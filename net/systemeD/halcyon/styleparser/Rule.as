package net.systemeD.halcyon.styleparser {

    import net.systemeD.halcyon.connection.*;

	public class Rule {

		public var conditions:Array = [];
		public var isAnd:Boolean = true;
		public var minZoom:uint = 13;			// ** FIXME: shouldn't be hardcoded
		public var maxZoom:uint = 19;			//  |
		public var subject:String='';			// "", "way", "node" or "relation"
		
		public function Rule(s:String=''):void {
			subject=s;
		}
		
		public function test(obj:Entity,tags:Object,zoom:uint):Boolean {
			if (subject!='' && obj.getType()!=subject) { return false; }
			if (zoom<minZoom || zoom>maxZoom) { return false; }
			
			var v:Boolean=true; var i:uint=0;
			for each (var condition:Condition in conditions) {
				var r:Boolean=condition.test(tags);
				if (i==0) { v=r; }
				else if (isAnd) { v=v && r; }
				else { v = v || r;}
				i++;
			}
			return v;
		}
		
		public function toString():String {
			return subject+" z"+minZoom+"-"+maxZoom+": "+conditions;
		}
	}
}