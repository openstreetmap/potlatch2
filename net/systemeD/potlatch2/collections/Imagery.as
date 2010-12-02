package net.systemeD.potlatch2.collections {

	import flash.events.*;
	import flash.display.*;
	import flash.net.*;
	import flash.text.TextField;
	import net.systemeD.halcyon.DebugURLRequest;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapEvent;
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

		private var _map:Map;
		private var _overlay:Sprite;
		private var _yahoo:Yahoo;

		/* Load catalogue file */

		public function init(map:Map, overlay:Sprite, yahoo:Yahoo):void {
			_map = map;
			_overlay = overlay;
			_yahoo = yahoo;

			// load imagery file
	        var request:DebugURLRequest = new DebugURLRequest("imagery.xml");
	        var loader:URLLoader = new URLLoader();
	        loader.addEventListener(Event.COMPLETE, onImageryLoad);
	        loader.load(request.request);

			// create map listeners
			map.addEventListener(MapEvent.MOVE, moveHandler);
			map.addEventListener(MapEvent.RESIZE, resizeHandler);
		}

        private function onImageryLoad(event:Event):void {
			var xml:XML = new XML(URLLoader(event.target).data);
			var saved:Object = {};
			var bg:Object;
			if (SharedObject.getLocal("user_state").data['background_url']) {
				saved={ name: SharedObject.getLocal("user_state").data['background_name'],
						url:  SharedObject.getLocal("user_state").data['background_url' ] };
			}

			var isSet:Boolean=false;
            var backgroundSet:Boolean = false;

			// Read all values from XML file
            collection=new Array(
				{ name: "None", url: "" },
				{ name: "Yahoo", url: "yahoo", sourcetag: "Yahoo" } );
			for each(var set:XML in xml.set) {
				var obj:Object={};
				var a:XML;
				for each (a in set.@*) { obj[a.name().localName]=a.toString(); }
				for each (a in set.* ) { obj[a.name()          ]=a.toString(); }
                collection.push(obj);
				if ((saved.url  && obj.url ==saved.url) ||
				    (saved.name && obj.name==saved.name && obj.name!='Custom')) { isSet=true; }
			}

			// Add user's previous preference (from SharedObject) if we didn't find it in the XML file
            if (!isSet && saved.name && saved.url && saved.url!='' && saved.url!='yahoo') {
                collection.push(saved);
                isSet=true;
            }

			// Automatically select the user's previous preference
			var defaultBackground:Object=null;
			for each (bg in collection) {
				if (bg.name==saved.name || bg.url==saved.url) {
					setBackground(bg);
                    backgroundSet = true;
				} else if (bg.default) {
					defaultBackground=bg;
				}
			}

            // Otherwise, set whatever's specified as default
            if (!backgroundSet && defaultBackground) {
                setBackground(defaultBackground);
            }

			// Get any attribution and logo details
			for each (bg in collection) {
				if (bg.logo) {
					// load the logo
					var loader:Loader = new Loader();
					var thisbg1:Object = bg;			// scope it for the closure
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void { onLogoLoad(e,thisbg1); });
					loader.load(new URLRequest(bg.logo));
				}
				if (bg.attribution_url) {
					// load the attribution
					trace("requesting "+bg.attribution_url);
			        var urlloader:URLLoader = new URLLoader();
					var thisbg2:Object = bg;			// scope it for the closure
					urlloader.addEventListener(Event.COMPLETE, function(e:Event):void { onAttributionLoad(e,thisbg2); });
			        urlloader.load(new URLRequest(bg.attribution_url));
				}
			}

			// Tell the function key manager that we'd like to receive function key calls
			FunctionKeyManager.instance().registerListener('Background imagery',
				function(o:String):void { setBackground(findBackgroundWithName(o)); });
			dispatchEvent(new Event("collection_changed"));
		}
		
		public function onLogoLoad(e:Event, bg:Object):void {
			bg.logoData  = Bitmap(LoaderInfo(e.target).content).bitmapData;
			bg.logoWidth = e.target.loader.width;
			bg.logoHeight= e.target.loader.height;
			setLogo();
		}
		
		public function onAttributionLoad(e:Event,bg: Object):void {
			trace ("onAttributionLoad");
			// if we ever need to cope with non-Microsoft attribution, then this should look at bg.scheme
            default xml namespace = Namespace("http://schemas.microsoft.com/search/local/ws/rest/v1");
            var xml:XML = new XML(e.target.data);
			var attribution:Object = {};
            for each (var ImageryProvider:XML in xml..ImageryProvider) {
                var areas:Array=[];
                for each (var CoverageArea:XML in ImageryProvider.CoverageArea) {
                    areas.push([CoverageArea.ZoomMin,
                                CoverageArea.ZoomMax,
                                CoverageArea.BoundingBox.SouthLatitude,
                                CoverageArea.BoundingBox.WestLongitude,
                                CoverageArea.BoundingBox.NorthLatitude,
                                CoverageArea.BoundingBox.EastLongitude]);
                }
                attribution[ImageryProvider.Attribution]=areas;
            }
			bg.attribution=attribution;
			setAttribution();
		}

		public function setBackground(bg:Object):void {
			// set background
			selected=bg;
			if (bg.url=='yahoo') { _map.setBackground({url:''}); _yahoo.show(); }
			                else { _map.setBackground(bg      ); _yahoo.hide(); }
			// update attribution and logo
			_overlay.visible=bg.attribution || bg.logo || bg.terms_url;
			setLogo(); setAttribution(); setTerms();
			// save as SharedObject for next time
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

		private function moveHandler(event:MapEvent):void {
			setAttribution();
		}
		private function setAttribution():void {
			var tf:TextField=TextField(_overlay.getChildAt(0));
			tf.text='';
			if (!selected.attribution) return;
			var attr:Array=[];
			for (var provider:String in selected.attribution) {
				for each (var bounds:Array in selected.attribution[provider]) {
					if (_map.scale>=bounds[0] && _map.scale<=bounds[1] &&
					  ((_map.edge_l>bounds[3] && _map.edge_l<bounds[5]) ||
					   (_map.edge_r>bounds[3] && _map.edge_r<bounds[5]) ||
			     	   (_map.edge_l<bounds[3] && _map.edge_r>bounds[5])) &&
					  ((_map.edge_b>bounds[2] && _map.edge_b<bounds[4]) ||
					   (_map.edge_t>bounds[2] && _map.edge_t<bounds[4]) ||
					   (_map.edge_b<bounds[2] && _map.edge_t>bounds[4]))) {
						attr.push(provider);
					}
				}
			}
			if (attr.length==0) return;
			tf.text="Background "+attr.join(", ");
			positionAttribution();
			dispatchEvent(new MapEvent(MapEvent.BUMP, { y: tf.textHeight }));	// don't let the toolbox obscure it
		}
		private function positionAttribution():void {
			var tf:TextField=TextField(_overlay.getChildAt(0));
			tf.x=_map.mapwidth  - 5 - tf.textWidth;
			tf.y=_map.mapheight - 5 - tf.textHeight;
		}

		private function setLogo():void {
			while (_overlay.numChildren>2) { _overlay.removeChildAt(2); }
			if (!selected.logoData) return;
			var logo:Sprite=new Sprite();
			logo.addChild(new Bitmap(selected.logoData));
			if (selected.logo_url) { logo.buttonMode=true; logo.addEventListener(MouseEvent.CLICK, launchLogoLink, false, 0, true); }
			_overlay.addChild(logo);
			positionLogo();
		}
		private function positionLogo():void {
			_overlay.getChildAt(2).x=5;
			_overlay.getChildAt(2).y=_map.mapheight - 5 - selected.logoHeight - (selected.terms_url ? 10 : 0);
		}
		private function launchLogoLink(e:Event):void {
			if (!selected.logo_url) return;
			navigateToURL(new URLRequest(selected.logo_url), '_blank');
		}
		private function setTerms():void {
			var terms:TextField=TextField(_overlay.getChildAt(1));
			if (!selected.terms_url) { terms.text=''; return; }
			terms.text="Background terms of use";
			positionTerms();
			terms.addEventListener(MouseEvent.CLICK, launchTermsLink, false, 0, true);
		}
		private function positionTerms():void {
			_overlay.getChildAt(1).x=5;
			_overlay.getChildAt(1).y=_map.mapheight - 15;
		}
		private function launchTermsLink(e:Event):void {
			if (!selected.terms_url) return;
			navigateToURL(new URLRequest(selected.terms_url), '_blank');
		}

		private function resizeHandler(event:MapEvent):void {
			if (selected.logoData) positionLogo();
			if (selected.terms_url) positionTerms();
			if (selected.attribution) positionAttribution();
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
