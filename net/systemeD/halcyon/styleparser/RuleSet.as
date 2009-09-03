package net.systemeD.halcyon.styleparser {

	import org.as3yaml.*;
	import flash.events.*;
	import flash.net.*;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.connection.Entity;
//	import bustin.dev.Inspector;
	
	public class RuleSet {

		private var map:Map;
		public var choosers:Array=new Array();	// list of StyleChoosers
		public var images:Object=new Object();	// loaded images
		private var iconCallback:Function=null;	// function to call when all icons loaded
		private var iconsToLoad:uint=0;			// number of icons left to load (fire callback when ==0)

		// variables for name, author etc.

		public function RuleSet(m:Map,f:Function=null):void {
			map=m;
			iconCallback=f;
		}

		// Get styles for an object

		public function getStyles(obj:Entity,tags:Object):StyleList {
			var sl:StyleList=new StyleList();
			for each (var sc:StyleChooser in choosers) {
				sc.updateStyles(obj,tags,sl);
			}
			return sl;
		}

		// ---------------------------------------------------------------------------------------------------------
		// Loading stylesheet

		public function loadFromCSS(url:String):void {
			var request:URLRequest=new URLRequest(url);
			var loader:URLLoader=new URLLoader();

			request.method=URLRequestMethod.GET;
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, 					loadedCSS,				false, 0, true);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler,	false, 0, true);
			loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler,			false, 0, true);
			loader.load(request);
		}

		private function loadedCSS(event:Event):void {
			var css:MapCSS=new MapCSS(map);
			choosers=css.parse(event.target.data);
//			Inspector.getInstance().show();
//			Inspector.getInstance().shelf('Choosers', choosers);
		}

		private function httpStatusHandler( event:HTTPStatusEvent ):void { }
		private function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		private function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }


		// ------------------------------------------------------------------------------------------------
		// Load all referenced images
		// ** currently only looks in PointRules
		// ** will duplicate if referenced twice, shouldn't
		
		public function loadImages():void {
			var ps:PointStyle;

			for each (var rule:* in choosers) {
				// if (!(rule is PointRule)) { continue; }
				if (!(rule.pointStyle)) { continue; }
				if (!(rule.pointStyle.icon_image)) { continue; }
				
				iconsToLoad++;
				var request:URLRequest=new URLRequest(rule.pointStyle.icon_image);
				var loader:ImageLoader=new ImageLoader();
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.filename=rule.pointStyle.icon_image;
				loader.addEventListener(Event.COMPLETE, 					loadedImage,			false, 0, true);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler,	false, 0, true);
				loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler,			false, 0, true);
				loader.load(request);
			}
		}

		// data handler

		private function loadedImage(event:Event):void {
			images[event.target.filename]=event.target.data;
			iconsToLoad--;
			if (iconsToLoad==0 && iconCallback!=null) { iconCallback(); }
		}
	}
}
