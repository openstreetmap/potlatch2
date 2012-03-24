package net.systemeD.halcyon.styleparser {

	public class InstructionStyle extends Style {

		public var set_tags:Object={};
		public var breaker:Boolean=false;
		public var set_tags_order:Array=[];

		public function addSetTag(k:String,v:*):void {
			if (v is Eval) { evals[k]=v; }
			else if (v is TagValue) { tagvalues[k]=v; }
			
			edited=true;
			set_tags_order.push(k);
			set_tags[k]=v;
		}

		public function assignSetTags(tags:Object):void {
			for (var i:uint=0; i<set_tags_order.length; i++) {
				var k:String=set_tags_order[i];
				var v:*=set_tags[k];
				if (v is TagValue) { v=v.getValue(tags); }
				if (v=='') { delete tags[k]; }
				else { tags[k]=v; }
			}
		}
	}

}
