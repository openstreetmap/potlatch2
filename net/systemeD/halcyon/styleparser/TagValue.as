package net.systemeD.halcyon.styleparser {

	/*
		=== TagValue ===

		This is a custom declaration value that means 'use the value of this tag'.
		In other words,
			{ set ref=tag('dftnumber'); }
		parses to
			TagValue('dftnumber')
		and returns the value of the dftnumber tag.
		
		There isn't really any logic contained within this class, it's just here 
		so that we can store it as a custom property within Styles (like Eval).

	*/

	public class TagValue {
		private var key:String;

		public function TagValue(k:String) {
			key=k;
		}

		public function getValue(tags:Object):String {
			return tags[key];
		}
		
		public function toString():String {
			return "TagValue("+key+")";
		}
	}
}
