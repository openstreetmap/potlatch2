package net.systemeD.potlatch2.collections {

	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.net.*;
	import net.systemeD.halcyon.DebugURLRequest;
	import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.FunctionKeyManager;
	import net.systemeD.potlatch2.Yahoo;
	import mx.collections.ArrayCollection;

	public class Stylesheets extends EventDispatcher {

        private static const GLOBAL_INSTANCE:Stylesheets = new Stylesheets();
        public static function instance():Stylesheets { return GLOBAL_INSTANCE; }

		public var collection:Array=[];
		public var selected:Object={};
		private var _map:Map;

		/* Load catalogue file */

		public function init(map:Map):void {
			_map=map;
			var request:DebugURLRequest = new DebugURLRequest("stylesheets.xml");
			var loader:URLLoader = new URLLoader();
	        loader.addEventListener(Event.COMPLETE, onStylesheetsLoad);
	        loader.load(request.request);
		}

		private function onStylesheetsLoad(event:Event):void {
			var xml:XML = new XML(URLLoader(event.target).data);
			var saved_url:String = SharedObject.getLocal("user_state").data['stylesheet_url'];
			var saved_name:String= SharedObject.getLocal("user_state").data['stylesheet_name'];
			var isInMenu:Boolean=false, isSet:Boolean=false;

            // first, build the menu from the stylesheet list.
            // Also ensure the saved_url is in the menu (might be either saved from before, or supplied via loaderInfo)
            collection=new Array();
			for each(var set:XML in xml.stylesheet) {
				var obj:Object={};
				for (var a:String in set.children()) {
					obj[set.child(a).name()]=set.child(a);
				}
                collection.push(obj);
				if (obj.url==saved_url || (obj.name==saved_name && obj.name!='Custom')) { isInMenu=true; }
			}
			if (saved_url && !isInMenu) { collection.push({ name:saved_name, url:saved_url }); }

            // pick a stylesheet to be set. It should be the saved one, if it is in the menu
            // or alternatively the first one on the menu,
            // or finally try 'stylesheets/potlatch.css'
			for each (var ss:Object in collection) {
				if (ss.name==saved_name || ss.url==saved_url) {
					setStylesheet(ss.name, ss.url);
                    isSet = true;
                    break;
				}
			}
            if (!isSet) {
              if(collection.length > 0) {
                var s:Object = collection[0];
                setStylesheet(s.name, s.url);
              } else {
                //hit and hope. FIXME should this be an error state?
                collection.push({ name:'Potlatch', url:'stylesheets/potlatch.css'});
                setStylesheet('Potlatch','stylesheets/potlatch.css');
              }
            }
			FunctionKeyManager.instance().registerListener('Map style',
				function(o:String):void { setStylesheet(o,findStylesheetURLWithName(o)); });
			dispatchEvent(new Event("collection_changed"));
		}

		public function setStylesheet(name:String,url:String):void {
			_map.setStyle(url);
			var obj:SharedObject = SharedObject.getLocal("user_state");
			obj.setProperty("stylesheet_url",url);
			obj.setProperty("stylesheet_name",name);
			obj.flush();
		}

		private function findStylesheetURLWithName(name:String):String {
			for each (var ss:Object in collection) {
				if (ss.name==name) { return ss.url; }
			}
			return '';
		}
		
		[Bindable(event="collection_changed")]
		public function getCollection():ArrayCollection {
			return new ArrayCollection(collection);
		}

	}
}
