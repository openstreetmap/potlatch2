package net.systemeD.halcyon.styleparser {

	import flash.events.*;
	import flash.net.*;
	import net.systemeD.halcyon.ExtendedLoader;
	import net.systemeD.halcyon.ExtendedURLLoader;
    import net.systemeD.halcyon.connection.Entity;

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
//	import bustin.dev.Inspector;
	
	public class RuleSet {

		private var minscale:uint;
		private var maxscale:uint;
		public var loaded:Boolean=false;			// has it loaded yet?
		public var choosers:Array=new Array();		// list of StyleChoosers
		public var images:Object=new Object();		// loaded images
		public var imageWidths:Object=new Object();	// width of each bitmap image
		private var redrawCallback:Function=null;	// function to call when CSS loaded
		private var iconCallback:Function=null;		// function to call when all icons loaded
		private var iconsToLoad:uint=0;				// number of icons left to load (fire callback when ==0)

		// variables for name, author etc.

		public function RuleSet(mins:uint,maxs:uint,redrawCall:Function=null,iconLoadedCallback:Function=null):void {
			minscale = mins;
			maxscale = maxs;
			redrawCallback = redrawCall;
			iconCallback = iconLoadedCallback;
		}

		// Get styles for an object

		public function getStyles(obj:Entity,tags:Object):StyleList {
			var sl:StyleList=new StyleList();
			for each (var sc:StyleChooser in choosers) {
				sc.updateStyles(obj,tags,sl,imageWidths);
			}
			return sl;
		}

		// ---------------------------------------------------------------------------------------------------------
		// Loading stylesheet

		public function loadFromCSS(str:String):void {
			if (str.match(/[\s\n\r\t]/)!=null) { parseCSS(str); redrawCallback(); return; }

			var request:URLRequest=new URLRequest(str);
			var loader:URLLoader=new URLLoader();

			request.method=URLRequestMethod.GET;
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, 					doRedrawCallback);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
			loader.load(request);
		}

		private function parseCSS(str:String):void {
			var css:MapCSS=new MapCSS(minscale,maxscale);
			choosers=css.parse(str);
//			Inspector.getInstance().show();
//			Inspector.getInstance().shelf('Choosers', choosers);
			loadImages();
//			map.redraw();
		}

		private function doRedrawCallback(e:Event):void {
			parseCSS(e.target.data);
			loaded=true;
			redrawCallback();
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
					var request:URLRequest=new URLRequest(filename);
					var loader:ExtendedURLLoader=new ExtendedURLLoader();
					loader.dataFormat=URLLoaderDataFormat.BINARY;
					loader.info['filename']=filename;
					loader.addEventListener(Event.COMPLETE, 					loadedImage,			false, 0, true);
					loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler,	false, 0, true);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler,			false, 0, true);
					loader.load(request);
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

			iconsToLoad--;
			if (iconsToLoad==0 && iconCallback!=null) { iconCallback(); }
		}

		private function httpStatusHandler( event:HTTPStatusEvent ):void { }
		private function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		private function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }

	}
}
