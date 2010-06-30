package net.systemeD.halcyon.styleparser {

	public class StyleList {

		/*
			A StyleList object is the full list of all styles applied to 
			a drawn entity (i.e. node/way).
			
			Each array element applies to that sublayer (z-index). If there
			is no element, nothing is drawn on that sublayer.

		*/

		public var shapeStyles:Object={};
		public var textStyles:Object={};
		public var pointStyles:Object={};
		public var shieldStyles:Object={};
		public var maxwidth:Number=0;
		public var sublayers:Array=[];

		public function hasStyles():Boolean {
			return ( hasShapeStyles() || hasTextStyles() || hasPointStyles() || hasShieldStyles() );
		}
		
		public function addSublayer(s:Number):void {
			if (sublayers.indexOf(s)==-1) { sublayers.push(s); }
		}

		private function hasShapeStyles():Boolean  { for (var a:String in shapeStyles ) { return true; }; return false; }
		private function hasTextStyles():Boolean   { for (var a:String in textStyles  ) { return true; }; return false; }
		private function hasPointStyles():Boolean  { for (var a:String in pointStyles ) { return true; }; return false; }
		private function hasShieldStyles():Boolean { for (var a:String in shieldStyles) { return true; }; return false; }
	}
}
