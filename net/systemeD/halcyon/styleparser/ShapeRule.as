package net.systemeD.halcyon.styleparser {

	public class ShapeRule extends Rule {
		public var shapeStyle:ShapeStyle;
		public var textStyle:TextStyle;
		public var shieldStyle:ShieldStyle;

		public function ShapeRule(c:Array=null,ss:ShapeStyle=null,ts:TextStyle=null,hs:ShieldStyle=null) {
			conditions=c;
			shapeStyle=ss;
			textStyle=ts;
			shieldStyle=hs;
		}
	}
}
