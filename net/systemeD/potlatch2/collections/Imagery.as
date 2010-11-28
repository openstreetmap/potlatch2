package net.systemeD.potlatch2.collections {

	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.net.*;
	import net.systemeD.halcyon.DebugURLRequest;
	import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.FunctionKeyManager;
	import net.systemeD.potlatch2.Yahoo;
	import mx.collections.ArrayCollection;

	/*
		There's lots of further tidying we can do:
		- remove all the horrid Yahoo stuff
		- remove the backreferences to _map and send events instead
		but this will do for now and help remove the clutter from potlatch2.mxml.
	*/

	public class Imagery extends EventDispatcher {

        private static const GLOBAL_INSTANCE:Imagery = new Imagery();
        public static function instance():Imagery { return GLOBAL_INSTANCE; }

		public var collection:Array=[];
		public var selected:Object={};
		private var _yahooDefault:Boolean=false;
		private var _map:Map;
		private var _yahoo:Yahoo;

		/* Load catalogue file */

		public function init(map:Map,yahoo:Yahoo,yahooDefault:Boolean):void {
			_map = map;
			_yahoo = yahoo;
			_yahooDefault = yahooDefault;
	        var request:DebugURLRequest = new DebugURLRequest("imagery.xml");
	        var loader:URLLoader = new URLLoader();
	        loader.addEventListener(Event.COMPLETE, onImageryLoad);
	        loader.load(request.request);
		}

        private function onImageryLoad(event:Event):void {
			var xml:XML = new XML(URLLoader(event.target).data);
			var saved:Object;
			if (SharedObject.getLocal("user_state").data['background_url']) {
				saved={ name: SharedObject.getLocal("user_state").data['background_name'],
						url:  SharedObject.getLocal("user_state").data['background_url' ] };
			} else {
				saved={ url: ''};
			}

			var isSet:Boolean=false;
            var backgroundSet:Boolean = false;

            collection=new Array(
				{ name: "None", url: "" },
				{ name: "Yahoo", url: "yahoo", sourcetag: "Yahoo" } );
			for each(var set:XML in xml.set) {
				var obj:Object={};
				var a:XML;
				for each (a in set.@*) { obj[a.name().localName]=a.toString(); }
				for each (a in set.* ) { obj[a.name()          ]=a.toString(); }
                collection.push(obj);
				if ((obj.url ==saved.url) ||
				    (obj.name==saved.name && obj.name!='Custom')) { isSet=true; }
			}

            if (!isSet && saved.name && saved.url && saved.url!='' && saved.url!='yahoo') {
                collection.push(saved);
                isSet=true;
            }

			for each (var bg:Object in collection) {
				if (bg.name==saved.name || bg.url==saved.url) {
					setBackground(bg);
                    backgroundSet = true;
				}
			}

            // For most contributors it's useful to set the background to yahoo by default, I reckon, but lets make it a config
            if (!backgroundSet && _yahooDefault) {
                setBackground(collection[1]);
            }
			FunctionKeyManager.instance().registerListener('Background imagery',
				function(o:String):void { setBackground(findBackgroundWithName(o)); });
			dispatchEvent(new Event("collection_changed"));
		}
		
		public function setBackground(bg:Object):void {
			if (bg.url=='yahoo') { _map.setBackground({url:''}); _yahoo.show(); }
			                else { _map.setBackground(bg      ); _yahoo.hide(); }
			selected=bg;
			var obj:SharedObject = SharedObject.getLocal("user_state");
			obj.setProperty('background_url' ,String(bg.url));
			obj.setProperty('background_name',String(bg.name));
			obj.flush();
		}
		
		private function findBackgroundWithName(name:String):Object {
			for each (var bg:Object in collection) {
				if (bg.name==name) { return bg; }
			}
			return { url:'' };
		}

		[Bindable(event="collection_changed")]
		public function getAvailableImagery():ArrayCollection {
			var available:Array=[];
			for each (var bg:Object in collection) {
				if (bg.minlon) {
					// if there's a bbox, check the current viewport intersects it
					if (((_map.edge_l>bg.minlon && _map.edge_l<bg.maxlon) ||
					     (_map.edge_r>bg.minlon && _map.edge_r<bg.maxlon) ||
					     (_map.edge_l<bg.minlon && _map.edge_r>bg.maxlon)) &&
					    ((_map.edge_b>bg.minlat && _map.edge_b<bg.maxlat) ||
					     (_map.edge_t>bg.minlat && _map.edge_t<bg.maxlat) ||
					     (_map.edge_b<bg.minlat && _map.edge_t>bg.maxlat))) {
						available.push(bg);
					}
				} else {
					// if there's no bbox (i.e. global set), include it anyway
					available.push(bg);
				}
			}
			return new ArrayCollection(available);
		}

	}
	
}
