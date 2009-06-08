package net.systemeD.halcyon.styleparser {

	import flash.utils.ByteArray;

	public class ShapeStyle {

		public var isStroked:Boolean=true;
		public var stroke_width:Number;
		public var stroke_colour:Number;
		public var stroke_opacity:Number;
		public var stroke_dashArray:Array=[];
		public var stroke_linecap:String="none";
		public var stroke_linejoin:String="round";
		public var sublayer:uint=0;
		
		public var isFilled:Boolean=false;
		public var fill_colour:Number;
		public var fill_opacity:Number;
		public var fill_pattern:String;
		
		public var isCased:Boolean=false;
		public var casing_width:Number;
		public var casing_colour:Number;
		public var casing_opacity:Number;
		public var casing_dashArray:Array=[];
		
	}

}
