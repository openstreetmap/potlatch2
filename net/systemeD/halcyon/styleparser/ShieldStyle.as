package net.systemeD.halcyon.styleparser {

	public class ShieldStyle extends Style {

		public var shield_image:String;
		public var shield_width:uint;
		public var shield_height:uint;
		// ** also needs shield fonts etc.

		override public function get properties():Array {
			return [
				'shield_image','shield_width','shield_height'
			];
		}
	}
}
