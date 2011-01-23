package net.systemeD.halcyon.styleparser {

	/** A class permitting you to load CSS files containing '@import' rules, which will be 
	*	automatically replaced with the contents of the file.
	*
	*   Typical usage:
	*
	*		cssLoader=new NestedCSSLoader();
	*		cssLoader.addEventListener(Event.COMPLETE, doParseCSS);
	*		cssLoader.load("potlatch.css");
	*
	*	doParseCSS can then access the CSS via event.target.css.
	*/

	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	public class NestedCSSLoader extends EventDispatcher {
		private var sourceCSS:String;
		public var css:String;
		private var url:String;
		private var count:int;

		private static const IMPORT:RegExp=/@import [^'"]*['"]([^'"]+)['"][^;]*;/g;		// '

		public function NestedCSSLoader() {
		}
		
		public function load(url:String):void {
			this.url=url;
			var request:URLRequest=new URLRequest(url+"?d="+Math.random());
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, fileLoaded);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fileError);
			loader.addEventListener(IOErrorEvent.IO_ERROR, fileError);
			loader.load(request);
		}
		
		private function fileLoaded(event:Event):void {
			sourceCSS=URLLoader(event.target).data;
			css=sourceCSS;
			count=0;

			var result:Object=IMPORT.exec(sourceCSS);
			while (result!=null) {
				count++;
				replaceCSS(result[1],result[0]);
				result=IMPORT.exec(sourceCSS);
			}
			if (count==0) { fireComplete(); }
		}

		private function replaceCSS(filename:String, toReplace:String):void {
			var cssLoader:NestedCSSLoader=new NestedCSSLoader();
			var replaceText:String=toReplace;
			cssLoader.addEventListener(Event.COMPLETE, function(event:Event):void {
				css=css.replace(replaceText,event.target.css);
				decreaseCount();
			});
			cssLoader.load(filename+"?d="+Math.random());
		}

		private function fileError(event:Event):void {
			// just fire a complete event so we don't get an error dialogue
			fireComplete();
		}
		
		private function decreaseCount():void {
			count--; if (count>0) return;
			fireComplete();
		}
		
		private function fireComplete():void {
			var event:Event=new Event(Event.COMPLETE);
			dispatchEvent(event);
		}
	}
}
