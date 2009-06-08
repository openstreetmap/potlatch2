package net.systemeD.halcyon.styleparser {

	public class Rule {

		public var conditions:Array;
		public var breaker:Boolean = true;
		public var isAnd:Boolean = true;
		public var minScale:uint = 19;
		public var maxScale:uint = 13;
		public var hasTags:Boolean = false;
		public var setTags:Object = {};
		
		public function test(tags:Object):Boolean {
			var v:Boolean; var i:uint=0;
			for each (var condition:Condition in conditions) {
				var r:Boolean=condition.test(tags);
				if (i==0) { v=r; }
				else if (isAnd) { v=v && r; }
				else { v = v || r;}
				i++;
			}
			return v;
		}
	}
}