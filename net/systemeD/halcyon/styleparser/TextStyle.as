package net.systemeD.halcyon.styleparser {

	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.filters.BitmapFilter;
	import flash.filters.GlowFilter;

	public class TextStyle {

		public var font_name:String;
		public var font_bold:Boolean;
		public var font_italic:Boolean;
		public var font_caps:Boolean;
		public var text_size:uint;
		public var text_colour:uint;
		public var text_offset:Number;	// Y offset - i.e. within or outside casing?
		public var text_width:Number;	// maximum width of label
		public var tag:String;
		public var pullout_colour:uint;
		public var pullout_radius:uint=0;
		public var isLine:Boolean;
		public var sublayer:uint=0;

		public function getTextFormat():TextFormat {
			return new TextFormat(font_name   ? font_name : "_sans",
								  text_size   ? text_size : 8,
								  text_colour ? text_colour: 0,
								  font_bold   ? font_bold : false,
								  font_italic ? font_italic: false);
		}
	
		public function getPulloutFilter():Array {
			var filter:BitmapFilter=new GlowFilter(pullout_colour ? pullout_colour : 0xFFFFFF,1,
												   pullout_radius ? pullout_radius: 2,
												   pullout_radius ? pullout_radius: 2,255);
			return [filter];
		}
		
		public function writeNameLabel(d:DisplayObjectContainer,a:String,x:Number,y:Number):TextField {
			var tf:TextField = new TextField();
			var n:TextFormat = getTextFormat();
			n.align = "center";
//			tf.embedFonts = true;
			tf.defaultTextFormat = n;
			tf.text = a;
			if (text_width) {
				tf.width=text_width;
				tf.wordWrap=true;
				tf.height=tf.textHeight+4;
			} else {
				tf.width = tf.textWidth+4;
				tf.height = tf.textHeight+4;
			}
			if (pullout_radius>0) { tf.filters=getPulloutFilter(); }
			d.x=x-tf.width/2;
			d.y=y+(text_offset ? text_offset : 0);
			d.addChild(tf);
			return tf;
		}

	}

}
