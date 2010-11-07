package net.systemeD.halcyon.styleparser {

	import flash.display.Graphics;
	
	public class ShapeStyle extends Style {

		public var width:Number=0;
		public var color:Number;
		public var opacity:Number;
		public var dashes:Array=[];
		public var linecap:String;
		public var linejoin:String;
		public var line_style:String;
		
		public var fill_color:Number;
		public var fill_opacity:Number;
		public var fill_image:String;
		
		public var casing_width:Number;
		public var casing_color:Number;
		public var casing_opacity:Number;
		public var casing_dashes:Array=[];
		
		public var layer:Number;				// optional layer override (usually set by OSM tag)
		
		override public function get properties():Array {
			return [
				'width','color','opacity','dashes','linecap','linejoin','line_style',
				'fill_color','fill_opacity','fill_image',
				'casing_width','casing_color','casing_opacity','casing_dashes','layer'
			];
		}
		
		override public function get drawn():Boolean {
			return (fill_image || !isNaN(fill_color) || width || casing_width);
		}

		public function applyStrokeStyle(g:Graphics):void {
			g.lineStyle(width,
						color ? color : 0,
						opacity ? opacity : 1,
						false, "normal",
						linecap  ? linecap : "none",
						linejoin ? linejoin : "round");
		}
		
		public function applyCasingStyle(g:Graphics):void {
			g.lineStyle(casing_width,
						casing_color   ? casing_color : 0,
						casing_opacity ? casing_opacity : 1,
						false, "normal",
						linecap  ? linecap : "none",
						linejoin ? linejoin : "round");
		}
		
		public function applyFill(g:Graphics):void {
			g.beginFill(fill_color,
						fill_opacity ? fill_opacity : 1);
		}
		
	}

}
