package net.systemeD.halcyon.styleparser {

	public class ShapeStyle {

		public var isStroked:Boolean=true;
		public var stroke_colour:uint=0x777777;
		public var stroke_width:Number=1;
		public var stroke_opacity:uint=100;
		public var stroke_dashArray:Array=[];
		public var stroke_linecap:String="none";
		public var stroke_linejoin:String="round";
		public var sublayer:uint=0;
		
		public var isFilled:Boolean=false;
		public var fill_colour:uint=0xFFFFFF;
		public var fill_opacity:Number=100;
		public var fill_pattern:String;
		
		public var isCased:Boolean=false;
		public var casing_width:Number=1;
		public var casing_colour:uint=0;
		public var casing_opacity:Number=100;
		public var casing_dashArray:Array=[];
		
	}

}
