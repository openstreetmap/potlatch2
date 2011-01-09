package net.systemeD.halcyon {

	/** A class permitting you to load XML files containing 'include' elements (for example,
	*   <include file="cuisine.xml" />, which will be automatically replaced with the contents of the file.
	*
	*   Typical usage:
	*
	*		xmlLoader=new NestedXMLLoader();
	*		xmlLoader.addEventListener(Event.COMPLETE, onFeatureLoad);
	*		xmlLoader.load("root.xml");
	*
	*	onFeatureLoad can then access the XML via event.target.xml.
	*/

	import flash.events.*;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

	public class NestedXMLLoader extends EventDispatcher {
		public var xml:XML = null;
		private var url:String;
		private var count:int;

		public function NestedXMLLoader() {
		}
		
		public function load(url:String):void {
			this.url=url;
			var request:URLRequest=new URLRequest(url+"?d="+Math.random());
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, fileLoaded);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fileError);
			loader.addEventListener(IOErrorEvent.IO_ERROR, fileError);
			loader.load(request);
		}
		
		private function fileLoaded(event:Event):void {
			count=0;
			xml = new XML(URLLoader(event.target).data);
			for each (var inc:XML in xml.descendants('include')) {
				replaceXML(inc);
				count++;
			}
			if (count==0) { fireComplete(); }
		}

		private function replaceXML(inc:XML):void {
			var xmlLoader:NestedXMLLoader=new NestedXMLLoader();
			var includeElement:XML=inc;
			xmlLoader.addEventListener(Event.COMPLETE, function(event:Event):void {
				includeElement.parent().replace(findChildIndex(includeElement),event.target.xml);
				decreaseCount();
			});
			xmlLoader.load(inc.@file+"?d="+Math.random());
		}

		private function findChildIndex(child:XML):int {
			var i:uint=0;
			for each (var sibling:XML in child.parent().children()) {
				if (sibling==child) return i;
				i++;
			}
			return -1;
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
