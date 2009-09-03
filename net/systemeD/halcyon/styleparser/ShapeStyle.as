package net.systemeD.halcyon.styleparser {

	public class ShapeStyle extends Style {

		public var width:Number;
		public var color:Number;
		public var opacity:Number;
		public var dashes:Array;
		public var linecap:String;
		public var linejoin:String;
		
		public var fill_color:Number;
		public var fill_opacity:Number;
		public var fill_pattern:String;
		
		public var casing_width:Number;
		public var casing_color:Number;
		public var casing_opacity:Number;
		public var casing_dashes:Array;
		
		override public function get properties():Array {
			return [
				'width','color','opacity','dashes','linecap','linejoin',
				'fill_color','fill_opacity','fill_pattern',
				'casing_width','casing_color','casing_opacity','casing_dashes'
			];
		}
	}

}
