package net.systemeD.halcyon.vectorlayers {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

	public class VectorLayer extends Object {

		public var map:Map;
		public var paint:MapPaint;						// sprites
		public var name:String;

		public var ways:Object=new Object();			// geodata
		public var nodes:Object=new Object();			//  |
		public var relations:Object=new Object();		//  |
        private var negativeID:Number = -1;

		public function VectorLayer(n:String,m:Map) {
			name=n;
			map=m;
			paint=new MapPaint(m,0,0);
		}
		
		public function createNode(tags:Object,lat:Number,lon:Number):Node {
			var node:Node = new Node(negativeID, 0, tags, true, lat, lon);
			nodes[negativeID]=node; negativeID--;
			return node;
		}
		public function createWay(tags:Object,nodes:Array):Way {
			var way:Way = new Way(negativeID, 0, tags, true, nodes.concat());
			ways[negativeID]=way; negativeID--;
			return way;
		}
		public function createRelation(tags:Object,members:Array):Relation {
            var relation:Relation = new Relation(negativeID, 0, tags, true, members.concat());
			relations[negativeID]=relation; negativeID--;
            return relation;
		}
		
		public function pullThrough(entity:Entity,connection:Connection):Way {
			var i:uint=0;
			if (entity is Way) {
				// copy way through to main layer
				// ** shouldn't do this if the nodes are already in the main layer
				var oldWay:Way=Way(entity);
				var newWay:Way=connection.createWay(oldWay.getTagsCopy(), [], MainUndoStack.getGlobalStack().addAction);
				for (i=0; i<oldWay.length; i++) {
					var oldNode:Node = oldWay.getNode(i);
					var newNode:Node = connection.createNode(
						oldNode.getTagsCopy(), oldNode.lat, oldNode.lon, 
						MainUndoStack.getGlobalStack().addAction);
					newWay.appendNode(newNode, MainUndoStack.getGlobalStack().addAction);
				}
				// delete this way
				while (oldWay.length) { 
					var id:int=oldWay.getNode(0).id;
					oldWay.removeNodeByIndex(0,MainUndoStack.getGlobalStack().addAction,false);
					delete nodes[id];
				}
				paint.wayuis[oldWay.id].redraw();
				ways[oldWay.id]=null;
				map.paint.createWayUI(newWay);
			}
			return newWay;
		}

	}
}
