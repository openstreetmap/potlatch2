package net.systemeD.halcyon.styleparser {

    /**
    * A StyleList object is the full list of all styles applied to
    * a drawn entity (i.e. node/way).
    *
    * Each array element applies to that sublayer (z-index). If there
    * is no element, nothing is drawn on that sublayer.
    */

	public class StyleList {

		public var shapeStyles:Object={};
		public var textStyles:Object={};
		public var pointStyles:Object={};
		public var shieldStyles:Object={};
		public var maxwidth:Number=0;
		public var sublayers:Array=[];
        /**
        * zoom level at which this StyleList is valid, or -1 for all
        */
		public var validAt:int=-1;

		public function hasStyles():Boolean {
			return ( hasShapeStyles() || hasTextStyles() || hasPointStyles() || hasShieldStyles() );
		}

		public function hasFills():Boolean {
			for each (var ss:ShapeStyle in shapeStyles) {
				if (!isNaN(ss.fill_color) || ss.fill_image) return true;
			}
			return false;
		}

		public function layerOverride():Number {
			for each (var ss:ShapeStyle in shapeStyles) {
				if (ss['layer']) return ss['layer'];
			}
			return NaN;
		}
		
		public function addSublayer(s:Number):void {
			if (sublayers.indexOf(s)==-1) { sublayers.push(s); }
		}

		public function toString():String {
			var str:String='';
			var k:String;
			for (k in shapeStyles) { str+="- SS "+k+"="+shapeStyles[k]+"\n"; }
			for (k in textStyles) { str+="- TS "+k+"="+textStyles[k]+"\n"; }
			for (k in pointStyles) { str+="- PS "+k+"="+pointStyles[k]+"\n"; }
			for (k in shieldStyles) { str+="- sS "+k+"="+shieldStyles[k]+"\n"; }
			return str;
		}

		public function isValidAt(zoom:uint):Boolean {
			return (validAt==-1 || validAt==zoom);
		}

		private function hasShapeStyles():Boolean  { for (var a:String in shapeStyles ) { return true; }; return false; }
		private function hasTextStyles():Boolean   { for (var a:String in textStyles  ) { return true; }; return false; }
		private function hasPointStyles():Boolean  { for (var a:String in pointStyles ) { return true; }; return false; }
		private function hasShieldStyles():Boolean { for (var a:String in shieldStyles) { return true; }; return false; }
	}
}
