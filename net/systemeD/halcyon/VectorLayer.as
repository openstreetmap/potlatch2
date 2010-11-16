package net.systemeD.halcyon {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.RuleSet;

    /** The VectorLayer class is used for the concept of Vector Background Layers.
    * It is similar in concept to the various Connection layers used for the core
    * OpenStreetMap data, and as such it stores its own list of nodes, ways and relations.
    * The most interesting function is pullThrough which allows moving entities out
    * of a VectorLayer and into the main map layer
    */
	public class VectorLayer extends Object {

		public var map:Map;
		public var paint:MapPaint;						// sprites
		public var name:String;
		public var url:String;
		public var style:String='';

		public var ways:Object=new Object();			// geodata
		public var nodes:Object=new Object();			//  |
		public var relations:Object=new Object();		//  |
		private var pois:Array=[];						//  |

        private var markers:Object=new Object();        // markers
        private var negativeID:Number = -1;

        /** Create a new VectorLayer
        * @param n The name of the VectorLayer (eg 'GPS tracks')
        * @param m The map. You probably have a global reference to this
        * @param s The style you wish to use (eg 'gpx.css')
        */
		public function VectorLayer(n:String,m:Map,s:String) {
			name=n;
			map=m;
			style=s;
			paint=new MapPaint(m,0,0);
			redrawFromCSS(style);
		}

		public function redrawFromCSS(style:String):void {
			paint.ruleset=new RuleSet(map.MINSCALE,map.MAXSCALE,paint.redraw,paint.redrawPOIs);
			paint.ruleset.loadFromCSS(style);
		}

        /** Create a new node on the vector layer. Note that the node won't show up until on the map
        * until the the relevant nodeUI is created, so you will need to instruct the paint to create one
        *
        * e.g. layer.paint.updateEntityUIs(layer.getObjectsByBbox(...)...);
        */
		public function createNode(tags:Object,lat:Number,lon:Number):Node {
			var node:Node = new Node(negativeID, 0, tags, true, lat, lon);
			nodes[negativeID]=node; negativeID--;
			return node;
		}

        /**
        * @param tags The tags for the new Way
        * @param nodes An array of Node objects
        */
		public function createWay(tags:Object,nodes:Array):Way {
			var way:Way = new Way(negativeID, 0, tags, true, nodes.concat());
			ways[negativeID]=way; negativeID--;
			return way;
		}

        /**
        * @param tags The tags for the new relation
        * @param members An array of RelationMember objects
        */
		public function createRelation(tags:Object,members:Array):Relation {
            var relation:Relation = new Relation(negativeID, 0, tags, true, members.concat());
			relations[negativeID]=relation; negativeID--;
            return relation;
		}

        public function createMarker(tags:Object,lat:Number,lon:Number:Marker {
            var marker:Marker = new Marker(negativeID, 0, tags, true, lat, lon);
            markers[negativeID]=node; negativeID--;
            return marker;
        }

        public function registerPOI(node:Node):void {
            if (pois.indexOf(node)<0) { pois.push(node); }
        }
        public function unregisterPOI(node:Node):void {
			var index:uint = pois.indexOf(node);
			if ( index >= 0 ) { pois.splice(index,1); }
        }

		public function getObjectsByBbox(left:Number, right:Number, top:Number, bottom:Number):Object {
			// ** FIXME: this is just copied-and-pasted from Connection.as, which really isn't very
			// good practice. Is there a more elegant way of doing it?
			var o:Object = { poisInside: [], poisOutside: [], waysInside: [], waysOutside: [] };
			for each (var way:Way in ways) {
				if (way.within(left,right,top,bottom)) { o.waysInside.push(way); }
				                                  else { o.waysOutside.push(way); }
			}
			for each (var poi:Node in pois) {
				if (poi.within(left,right,top,bottom)) { o.poisInside.push(poi); }
				                                  else { o.poisOutside.push(poi); }
			}
			return o;
		}

        /**
        * Transfers an entity from the VectorLayer into the main layer
        * @param entity The entity from the VectorLayer that you want to transfer.
        * @param connection The Connection instance to transfer to (eg Connection.getConnection() )
        *
        * @return either the newly created entity, or null
        */
		public function pullThrough(entity:Entity,connection:Connection):Entity {
			var i:uint=0;
			var oldNode:Node, newNode:Node;
			if (entity is Way) {
				// copy way through to main layer
				// ** shouldn't do this if the nodes are already in the main layer
				//    (or maybe we should just match on lat/long to avoid ways in background having nodes in foreground)
				var oldWay:Way=Way(entity);
				var newWay:Way=connection.createWay(oldWay.getTagsCopy(), [], MainUndoStack.getGlobalStack().addAction);
				var nodemap:Object={};
				for (i=0; i<oldWay.length; i++) {
					oldNode = oldWay.getNode(i);
					newNode = nodemap[oldNode.id] ? nodemap[oldNode.id] : connection.createNode(
						oldNode.getTagsCopy(), oldNode.lat, oldNode.lon, 
						MainUndoStack.getGlobalStack().addAction);
					newWay.appendNode(newNode, MainUndoStack.getGlobalStack().addAction);
					nodemap[oldNode.id]=newNode;
				}
				// delete this way
				while (oldWay.length) { 
					var id:Number=oldWay.getNode(0).id;
					oldWay.removeNodeByIndex(0,MainUndoStack.getGlobalStack().addAction,false);
					delete nodes[id];
				}
				paint.wayuis[oldWay.id].redraw();
				delete ways[oldWay.id];
				map.paint.createWayUI(newWay);
				return newWay;

			} else if (entity is Node && !entity.hasParentWays) {
				// copy node through to main layer
				// ** should be properly undoable
				oldNode=Node(entity);
				unregisterPOI(oldNode);
				var newPoiAction:CreatePOIAction = new CreatePOIAction(
					oldNode.getTagsCopy(), oldNode.lat, oldNode.lon);
				MainUndoStack.getGlobalStack().addAction(newPoiAction);
				paint.deleteNodeUI(oldNode);
				delete nodes[oldNode.id];
				return newPoiAction.getNode();
			}
			return null;
		}

        /**
        * Remove all the nodes, ways, and relations from the VectorLayer.
        * Also removes the associated NodeUIs, WayUIs and POIs
        */
		public function blank():void {
			for each (var node:Node in nodes) { paint.deleteNodeUI(node); }
			for each (var way:Way in ways) { paint.deleteWayUI(way); }
			relations={}; nodes={}; ways={}; pois=[];
		}

	}
}
