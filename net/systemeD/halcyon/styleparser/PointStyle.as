package net.systemeD.halcyon.styleparser {

	public class PointStyle extends Style {

		public var icon_image:String;
		public var icon_width:uint;
		public var icon_height:uint;

		override public function get properties():Array {
			return [
				'icon_image','icon_width','icon_height'
			];
		}
	}

}
