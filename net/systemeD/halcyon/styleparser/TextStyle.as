package net.systemeD.halcyon.styleparser {

	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.filters.BitmapFilter;
	import flash.filters.GlowFilter;

	public class TextStyle extends Style {

		public var font_family:String;
		public var font_bold:Boolean;
		public var font_italic:Boolean;
		public var font_underline:Boolean;
		public var font_caps:Boolean;
		public var font_size:uint;
		public var text_color:uint;
		public var text_offset:Number;		// Y offset - i.e. within or outside casing?
		public var max_width:Number;		// maximum width of label
		public var text:String;
		public var text_halo_color:uint;
		public var text_halo_radius:uint=0;
		public var text_center:Boolean;
		public var letter_spacing:uint;

		override public function get properties():Array {
			return [
				'font_family','font_bold','font_italic','font_caps','font_size',
				'text_color','text_offset','max_width',
				'text','text_halo_color','text_halo_radius','text_center',
				'letter_spacing'
			];
		}

		override public function get drawn():Boolean {
			return (text!=null);
		}

		public function getTextFormat():TextFormat {
			var tf:TextFormat=new TextFormat(font_family    ? font_family   : "DejaVu",
			                                 font_size      ? font_size     : 8,
			                                 text_color     ? text_color    : 0,
			                                 font_bold      ? font_bold     : false,
			                                 font_italic    ? font_italic   : false,
			                                 font_underline ? font_underline: false);
			tf.letterSpacing=(letter_spacing ? letter_spacing : 0);
			return tf;
		}
	
		public function getHaloFilter():Array {
			var filter:BitmapFilter=new GlowFilter(text_halo_color  ? text_halo_color  : 0xFFFFFF,1,
												   text_halo_radius ? text_halo_radius: 2,
												   text_halo_radius ? text_halo_radius: 2,255);
			return [filter];
		}
		
		public function writeNameLabel(d:DisplayObjectContainer,a:String,x:Number,y:Number):TextField {
			var tf:TextField = new TextField();
			var n:TextFormat = getTextFormat();
			n.align = "center";
			tf.embedFonts = true;
			tf.defaultTextFormat = n;
			tf.text = a;
			if (max_width) {
				tf.width=max_width;
				tf.wordWrap=true;
				tf.height=tf.textHeight+4;
			} else {
				tf.width = tf.textWidth+4;
				tf.height = tf.textHeight+4;
			}
			if (text_halo_radius>0) { tf.filters=getHaloFilter(); }
			d.x=x-tf.width/2;
			d.y=y-tf.height/2; tf.y=text_offset ? text_offset : 0;
			d.addChild(tf);

			return tf;
		}

	}

}
