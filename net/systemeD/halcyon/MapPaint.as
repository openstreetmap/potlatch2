package net.systemeD.halcyon {

	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import net.systemeD.halcyon.NodeUI;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.styleparser.RuleSet;
	import net.systemeD.halcyon.Globals;

	/** Manages the drawing of map entities, allocating their sprites etc. */
	public class MapPaint extends Sprite {
		
		/** Access Map object */
		public var map:Map;
		/** Entities on layers below minlayer will not be shown by this paint object. (Confirm?) */
		public var minlayer:int;
		/** Entities on layers above maxlayer will not be shown by this paint object. (Confirm?) */
		public var maxlayer:int;
		/** The MapCSS rules used for drawing entities. */
		public var ruleset:RuleSet;						
		/** WayUI objects attached to Way entities that are currently visible. */
		public var wayuis:Object=new Object();			// sprites for ways and (POI/tagged) nodes
		/** NodeUI objects attached to POI/tagged node entities that are currently visible. */
		// confirm this - it seems to me all nodes in ways get nodeuis? --Steve B
		public var nodeuis:Object=new Object();
		/** MarkerUI objects attached to Marker entities that are currently visible. */
        public var markeruis:Object=new Object();
        /** Is this a background layer or the core paint object? */
		public var isBackground:Boolean = true;
		/** Hash of index->position */
		public var sublayerIndex:Object={};

		private const VERYBIG:Number=Math.pow(2,16);
		private static const NO_LAYER:int=-99999;		// same as NodeUI

		// Set up layering

		public function MapPaint(map:Map,minlayer:int,maxlayer:int) {
			mouseEnabled=false;

			this.map=map;
			this.minlayer=minlayer;
			this.maxlayer=maxlayer;
			sublayerIndex[1]=0;
			var s:Sprite, l:int;

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
        * Update, and if necessary, create / remove UIs for the given objects.
        * The object is effectively lists of objects split into inside/outside pairs, e.g.
        * { waysInside: [], waysOutside: [] } where each is a array of entities either inside
        * or outside this current view window. UIs for the entities on "inside" lists will be created if necessary.
        * Flags control redrawing existing entities and removing UIs from entities no longer in view.
        *
        * @param o The object containing all the relevant entites.
        * @param redraw If true, all UIs for entities on "inside" lists will be redrawn
        * @param remove If true, all UIs for entites on "outside" lists will be removed. The purgable flag on UIs
                        can override this, for example for selected objects.
        * fixme? add smarter behaviour for way nodes - remove NodeUIs from way nodes off screen, create them for ones
        * that scroll onto screen (for highlights etc)
        */
		public function updateEntityUIs(o:Object, redraw:Boolean, remove:Boolean):void {
			var way:Way, poi:Node, marker:Marker;

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
			if (!nodeuis[node.id]) { return; }
			node.removeEventListener(Connection.NODE_DELETED, nodeDeleted);
			nodeuis[node.id].removeSprites();
			nodeuis[node.id].removeEventListeners();
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
            if (!markeruis[marker.id]) { return; }
            marker.removeEventListener(Connection.NODE_DELETED, markerDeleted);
            markeruis[marker.id].removeSprites();
            markeruis[marker.id].removeEventListeners();
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

		public function redraw():void {
			for each (var w:WayUI in wayuis) { w.recalculate(); w.invalidateStyleList(); w.redraw(); }
			/* sometimes (e.g. in Map.setStyle) Mappaint.redrawPOIs() is called immediately afterwards anyway. FIXME? */
			for each (var p:NodeUI in nodeuis) { p.invalidateStyleList(); p.redraw(); }
            for each (var m:MarkerUI in markeruis) { m.invalidateStyleList(); m.redraw(); }
		}

		/** Redraw nodes and markers */
		public function redrawPOIs():void {
			for each (var p:NodeUI in nodeuis) { p.invalidateStyleList(); p.redraw(); }
            for each (var m:MarkerUI in markeruis) { m.invalidateStyleList(); m.redraw(); }
		}
		
		public function findSource():VectorLayer {
			var v:VectorLayer;
			for each (v in map.vectorlayers) {
				if (v.paint==this) { return v; }
			}
			return null;
		}
	}
}
