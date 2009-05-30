package net.systemeD.halcyon.styleparser {

	public class PointRule extends Rule {
		public var pointStyle:PointStyle;
		public var textStyle:TextStyle;

		public function PointRule(c:Array=null,ps:PointStyle=null,ts:TextStyle=null) {
			conditions=c;
			pointStyle=ps;
			textStyle=ts;
		}
	}
}
