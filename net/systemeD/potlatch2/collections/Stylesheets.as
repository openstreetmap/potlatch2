package net.systemeD.potlatch2.collections {

	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.net.*;
	import net.systemeD.halcyon.FileBank;
	import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.FunctionKeyManager;
	import mx.collections.ArrayCollection;

	public class Stylesheets extends EventDispatcher {

        private static const GLOBAL_INSTANCE:Stylesheets = new Stylesheets();
        public static function instance():Stylesheets { return GLOBAL_INSTANCE; }

		private static const DEFAULT:String = 'stylesheets/potlatch.css';

		public var collection:Array=[];
		private var _selected:String;

		/* Load catalogue file */

		public function init(request_url:String=null):void {
			// First, we set _selected in case it's needed before the stylesheet catalogue loads
			_selected=request_url;
			_selected=_selected ? _selected : SharedObject.getLocal("user_state").data['stylesheet_url'];
			_selected=_selected ? _selected : DEFAULT;
			
			// Load the stylesheet catalogue
            FileBank.getInstance().addFromFile("stylesheets.xml", function (fb:FileBank, name:String):void {
                onStylesheetsLoad(fb, name, request_url);
            });
		}

		private function onStylesheetsLoad(fileBank:FileBank, filename:String, request_url:String=null):void {
			var xml:XML = new XML(fileBank.getAsString(filename));
			var saved_url:String = SharedObject.getLocal("user_state").data['stylesheet_url'];
			var saved_name:String= SharedObject.getLocal("user_state").data['stylesheet_name'];
			if (request_url && request_url!=saved_url) { saved_url=request_url; saved_name='Custom'; }
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
				if (obj.url==saved_url) { isInMenu=true; }
				else if (obj.name==saved_name && obj.name!='Custom') { isInMenu=true; saved_url=obj.url; }
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
                collection.push({ name:'Potlatch', url:DEFAULT});
                setStylesheet('Potlatch',DEFAULT);
              }
            }
			FunctionKeyManager.instance().registerListener('Map style',
				function(o:String):void { setStylesheet(o,findStylesheetURLWithName(o)); });
			dispatchEvent(new Event("collection_changed"));
		}

		public function setStylesheet(name:String,url:String):void {
			_selected=url;
			dispatchEvent(new CollectionEvent(CollectionEvent.SELECT, url));
			var obj:SharedObject = SharedObject.getLocal("user_state");
			obj.setProperty("stylesheet_url",url);
			obj.setProperty("stylesheet_name",name);
			obj.flush();
		}
		
		public function get selected():String { return _selected; }

		private function findStylesheetURLWithName(name:String):String {
			for each (var ss:Object in collection) {
				if (ss.name==name) { return ss.url; }
			}
			return '';
		}
		
		[Bindable(event="collection_changed")]
		public function getCollection():ArrayCollection {
			var available:Array=[];
			for each (var ss:Object in collection) {
				if (!ss.corestyle || ss.corestyle!='no') available.push(ss);
			}
			return new ArrayCollection(available);
		}
	}
}
