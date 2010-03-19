package net.systemeD.halcyon.vectorlayers {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Relation;

	public class VectorLayer extends Object {

		public var map:Map;
		public var paint:MapPaint;						// sprites

		public var ways:Object=new Object();			// geodata
		public var nodes:Object=new Object();			//  |
		public var relations:Object=new Object();		//  |
        private var negativeID:Number = -1;

		public function VectorLayer(m:Map) {
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

	}
}
