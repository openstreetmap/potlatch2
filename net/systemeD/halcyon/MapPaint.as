package net.systemeD.halcyon {

	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import net.systemeD.halcyon.NodeUI;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.connection.actions.CreatePOIAction;
	import net.systemeD.halcyon.styleparser.RuleSet;

	/** Manages the drawing of map entities, allocating their sprites etc. */
	public class MapPaint extends Sprite {
		
		/** Parent Map - required for finding out bounds and scale */
		public var map:Map;

		/** Source data for this MapPaint layer */
		public var connection:Connection;

		/** Lowest OSM layer that can be displayed */
		public var minlayer:int;
		/** Highest OSM layer that can be displayed */
		public var maxlayer:int;
		/** The MapCSS rules used for drawing entities. */
		public var ruleset:RuleSet;						
		/** WayUI objects attached to Way entities that are currently visible. */
		private var wayuis:Object=new Object();
		/** NodeUI objects attached to POI/tagged node entities that are currently visible. */
		private var nodeuis:Object=new Object();
		/** MarkerUI objects attached to Marker entities that are currently visible. */
        private var markeruis:Object=new Object();
        /** Is this a background layer or the core paint object? */
		public var isBackground:Boolean = true;
		/** Hash of index->position */
		public var sublayerIndex:Object={};

        /** The url of the style in use */
        public var style:String = '';

		private const VERYBIG:Number=Math.pow(2,16);
		private static const NO_LAYER:int=-99999;		// same as NodeUI

		// Set up layering

		/** Creates paint sprites and hit sprites for all layers in range. This object ends up with a series of child sprites
		 * as follows: p0,p1,p2..px, h0,h1,h2..hx where p are "paint sprites" and "h" are "hit sprites". There is one of each type for each layer.
		 * <p>Each paint sprite has 4 child sprites (fill, casing, stroke, names). Each hit sprite has 2 child sprites (way hit tests, node hit tests).</p>  
		 * <p>Thus if layers range from -5 to +5, there will be 11 top level paint sprites followed by 11 top level hit sprites.</p>
		 * 
		 * @param map The Map this is attached to. (Required for finding out bounds and scale.)
		 * @param connection The Connection containing the data for this layer.
		 * @param minlayer The lowest OSM layer to display.
		 * @param maxlayer The highest OSM layer to display.
		 * */ 
		public function MapPaint(map:Map, connection:Connection, styleurl:String, minlayer:int, maxlayer:int) {
			mouseEnabled=false;

			this.map=map;
			this.connection=connection;
			this.minlayer=minlayer;
			this.maxlayer=maxlayer;
			sublayerIndex[1]=0;
			var s:Sprite, l:int;

			// Set up stylesheet
			setStyle(styleurl);

			// Listen for changes on this Connection
            connection.addEventListener(Connection.NEW_WAY, newWayCreatedListener);
            connection.addEventListener(Connection.NEW_POI, newPOICreatedListener);
            connection.addEventListener(Connection.WAY_RENUMBERED, wayRenumberedListener);
            connection.addEventListener(Connection.NODE_RENUMBERED, nodeRenumberedListener);
            connection.addEventListener(Connection.NEW_MARKER, newMarkerCreatedListener);

			// Add paint sprites
			for (l=minlayer; l<=maxlayer; l++) {			// each layer (10 is +5, 0 is -5)
				s = getPaintSprite();						//	|
				s.addChild(getPaintSprite());				//	| 0 fill
				s.addChild(getPaintSprite());				//	| 1 casing
				var t:Sprite = getPaintSprite();			//	| 2 stroke
				t.addChild(getPaintSprite());				//	|  | sublayer
				s.addChild(t);								//	|  |
				s.addChild(getPaintSprite());				//	| 3 names
				addChild(s);								//	|
			}
			
			// Add hit sprites
			for (l=minlayer; l<=maxlayer; l++) {			// each layer (21 is +5, 11 is -5)
				s = getHitSprite();							//	|
				s.addChild(getHitSprite());					//	| 0 way hit tests
				s.addChild(getHitSprite());					//	| 1 node hit tests
				addChild(s);
			}
		}
		
		/** Returns the paint surface for the given layer. */
		public function getPaintSpriteAt(l:int):Sprite {
			return getChildAt(l-minlayer) as Sprite;
		}

		/** Returns the hit sprite for the given layer. */
		public function getHitSpriteAt(l:int):Sprite {
			return getChildAt((l-minlayer) + (maxlayer-minlayer+1)) as Sprite;
		}
		
		/** Is ruleset loaded? */
		public function get ready():Boolean {
			if (!ruleset) { return false; }
			if (!ruleset.loaded) { return false; }
			return true;
		}

		public function sublayer(layer:int,sublayer:Number):Sprite {
			var l:DisplayObject;
			var o:DisplayObject;
			var index:String, ix:Number;
			if (!sublayerIndex.hasOwnProperty(sublayer)) {
				// work out which position to add at
				var lowestAbove:Number=VERYBIG;
				var lowestAbovePos:int=-1;
				var indexLength:uint=0;
				for (index in sublayerIndex) {
					ix=Number(index);
					if (ix>sublayer && ix<lowestAbove) {
						lowestAbove=ix;
						lowestAbovePos=sublayerIndex[index];
					}
					indexLength++;
				}
				if (lowestAbovePos==-1) { lowestAbovePos=indexLength; }
			
				// add sprites
				for (var i:int=minlayer; i<=maxlayer; i++) {
					l=getChildAt(i-minlayer);
					o=(l as Sprite).getChildAt(2);
					(o as Sprite).addChildAt(getPaintSprite(),lowestAbovePos);
				}
			
				// update index
				// (we do it in this rather indirect way because if you alter sublayerIndex directly
				//	within the loop, it confuses the iterator)
				var toUpdate:Array=[];
				for (index in sublayerIndex) {
					ix=Number(index);
					if (ix>sublayer) { toUpdate.push(index); }
				}
				for each (index in toUpdate) { sublayerIndex[index]++; }
				sublayerIndex[sublayer]=lowestAbovePos;
			}

			l=getChildAt(layer-minlayer);
			o=(l as Sprite).getChildAt(2);
			return ((o as Sprite).getChildAt(sublayerIndex[sublayer]) as Sprite);
		}

        /**
        * Update, and if necessary, create / remove UIs for the current viewport.
        * Flags control redrawing existing entities and removing UIs from entities no longer in view.
        *
        * @param redraw If true, all UIs for entities on "inside" lists will be redrawn
        * @param remove If true, all UIs for entites on "outside" lists will be removed. The purgable flag on UIs
                        can override this, for example for selected objects.
        * fixme? add smarter behaviour for way nodes - remove NodeUIs from way nodes off screen, create them for ones
        * that scroll onto screen (for highlights etc)
        */
		public function updateEntityUIs(redraw:Boolean, remove:Boolean):void {
			var way:Way, poi:Node, marker:Marker;
			var o:Object = connection.getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b);

			for each (way in o.waysInside) {
				if (!wayuis[way.id]) { createWayUI(way); }
				else if (redraw) { wayuis[way.id].recalculate(); wayuis[way.id].redraw(); }
				else wayuis[way.id].updateHighlights();//dubious
			}

			if (remove) {
				for each (way in o.waysOutside) {
					if (wayuis[way.id] && !wayuis[way.id].purgable) {
						if (redraw) { wayuis[way.id].recalculate(); wayuis[way.id].redraw(); }
					} else {
						deleteWayUI(way);
					}
				}
			}

			for each (poi in o.poisInside) {
				if (!nodeuis[poi.id]) { createNodeUI(poi); }
				else if (redraw) { nodeuis[poi.id].redraw(); }
			}

			if (remove) {
				for each (poi in o.poisOutside) { 
					if (nodeuis[poi.id] && !nodeuis[poi.id].purgable) {
						if (redraw) { nodeuis[poi.id].redraw(); }
					} else {
						deleteNodeUI(poi);
					}
				}
			}

            for each (marker in o.markersInside) {
                if (!markeruis[marker.id]) { createMarkerUI(marker); }
                else if (redraw) { markeruis[marker.id].redraw(); }
            }

            if (remove) {
                for each (marker in o.markersOutside) {
                    if (markeruis[marker.id] && !markeruis[marker.id].purgable) {
                        if (redraw) { markeruis[marker.id].redraw(); }
                    } else {
                        deleteMarkerUI(marker);
                    }
                }
            }
		}

		/** Make a UI object representing a way. */
		public function createWayUI(way:Way):WayUI {
			if (!wayuis[way.id]) {
				wayuis[way.id]=new WayUI(way,this);
				way.addEventListener(Connection.WAY_DELETED, wayDeleted);
			} else {
				wayuis[way.id].redraw();
			}
			return wayuis[way.id];
		}

		/** Respond to event by removing the WayUI. */
		public function wayDeleted(event:EntityEvent):void {
			deleteWayUI(event.entity as Way);
		}

		/** Remove a way's UI object. */
		public function deleteWayUI(way:Way):void {
			way.removeEventListener(Connection.WAY_DELETED, wayDeleted);
			if (wayuis[way.id]) {
				wayuis[way.id].redrawMultis();
				wayuis[way.id].removeSprites();
				wayuis[way.id].removeEventListeners();
				wayuis[way.id].removeListenSprite();
				delete wayuis[way.id];
			}
			for (var i:uint=0; i<way.length; i++) {
				var node:Node=way.getNode(i);
				if (nodeuis[node.id]) { deleteNodeUI(node); }
			}
		}

		/** Make a UI object representing a node. */
		public function createNodeUI(node:Node,rotation:Number=0,layer:int=NO_LAYER,stateClasses:Object=null):NodeUI {
			if (!nodeuis[node.id]) {
				nodeuis[node.id]=new NodeUI(node,this,rotation,layer,stateClasses);
				node.addEventListener(Connection.NODE_DELETED, nodeDeleted);
			} else {
				for (var state:String in stateClasses) {
					nodeuis[node.id].setStateClass(state,stateClasses[state]);
				}
				nodeuis[node.id].redraw();
			}
			return nodeuis[node.id];
		}

		/** Respond to event by deleting NodeUI. */
		public function nodeDeleted(event:EntityEvent):void {
			deleteNodeUI(event.entity as Node);
		}

		/** Remove a node's UI object. */
		public function deleteNodeUI(node:Node):void {
			node.removeEventListener(Connection.NODE_DELETED, nodeDeleted);
			if (!nodeuis[node.id]) { return; }
			nodeuis[node.id].removeSprites();
			nodeuis[node.id].removeEventListeners();
			nodeuis[node.id].removeListenSprite();
			delete nodeuis[node.id];
		}

        /** Make a UI object representing a marker. */
        public function createMarkerUI(marker:Marker,rotation:Number=0,layer:int=NO_LAYER,stateClasses:Object=null):MarkerUI {
            if (!markeruis[marker.id]) {
                markeruis[marker.id]=new MarkerUI(marker,this,rotation,layer,stateClasses);
                marker.addEventListener(Connection.NODE_DELETED, markerDeleted);
            } else {
                for (var state:String in stateClasses) {
                    markeruis[marker.id].setStateClass(state,stateClasses[state]);
                }
                markeruis[marker.id].redraw();
            }
            return markeruis[marker.id];
        }

        /** Respond to event by deleting MarkerUI. */
        public function markerDeleted(event:EntityEvent):void {
            deleteMarkerUI(event.entity as Marker);
        }

        /** Remove a marker's UI object. */
        public function deleteMarkerUI(marker:Marker):void {
            marker.removeEventListener(Connection.NODE_DELETED, markerDeleted);
            if (!markeruis[marker.id]) { return; }
            markeruis[marker.id].removeSprites();
            markeruis[marker.id].removeEventListeners();
            markeruis[marker.id].removeListenSprite();
            delete markeruis[marker.id];
        }
		
		public function renumberWayUI(way:Way,oldID:Number):void {
			if (!wayuis[oldID]) { return; }
			wayuis[way.id]=wayuis[oldID];
			delete wayuis[oldID];
		}

		public function renumberNodeUI(node:Node,oldID:Number):void {
			if (!nodeuis[oldID]) { return; }
			nodeuis[node.id]=nodeuis[oldID];
			delete nodeuis[oldID];
		}

		/** Make a new sprite for painting on */
		private function getPaintSprite():Sprite {
			var s:Sprite = new Sprite();
			s.mouseEnabled = false;
			s.mouseChildren = false;
			return s;
		}

		private function getHitSprite():Sprite {
			var s:Sprite = new Sprite();
			return s;
		}

		/** Redraw all entities */
		public function redraw():void {
			for each (var w:WayUI in wayuis) { w.recalculate(); w.invalidateStyleList(); w.redraw(); }
			/* sometimes (e.g. in Map.setStyle) Mappaint.redrawPOIs() is called immediately afterwards anyway. FIXME? */
			for each (var p:NodeUI in nodeuis) { p.invalidateStyleList(); p.redraw(); }
            for each (var m:MarkerUI in markeruis) { m.invalidateStyleList(); m.redraw(); }
		}

		/** Redraw nodes and markers only */
		public function redrawPOIs():void {
			for each (var p:NodeUI in nodeuis) { p.invalidateStyleList(); p.redraw(); }
            for each (var m:MarkerUI in markeruis) { m.invalidateStyleList(); m.redraw(); }
		}
		
		/** Redraw a single entity if it exists */
		public function redrawEntity(e:Entity):Boolean {
			if      (e is Way    && wayuis[e.id]) wayuis[e.id].redraw();
			else if (e is Node   && nodeuis[e.id]) nodeuis[e.id].redraw();
			else if (e is Marker && markeruis[e.id]) markeruis[e.id].redraw();
			else return false;
			return true;
		}
		
		/** Switch to new MapCSS. */
		public function setStyle(url:String):void {
            style = url;
			ruleset=new RuleSet(map.MINSCALE,map.MAXSCALE,redraw,redrawPOIs);
			ruleset.loadFromCSS(url);
        }

		// ==================== Start of code moved from Map.as

		// Listeners for Connection events

        private function newWayCreatedListener(event:EntityEvent):void {
            var way:Way = event.entity as Way;
			if (!way.loaded || !way.within(map.edge_l, map.edge_r, map.edge_t, map.edge_b)) { return; }
			createWayUI(way);
        }

        private function newPOICreatedListener(event:EntityEvent):void {
            var node:Node = event.entity as Node;
			if (!node.within(map.edge_l, map.edge_r, map.edge_t, map.edge_b)) { return; }
			createNodeUI(node);
        }

        private function newMarkerCreatedListener(event:EntityEvent):void {
            var marker:Marker = event.entity as Marker;
            if (!marker.within(map.edge_l, map.edge_r, map.edge_t, map.edge_b)) { return; }
            createMarkerUI(marker);
        }

		private function wayRenumberedListener(event:EntityRenumberedEvent):void {
            var way:Way = event.entity as Way;
			renumberWayUI(way,event.oldID);
		}

		private function nodeRenumberedListener(event:EntityRenumberedEvent):void {
            var node:Node = event.entity as Node;
			renumberNodeUI(node,event.oldID);
		}

        /** Visually mark an entity as highlighted. */
        public function setHighlight(entity:Entity, settings:Object):void {
			if      ( entity is Way  && wayuis[entity.id] ) { wayuis[entity.id].setHighlight(settings);  }
			else if ( entity is Node && nodeuis[entity.id]) { nodeuis[entity.id].setHighlight(settings); }
        }

        public function setHighlightOnNodes(way:Way, settings:Object):void {
			if (wayuis[way.id]) wayuis[way.id].setHighlightOnNodes(settings);
        }

		public function protectWay(way:Way):void {
			if (wayuis[way.id]) wayuis[way.id].protectSprites();
		}

		public function unprotectWay(way:Way):void {
			if (wayuis[way.id]) wayuis[way.id].unprotectSprites();
		}
		
		public function limitWayDrawing(way:Way,except:Number=NaN,only:Number=NaN):void {
			if (!wayuis[way.id]) return;
			wayuis[way.id].drawExcept=except;
			wayuis[way.id].drawOnly  =only;
			wayuis[way.id].redraw();
		}

		/** Protect Entities and EntityUIs against purging. This prevents the currently selected items
		   from being purged even though they're off-screen. */

		public function setPurgable(entities:Array, purgable:Boolean):void {
			for each (var entity:Entity in entities) {
				entity.locked=!purgable;
				if ( entity is Way  ) {
					var way:Way=entity as Way;
					if (wayuis[way.id]) { wayuis[way.id].purgable=purgable; }
					for (var i:uint=0; i<way.length; i++) {
						var node:Node=way.getNode(i)
						node.locked=!purgable;
						if (nodeuis[node.id]) { nodeuis[node.id].purgable=purgable; }
					}
				} else if ( entity is Node && nodeuis[entity.id]) { 
					nodeuis[entity.id].purgable=purgable;
				}
			}
		}

		// ==================== End of code moved from Map.as

		/** Find all ways whose WayUI passes a given screen co-ordinate. */
		
		public function findWaysAtPoint(x:Number, y:Number, ignore:Way=null):Array {
			var ways:Array=[]; var w:Way;
			for each (var wayui:WayUI in wayuis) {
				w=wayui.hitTest(x,y);
				if (w && w!=ignore) { ways.push(w); }
			}
			return ways;
		}

        /**
        * Transfers an entity from this layer into another layer
        * @param entity The entity from this layer that you want to transfer.
        * @param target The layer to transfer to
        *
        * @return either the newly created entity, or null
        */
        public function pullThrough(entity:Entity, target:MapPaint):Entity {
            // TODO - check the entity actually resides in this layer.

            var action:CompositeUndoableAction = new CompositeUndoableAction("pull through");
            if (entity is Way) {
                // copy way through to main layer
                // ** shouldn't do this if the nodes are already in the main layer
                //    (or maybe we should just match on lat/long to avoid ways in background having nodes in foreground)
                var oldWay:Way=Way(entity);
                var nodemap:Object={};
                var nodes:Array=[];
                for (var i:uint=0; i<oldWay.length; i++) {
                    oldNode = oldWay.getNode(i);
                    var newNode:Node = nodemap[oldNode.id] ? nodemap[oldNode.id] : target.connection.createNode(
                        oldNode.getTagsCopy(), oldNode.lat, oldNode.lon,
                        action.push);
                    nodes.push(newNode);
                    nodemap[oldNode.id]=newNode;
                }
                oldWay.remove(action.push);
                var newWay:Way=target.connection.createWay(oldWay.getTagsCopy(), nodes, action.push);
                MainUndoStack.getGlobalStack().addAction(action);
                return newWay;

            } else if (entity is Node && !entity.hasParentWays) {

                var oldNode:Node=Node(entity);

                var newPoiAction:CreatePOIAction = new CreatePOIAction(
                    target.connection, oldNode.getTagsCopy(), oldNode.lat, oldNode.lon);
                action.push(newPoiAction);

                oldNode.remove(action.push);

                MainUndoStack.getGlobalStack().addAction(action);
                return newPoiAction.getNode();
            }
            return null;
        }

	}
}
