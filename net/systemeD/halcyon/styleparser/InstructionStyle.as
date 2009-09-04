package net.systemeD.halcyon.styleparser {

	public class InstructionStyle extends Style {

		public var set_tags:Object;
		public var breaker:Boolean=false;

		public function addSetTag(k:String,v:*):void {
			edited=true;
			if (!set_tags) { set_tags=new Object(); }
			set_tags[k]=v;
		}

	}

}
