package net.systemeD.halcyon {
	public class Node extends Object {
		public var lon:Number;			// raw longitude
		public var latp:Number;			// projected latitude
		public var tags:Object;
		public var tagged:Boolean;
		public var id:int;
		public var version:uint;
		public var clean:Boolean;

		public function Node(id:int,lon:Number,latp:Number,tags:Object,version:uint) {
			this.id=id;
			this.lon=lon;
			this.latp=latp;
			this.tags=tags;
//			this.tagged=hasTags();
			this.version=version;
			this.clean=false;		// set to true if just loaded from server
		}
	}
}
