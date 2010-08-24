package net.systemeD.halcyon {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.RuleSet;

	public class VectorLayer extends Object {

		public var map:Map;
		public var paint:MapPaint;						// sprites
		public var name:String;
		public var url:String;
		public var style:String='';

		public var ways:Object=new Object();			// geodata
		public var nodes:Object=new Object();			//  |
		public var relations:Object=new Object();		//  |
        private var negativeID:Number = -1;

		public function VectorLayer(n:String,m:Map,s:String) {
			name=n;
			map=m;
			style=s;
			paint=new MapPaint(m,0,0);
			redrawFromCSS(style);
		}

		public function redrawFromCSS(style:String):void {
			paint.ruleset=new RuleSet(map.MINSCALE,map.MAXSCALE,paint.redraw);
			paint.ruleset.loadFromCSS(style);
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

		public function getObjectsByBbox(left:Number, right:Number, top:Number, bottom:Number):Object {
			// ** FIXME: this is just copied-and-pasted from Connection.as, which really isn't very
			// good practice. Is there a more elegant way of doing it?
			var o:Object = { nodesInside: [], nodesOutside: [], waysInside: [], waysOutside: [] };
			for each (var way:Way in ways) {
				if (way.within(left,right,top,bottom)) { o.waysInside.push(way); }
				                                  else { o.waysOutside.push(way); }
			}
			for each (var node:Node in nodes) {
				if (node.within(left,right,top,bottom)) { o.nodesInside.push(node); }
				                                   else { o.nodesOutside.push(node); }
			}
			return o;
		}
		
		public function pullThrough(entity:Entity,connection:Connection):Way {
			var i:uint=0;
			if (entity is Way) {
				// copy way through to main layer
				// ** shouldn't do this if the nodes are already in the main layer
				//    (or maybe we should just match on lat/long to avoid ways in background having nodes in foreground)
				var oldWay:Way=Way(entity);
				var newWay:Way=connection.createWay(oldWay.getTagsCopy(), [], MainUndoStack.getGlobalStack().addAction);
				var nodemap:Object={};
				var oldNode:Node, newNode:Node;
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
			} else {
				// ** should be able to pull nodes through
				trace ("Pulling nodes through isn't supported yet");
			}
			return newWay;
		}
		
		public function blank():void {
			for each (var node:Node in nodes) { paint.deleteNodeUI(node); }
			for each (var way:Way in ways) { paint.deleteWayUI(way); }
			relations={}; nodes={}; ways={};
		}

	}
}
