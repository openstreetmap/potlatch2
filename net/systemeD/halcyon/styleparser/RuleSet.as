package net.systemeD.halcyon.styleparser {

	import flash.events.*;
	import flash.net.*;
	import net.systemeD.halcyon.ExtendedLoader;
	import net.systemeD.halcyon.ExtendedURLLoader;
	import net.systemeD.halcyon.DebugURLRequest;
    import net.systemeD.halcyon.connection.Entity;

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
//	import bustin.dev.Inspector;
	
	public class RuleSet {

		public var loaded:Boolean=false;			// has it loaded yet?
		public var images:Object=new Object();		// loaded images
		public var imageWidths:Object=new Object();	// width of each bitmap image
		private var redrawCallback:Function=null;	// function to call when CSS loaded
		private var iconCallback:Function=null;		// function to call when all icons loaded
		private var iconsToLoad:uint=0;				// number of icons left to load (fire iconCallback when ==0)
		private var evalsToLoad:uint=0;				// number of evals left to load (fire redrawCallback when ==0)

		private var minscale:uint;
		private var maxscale:uint;
		public var choosers:Array;
		public var evals:Array;

		private static const WHITESPACE:RegExp	=/^ \s+ /sx;
		private static const COMMENT:RegExp		=/^ \/\* .+? \*\/ \s* /sx;	/* */
		private static const CLASS:RegExp		=/^ ([\.:]\w+) \s* /sx;
		private static const NOT_CLASS:RegExp	=/^ !([\.:]\w+) \s* /sx;
		private static const ZOOM:RegExp		=/^ \| \s* z([\d\-]+) \s* /isx;
		private static const GROUP:RegExp		=/^ , \s* /isx;
		private static const CONDITION:RegExp	=/^ \[(.+?)\] \s* /sx;
		private static const OBJECT:RegExp		=/^ (\w+) \s* /sx;
		private static const DECLARATION:RegExp	=/^ \{(.+?)\} \s* /sx;
		private static const UNKNOWN:RegExp		=/^ (\S+) \s* /sx;

		private static const ZOOM_MINMAX:RegExp	=/^ (\d+)\-(\d+) $/sx;
		private static const ZOOM_MIN:RegExp	=/^ (\d+)\-      $/sx;
		private static const ZOOM_MAX:RegExp	=/^      \-(\d+) $/sx;
		private static const ZOOM_SINGLE:RegExp	=/^        (\d+) $/sx;

		private static const CONDITION_TRUE:RegExp      =/^ \s* ([:\w]+) \s* = \s* yes \s*  $/isx;
		private static const CONDITION_FALSE:RegExp     =/^ \s* ([:\w]+) \s* = \s* no  \s*  $/isx;
		private static const CONDITION_SET:RegExp       =/^ \s* ([:\w]+) \s* $/sx;
		private static const CONDITION_UNSET:RegExp     =/^ \s* !([:\w]+) \s* $/sx;
		private static const CONDITION_EQ:RegExp        =/^ \s* ([:\w]+) \s* =  \s* (.+) \s* $/sx;
		private static const CONDITION_NE:RegExp        =/^ \s* ([:\w]+) \s* != \s* (.+) \s* $/sx;
		private static const CONDITION_GT:RegExp        =/^ \s* ([:\w]+) \s* >  \s* (.+) \s* $/sx;
		private static const CONDITION_GE:RegExp        =/^ \s* ([:\w]+) \s* >= \s* (.+) \s* $/sx;
		private static const CONDITION_LT:RegExp        =/^ \s* ([:\w]+) \s* <  \s* (.+) \s* $/sx;
		private static const CONDITION_LE:RegExp        =/^ \s* ([:\w]+) \s* <= \s* (.+) \s* $/sx;
		private static const CONDITION_REGEX:RegExp     =/^ \s* ([:\w]+) \s* =~\/ \s* (.+) \/ \s* $/sx;

		private static const ASSIGNMENT_EVAL:RegExp	=/^ \s* (\S+) \s* \:      \s* eval \s* \( \s* ' (.+?) ' \s* \) \s* $/isx;
		private static const ASSIGNMENT:RegExp		=/^ \s* (\S+) \s* \:      \s*          (.+?) \s*                   $/sx;
		private static const SET_TAG_EVAL:RegExp	=/^ \s* set \s+(\S+)\s* = \s* eval \s* \( \s* ' (.+?) ' \s* \) \s* $/isx;
		private static const SET_TAG:RegExp			=/^ \s* set \s+(\S+)\s* = \s*          (.+?) \s*                   $/isx;
		private static const SET_TAG_TRUE:RegExp	=/^ \s* set \s+(\S+)\s* $/isx;
		private static const EXIT:RegExp			=/^ \s* exit \s* $/isx;

		private static const oZOOM:uint=2;
		private static const oGROUP:uint=3;
		private static const oCONDITION:uint=4;
		private static const oOBJECT:uint=5;
		private static const oDECLARATION:uint=6;

		private static const DASH:RegExp=/\-/g;
		private static const COLOR:RegExp=/color$/;
		private static const BOLD:RegExp=/^bold$/i;
		private static const ITALIC:RegExp=/^italic|oblique$/i;
		private static const UNDERLINE:RegExp=/^underline$/i;
		private static const CAPS:RegExp=/^uppercase$/i;
		private static const CENTER:RegExp=/^center$/i;
		private static const FALSE:RegExp=/^(no|false|0)$/i;

		private static const HEX:RegExp=/^#([0-9a-f]+)$/i;
		private static const CSSCOLORS:Object = {
			aliceblue:0xf0f8ff,
			antiquewhite:0xfaebd7,
			aqua:0x00ffff,
			aquamarine:0x7fffd4,
			azure:0xf0ffff,
			beige:0xf5f5dc,
			bisque:0xffe4c4,
			black:0x000000,
			blanchedalmond:0xffebcd,
			blue:0x0000ff,
			blueviolet:0x8a2be2,
			brown:0xa52a2a,
			burlywood:0xdeb887,
			cadetblue:0x5f9ea0,
			chartreuse:0x7fff00,
			chocolate:0xd2691e,
			coral:0xff7f50,
			cornflowerblue:0x6495ed,
			cornsilk:0xfff8dc,
			crimson:0xdc143c,
			cyan:0x00ffff,
			darkblue:0x00008b,
			darkcyan:0x008b8b,
			darkgoldenrod:0xb8860b,
			darkgray:0xa9a9a9,
			darkgreen:0x006400,
			darkkhaki:0xbdb76b,
			darkmagenta:0x8b008b,
			darkolivegreen:0x556b2f,
			darkorange:0xff8c00,
			darkorchid:0x9932cc,
			darkred:0x8b0000,
			darksalmon:0xe9967a,
			darkseagreen:0x8fbc8f,
			darkslateblue:0x483d8b,
			darkslategray:0x2f4f4f,
			darkturquoise:0x00ced1,
			darkviolet:0x9400d3,
			deeppink:0xff1493,
			deepskyblue:0x00bfff,
			dimgray:0x696969,
			dodgerblue:0x1e90ff,
			firebrick:0xb22222,
			floralwhite:0xfffaf0,
			forestgreen:0x228b22,
			fuchsia:0xff00ff,
			gainsboro:0xdcdcdc,
			ghostwhite:0xf8f8ff,
			gold:0xffd700,
			goldenrod:0xdaa520,
			gray:0x808080,
			green:0x008000,
			greenyellow:0xadff2f,
			honeydew:0xf0fff0,
			hotpink:0xff69b4,
			indianred :0xcd5c5c,
			indigo :0x4b0082,
			ivory:0xfffff0,
			khaki:0xf0e68c,
			lavender:0xe6e6fa,
			lavenderblush:0xfff0f5,
			lawngreen:0x7cfc00,
			lemonchiffon:0xfffacd,
			lightblue:0xadd8e6,
			lightcoral:0xf08080,
			lightcyan:0xe0ffff,
			lightgoldenrodyellow:0xfafad2,
			lightgrey:0xd3d3d3,
			lightgreen:0x90ee90,
			lightpink:0xffb6c1,
			lightsalmon:0xffa07a,
			lightseagreen:0x20b2aa,
			lightskyblue:0x87cefa,
			lightslategray:0x778899,
			lightsteelblue:0xb0c4de,
			lightyellow:0xffffe0,
			lime:0x00ff00,
			limegreen:0x32cd32,
			linen:0xfaf0e6,
			magenta:0xff00ff,
			maroon:0x800000,
			mediumaquamarine:0x66cdaa,
			mediumblue:0x0000cd,
			mediumorchid:0xba55d3,
			mediumpurple:0x9370d8,
			mediumseagreen:0x3cb371,
			mediumslateblue:0x7b68ee,
			mediumspringgreen:0x00fa9a,
			mediumturquoise:0x48d1cc,
			mediumvioletred:0xc71585,
			midnightblue:0x191970,
			mintcream:0xf5fffa,
			mistyrose:0xffe4e1,
			moccasin:0xffe4b5,
			navajowhite:0xffdead,
			navy:0x000080,
			oldlace:0xfdf5e6,
			olive:0x808000,
			olivedrab:0x6b8e23,
			orange:0xffa500,
			orangered:0xff4500,
			orchid:0xda70d6,
			palegoldenrod:0xeee8aa,
			palegreen:0x98fb98,
			paleturquoise:0xafeeee,
			palevioletred:0xd87093,
			papayawhip:0xffefd5,
			peachpuff:0xffdab9,
			peru:0xcd853f,
			pink:0xffc0cb,
			plum:0xdda0dd,
			powderblue:0xb0e0e6,
			purple:0x800080,
			red:0xff0000,
			rosybrown:0xbc8f8f,
			royalblue:0x4169e1,
			saddlebrown:0x8b4513,
			salmon:0xfa8072,
			sandybrown:0xf4a460,
			seagreen:0x2e8b57,
			seashell:0xfff5ee,
			sienna:0xa0522d,
			silver:0xc0c0c0,
			skyblue:0x87ceeb,
			slateblue:0x6a5acd,
			slategray:0x708090,
			snow:0xfffafa,
			springgreen:0x00ff7f,
			steelblue:0x4682b4,
			tan:0xd2b48c,
			teal:0x008080,
			thistle:0xd8bfd8,
			tomato:0xff6347,
			turquoise:0x40e0d0,
			violet:0xee82ee,
			wheat:0xf5deb3,
			white:0xffffff,
			whitesmoke:0xf5f5f5,
			yellow:0xffff00,
			yellowgreen:0x9acd32 };

		public function RuleSet(mins:uint,maxs:uint,redrawCall:Function=null,iconLoadedCallback:Function=null):void {
			minscale = mins;
			maxscale = maxs;
			redrawCallback = redrawCall;
			iconCallback = iconLoadedCallback;
		}

		// Get styles for an object

		public function getStyles(obj:Entity, tags:Object, zoom:uint):StyleList {
			var sl:StyleList=new StyleList();
			for each (var sc:StyleChooser in choosers) {
				sc.updateStyles(obj,tags,sl,imageWidths,zoom);
			}
			return sl;
		}

		// ---------------------------------------------------------------------------------------------------------
		// Loading stylesheet

		public function loadFromCSS(str:String):void {
			if (str.match(/[\s\n\r\t]/)!=null) { parseCSS(str); loaded=true; redrawCallback(); return; }

			var request:DebugURLRequest=new DebugURLRequest(str);
			var loader:URLLoader=new URLLoader();

//			request.method=URLRequestMethod.GET;
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, 					doParseCSS);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
			loader.load(request.request);
		}

		private function doParseCSS(e:Event):void {
			parseCSS(e.target.data);
		}

		private function parseCSS(str:String):void {
			parse(str);
			loaded=true;
			if (evals.length==0) { redrawCallback(); }
			loadImages();
		}


		// ------------------------------------------------------------------------------------------------
		// Load all referenced images
		// ** will duplicate if referenced twice, shouldn't
		
		public function loadImages():void {
			var filename:String;
			for each (var chooser:StyleChooser in choosers) {
				for each (var style:Style in chooser.styles) {
					if      (style is PointStyle  && PointStyle(style).icon_image   ) { filename=PointStyle(style).icon_image; }
					else if (style is ShapeStyle  && ShapeStyle(style).fill_image   ) { filename=ShapeStyle(style).fill_image; }
					else if (style is ShieldStyle && ShieldStyle(style).shield_image) { filename=ShieldStyle(style).shield_image; }
					else { continue; }
					if (filename=='square' || filename=='circle') { continue; }
				
					iconsToLoad++;
					var request:DebugURLRequest=new DebugURLRequest(filename);
					var loader:ExtendedURLLoader=new ExtendedURLLoader();
					loader.dataFormat=URLLoaderDataFormat.BINARY;
					loader.info['filename']=filename;
					loader.addEventListener(Event.COMPLETE, 					loadedImage,			false, 0, true);
					loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	onImageLoadSecurityError,	false, 0, true);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				onImageLoadioError,			false, 0, true);
					loader.load(request.request);
				}
			}
		}

		// data handler

		private function loadedImage(event:Event):void {
			var fn:String=event.target.info['filename'];
			images[fn]=event.target.data;

			var loader:ExtendedLoader = new ExtendedLoader();
			loader.info['filename']=fn;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, measureWidth);
			loader.loadBytes(images[fn]);
		}
		
		private function measureWidth(event:Event):void {
			var fn:String=event.target.loader.info['filename'];
			imageWidths[fn]=event.target.width;
			// ** do we need to explicitly remove the loader object now?

			oneLessImageToLoad();
		}

        private function oneLessImageToLoad():void {
            iconsToLoad--;
            if (iconsToLoad<=0 && iconCallback!=null) { iconCallback(); }
        }

        private function onImageLoadioError ( event:IOErrorEvent ):void {
            trace("ioerrorevent: "+event.target.info['filename']);
            oneLessImageToLoad();
        }

        private function onImageLoadSecurityError ( event:SecurityErrorEvent ):void {
            trace("securityerrorevent: "+event.target.info['filename']);
            oneLessImageToLoad();
        }

		private function httpStatusHandler( event:HTTPStatusEvent ):void { }
		private function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		private function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }

		// ------------------------------------------------------------------------------------------------
		// Parse CSS

		public function parse(css:String):void {
			var previous:uint=0;					// what was the previous CSS word?
			var sc:StyleChooser=new StyleChooser();	// currently being assembled
			choosers=new Array();
			evals=new Array();

			var o:Object=new Object();
			while (css.length>0) {

				// CSS comment
				if ((o=COMMENT.exec(css))) {
					css=css.replace(COMMENT,'');

				// Whitespace (probably only at beginning of file)
				} else if ((o=WHITESPACE.exec(css))) {
					css=css.replace(WHITESPACE,'');

				// Class - .motorway, .builtup, :hover
				} else if ((o=CLASS.exec(css))) {
					if (previous==oDECLARATION) { saveChooser(sc); sc=new StyleChooser(); }

					css=css.replace(CLASS,'');
					sc.addCondition(new Condition('set',o[1]));
					previous=oCONDITION;

				// Not class - !.motorway, !.builtup, !:hover
				} else if ((o=NOT_CLASS.exec(css))) {
					if (previous==oDECLARATION) { saveChooser(sc); sc=new StyleChooser(); }

					css=css.replace(NOT_CLASS,'');
					sc.addCondition(new Condition('unset',o[1]));
					previous=oCONDITION;

				// Zoom
				} else if ((o=ZOOM.exec(css))) {
					if (previous!=oOBJECT && previous!=oCONDITION) { sc.newObject(); }

					css=css.replace(ZOOM,'');
					var z:Array=parseZoom(o[1]);
					sc.addZoom(z[0],z[1]);
					previous=oZOOM;

				// Grouping - just a comma
				} else if ((o=GROUP.exec(css))) {
					css=css.replace(GROUP,'');
					sc.newGroup();
					previous=oGROUP;

				// Condition - [highway=primary]
				} else if ((o=CONDITION.exec(css))) {
					if (previous==oDECLARATION) { saveChooser(sc); sc=new StyleChooser(); }
					if (previous!=oOBJECT && previous!=oZOOM && previous!=oCONDITION) { sc.newObject(); }
					css=css.replace(CONDITION,'');
					sc.addCondition(parseCondition(o[1]) as Condition);
					previous=oCONDITION;

				// Object - way, node, relation
				} else if ((o=OBJECT.exec(css))) {
					if (previous==oDECLARATION) { saveChooser(sc); sc=new StyleChooser(); }

					css=css.replace(OBJECT,'');
					sc.newObject(o[1]);
					previous=oOBJECT;

				// Declaration - {...}
				} else if ((o=DECLARATION.exec(css))) {
					css=css.replace(DECLARATION,'');
					sc.addStyles(parseDeclaration(o[1]));
					previous=oDECLARATION;
				
				// Unknown pattern
				} else if ((o=UNKNOWN.exec(css))) {
					css=css.replace(UNKNOWN,'');
					Globals.vars.root.addDebug("unknown: "+o[1]);
					// ** do some debugging with o[1]

				} else {
					Globals.vars.root.addDebug("choked on "+css);
					return;
				}
			}
			if (previous==oDECLARATION) { saveChooser(sc); sc=new StyleChooser(); }
		}
		
		private function saveChooser(sc:StyleChooser):void {
			choosers.push(sc);
		};
		
		private function saveEval(expr:String):Eval {
			evalsToLoad++;
			var e:Eval=new Eval(expr);
			e.addEventListener("swf_loaded",evalLoaded);
			evals.push(e);
			return e;
		}
		
		private function evalLoaded(e:Event):void {
			evalsToLoad--;
			if (evalsToLoad==0) { redrawCallback(); }
		}

		// Parse declaration string into list of styles

		private function parseDeclaration(s:String):Array {
			var styles:Array=[];
			var t:Object=new Object();
			var o:Object=new Object();
			var a:String, k:String, v:*;

			// Create styles
			var ss:ShapeStyle =new ShapeStyle() ;
			var ps:PointStyle =new PointStyle() ; 
			var ts:TextStyle  =new TextStyle()  ; 
			var hs:ShieldStyle=new ShieldStyle(); 
			var xs:InstructionStyle=new InstructionStyle(); 

			for each (a in s.split(';')) {
				if ((o=ASSIGNMENT_EVAL.exec(a)))   { t[o[1].replace(DASH,'_')]=saveEval(o[2]); }
				else if ((o=ASSIGNMENT.exec(a)))   { t[o[1].replace(DASH,'_')]=o[2]; }
				else if ((o=SET_TAG_EVAL.exec(a))) { xs.addSetTag(o[1],saveEval(o[2])); }
				else if ((o=SET_TAG.exec(a)))      { xs.addSetTag(o[1],o[2]); }
				else if ((o=SET_TAG_TRUE.exec(a))) { xs.addSetTag(o[1],true); }
				else if ((o=EXIT.exec(a))) { xs.setPropertyFromString('breaker',true); }
			}

			// Find sublayer
			var sub:uint=5;
			if (t['z_index']) { sub=Number(t['z_index']); delete t['z_index']; }
			ss.sublayer=ps.sublayer=ts.sublayer=hs.sublayer=sub;
			xs.sublayer=10;
			
			// Find interactive
			var inter:Boolean=true;
			if (t['interactive']) { inter=t['interactive'].match(FALSE) ? false : true; delete t['interactive']; }
			ss.interactive=ps.interactive=ts.interactive=hs.interactive=xs.interactive=inter;

			// Munge special values
			if (t['font_weight']    ) { t['font_bold'  ]    = t['font_weight'    ].match(BOLD  )    ? true : false; delete t['font_weight']; }
			if (t['font_style']     ) { t['font_italic']    = t['font_style'     ].match(ITALIC)    ? true : false; delete t['font_style']; }
			if (t['text_decoration']) { t['font_underline'] = t['text_decoration'].match(UNDERLINE) ? true : false; delete t['text_decoration']; }
			if (t['text_position']  ) { t['text_center']    = t['text_position'  ].match(CENTER)    ? true : false; delete t['text_position']; }
			if (t['text_transform']) {
				// ** needs other transformations, e.g. lower-case, sentence-case
				if (t['text_transform'].match(CAPS)) { t['font_caps']=true; } else { t['font_caps']=false; }
				delete t['text_transform'];
			}

			// ** Do compound settings (e.g. line: 5px dotted blue;)

			// Assign each property to the appropriate style
			for (a in t) {
				// Parse properties
				// ** also do units, e.g. px/pt/m
				if (a.match(COLOR)) { v = parseCSSColor(t[a]); }
				               else { v = t[a]; }
				
				// Set in styles
				if      (ss.hasOwnProperty(a)) { ss.setPropertyFromString(a,v); }
				else if (ps.hasOwnProperty(a)) { ps.setPropertyFromString(a,v); }
				else if (ts.hasOwnProperty(a)) { ts.setPropertyFromString(a,v); }
				else if (hs.hasOwnProperty(a)) { hs.setPropertyFromString(a,v); }
			}

			// Add each style to list
			if (ss.edited) { styles.push(ss); }
			if (ps.edited) { styles.push(ps); }
			if (ts.edited) { styles.push(ts); }
			if (hs.edited) { styles.push(hs); }
			if (xs.edited) { styles.push(xs); }
			return styles;
		}
		
		private function parseZoom(s:String):Array {
			var o:Object=new Object();
			if ((o=ZOOM_MINMAX.exec(s))) { return [o[1],o[2]]; }
			else if ((o=ZOOM_MIN.exec(s))) { return [o[1],maxscale]; }
			else if ((o=ZOOM_MAX.exec(s))) { return [minscale,o[1]]; }
			else if ((o=ZOOM_SINGLE.exec(s))) { return [o[1],o[1]]; }
			return null;
		}

		private function parseCondition(s:String):Object {
			var o:Object=new Object();
			if      ((o=CONDITION_TRUE.exec(s)))  { return new Condition('true'	,o[1]); }
			else if ((o=CONDITION_FALSE.exec(s))) { return new Condition('false',o[1]); }
			else if ((o=CONDITION_SET.exec(s)))   { return new Condition('set'	,o[1]); }
			else if ((o=CONDITION_UNSET.exec(s))) { return new Condition('unset',o[1]); }
			else if ((o=CONDITION_NE.exec(s)))    { return new Condition('ne'	,o[1],o[2]); }
			else if ((o=CONDITION_GT.exec(s)))    { return new Condition('>'	,o[1],o[2]); }
			else if ((o=CONDITION_GE.exec(s)))    { return new Condition('>='	,o[1],o[2]); }
			else if ((o=CONDITION_LT.exec(s)))    { return new Condition('<'	,o[1],o[2]); }
			else if ((o=CONDITION_LE.exec(s)))    { return new Condition('<='	,o[1],o[2]); }
			else if ((o=CONDITION_REGEX.exec(s))) { return new Condition('regex',o[1],o[2]); }
			else if ((o=CONDITION_EQ.exec(s)))    { return new Condition('eq'	,o[1],o[2]); }
			return null;
		}

        public static function parseCSSColor(colorStr:String):uint {
            colorStr = colorStr.toLowerCase();
            if (CSSCOLORS[colorStr]) {
                return CSSCOLORS[colorStr];
            } else {
                var match:Object = HEX.exec(colorStr);
                if ( match ) { 
                  if ( match[1].length == 3) {
                    // repeat digits. #abc => 0xaabbcc
                    return Number("0x"+match[1].charAt(0)+match[1].charAt(0)+
                                       match[1].charAt(1)+match[1].charAt(1)+
                                       match[1].charAt(2)+match[1].charAt(2));
                  } else if ( match[1].length == 6) {
                    return Number("0x"+match[1]);
                  } else {
                    return Number("0x000000"); //as good as any
                  }
                }
            }
            return 0;
        }
	}
}
