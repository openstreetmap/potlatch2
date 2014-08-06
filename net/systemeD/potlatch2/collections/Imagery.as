package net.systemeD.potlatch2.collections {

	import flash.events.*;
	import flash.display.*;
	import flash.net.*;
	import flash.text.TextField;
	import net.systemeD.halcyon.FileBank;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapEvent;
	import net.systemeD.potlatch2.FunctionKeyManager;
	import mx.collections.ArrayCollection;
    import com.adobe.serialization.json.JSON;

	/*
		There's lots of further tidying we can do:
		- remove the backreferences to _map and send events instead
		but this will do for now and help remove the clutter from potlatch2.mxml.
	*/

	public class Imagery extends EventDispatcher {

        private static const GLOBAL_INSTANCE:Imagery = new Imagery();
        public static function instance():Imagery { return GLOBAL_INSTANCE; }

		private static const INDEX_URL:String="http://osmlab.github.io/editor-imagery-index/imagery.json";

		public var collection:Array=[];
		private var _selected:Object={};

		private var _map:Map;
		private var _overlay:Sprite;

		/* Load catalogue file */

		public function init(map:Map, overlay:Sprite):void {
			_map = map;
			_overlay = overlay;

			// load imagery file
			var request:URLRequest = new URLRequest(INDEX_URL);
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onImageryIndexLoad);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			loader.load(request);

			// create map listeners
			map.addEventListener(MapEvent.MOVE_END, moveHandler);
			map.addEventListener(MapEvent.RESIZE, resizeHandler);
		}

		private function onImageryIndexLoad(event:Event):void {
			var result:String = String(event.target.data);
			collection = com.adobe.serialization.json.JSON.decode(result) as Array;

			// Has the user saved something? If so, create dummy object
			var saved:Object = {};
			var bg:Object;
			if (SharedObject.getLocal("user_state","/").data['background_url']!=undefined) {
				saved={ url:  SharedObject.getLocal("user_state","/").data['background_url' ],
						name: SharedObject.getLocal("user_state","/").data['background_name'],
						type: "tms",
						extent: { bbox: { min_lon: -180, max_lon: 180, min_lat: -90, max_lat: 90 } }}
			}

			var isSet:Boolean=false;
            var backgroundSet:Boolean = false;
			collection.unshift({ name: "None", url: "" });

			// Is a set already chosen? (default to Bing if not)
			_selected=null;
			collection.forEach(function(bg:Object, index:int, array:Array):void {
				if (saved.name && saved.name==bg.name) { _selected=bg; }
				if (bg.id=='Bing') {
					bg.url="http://ecn.t{switch:0,1,2,3}.tiles.virtualearth.net/tiles/a{quadkey}.jpeg?g=587&amp;mkt=en-gb&amp;n=z";
					bg.attribution={
						data_url: "http://dev.virtualearth.net/REST/v1/Imagery/Metadata/Aerial/0,0?zl=1&mapVersion=v1&key=Arzdiw4nlOJzRwOz__qailc8NiR31Tt51dN2D7cm57NrnceZnCpgOkmJhNpGoppU&include=ImageryProviders&output=xml",
						logo: "bing_maps.png",
						url: "http://opengeodata.org/microsoft-imagery-details"
					}
				}
				if (bg.id=='Bing' && !_selected) { _selected=bg; }
				if (bg.attribution && bg.attribution.logo) {
					// load the logo (pretty much Bing-only)
					FileBank.getInstance().addFromFile(bg.attribution.logo, function (fb:FileBank, name:String):void {
						bg.logoData   = fb.getAsBitmapData(name);
						bg.logoWidth  = fb.getWidth(name);
						bg.logoHeight = fb.getHeight(name);
						setLogo();
						});
				}
				if (bg.attribution && bg.attribution.data_url) {
					// load the attribution (pretty much Bing-only)
			        var urlloader:URLLoader = new URLLoader();
					urlloader.addEventListener(Event.COMPLETE, function(e:Event):void { onAttributionLoad(e,bg); });
					urlloader.addEventListener(IOErrorEvent.IO_ERROR, onError);
					urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			        urlloader.load(new URLRequest(bg.attribution.data_url));
				}
			});
			if (saved.name && !_selected) { collection.push(saved); _selected=saved; }
			setBackground(_selected);

			// Tell the function key manager that we'd like to receive function key calls
			FunctionKeyManager.instance().registerListener('Background imagery',
				function(o:String):void { setBackground(findBackgroundWithName(o)); });
			dispatchEvent(new Event("collection_changed"));
		}
		
		private function onError(e:Event):void {
			// placeholder error routine so exception isn't thrown
		}
		
		public function onAttributionLoad(e:Event,bg: Object):void {
			// if we ever need to cope with non-Microsoft attribution, then this should look at bg.scheme
            default xml namespace = Namespace("http://schemas.microsoft.com/search/local/ws/rest/v1");
            var xml:XML = new XML(e.target.data);
			var providers:Object = {};
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
                providers[ImageryProvider.Attribution]=areas;
            }
			default xml namespace = new Namespace("");
			bg.attribution.providers=providers;
			setAttribution();
		}

		public function setBackground(bg:Object):void {
			// set background
			_selected=bg;
			dispatchEvent(new CollectionEvent(CollectionEvent.SELECT, bg));
			// update attribution and logo
			_overlay.visible=bg.hasOwnProperty('attribution');
			setLogo(); setAttribution(); setTerms();
			// save as SharedObject for next time
			var obj:SharedObject = SharedObject.getLocal("user_state","/");
			obj.setProperty('background_url' ,String(bg.url));
			obj.setProperty('background_name',String(bg.name));
			try { obj.flush(); } catch (e:Error) {}
		}
		
		public function get selected():Object { return _selected; }
		
		private function findBackgroundWithName(name:String):Object {
			for each (var bg:Object in collection) {
				if (bg.name==name) { return bg; }
			}
			return { url:'' };
		}

		private function moveHandler(event:MapEvent):void {
			setAttribution();
			dispatchEvent(new Event("collection_changed"));
		}

		/* --------------------
		   Attribution and logo */

		private function setAttribution():void {
			var tf:TextField=TextField(_overlay.getChildAt(0));
			tf.text='';
			if (!_selected.attribution) return;
			var attr:Array=[];
			if (_selected.attribution.providers) {
				// Bing attribution scheme
				for (var provider:String in _selected.attribution.providers) {
					for each (var bounds:Array in _selected.attribution.providers[provider]) {
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
			if (!_selected.logoData) return;
			var logo:Sprite=new Sprite();
			logo.addChild(new Bitmap(_selected.logoData));
			if (_selected.attribution.url) { logo.buttonMode=true; logo.addEventListener(MouseEvent.CLICK, launchLogoLink, false, 0, true); }
			_overlay.addChild(logo);
			positionLogo();
		}
		private function positionLogo():void {
			_overlay.getChildAt(2).x=5;
			_overlay.getChildAt(2).y=_map.mapheight - 5 - _selected.logoHeight - (_selected.terms_url ? 10 : 0);
		}
		private function launchLogoLink(e:Event):void {
			if (!_selected.attribution.url) return;
			navigateToURL(new URLRequest(_selected.attribution.url), '_blank');
		}
		private function setTerms():void {
			var terms:TextField=TextField(_overlay.getChildAt(1));
			if (!_selected.attribution) { terms.text=''; return; }
			if (_selected.attribution && _selected.attribution.text) { terms.text=_selected.attribution.text; }
			else { terms.text="Background terms of use"; }
			positionTerms();
			terms.addEventListener(MouseEvent.CLICK, launchTermsLink, false, 0, true);
		}
		private function positionTerms():void {
			_overlay.getChildAt(1).x=5;
			_overlay.getChildAt(1).y=_map.mapheight - 15;
		}
		private function launchTermsLink(e:Event):void {
			if (!_selected.attribution.url) return;
			navigateToURL(new URLRequest(_selected.attribution.url), '_blank');
		}

		private function resizeHandler(event:MapEvent):void {
			if (_selected.logoData) positionLogo();
			if (_selected.terms_url) positionTerms();
			if (_selected.attribution) positionAttribution();
		}

        [Bindable(event="collection_changed")]
        public function getCollection():ArrayCollection {
            return new ArrayCollection(collection);
        }

		/* --------------------
		   Imagery index parser */

		[Bindable(event="collection_changed")]
		public function getAvailableImagery():ArrayCollection {
			var available:Array=[];
			for each (var bg:Object in collection) {
				if (bg.extent && bg.extent.polygon) {
					// check if in boundary polygon
					var included:Boolean=false;
					for each (var poly:Array in bg.extent.polygon) {
						if (pointInPolygon(_map.centre_lon, _map.centre_lat, poly)) { included=true; }
					}
					if (included) { available.push(bg); }
				} else if (bg.extent && bg.extent.bbox && bg.extent.bbox.min_lon) {
					// if there's a bbox, check the current viewport intersects it
					if (((_map.edge_l>bg.extent.bbox.min_lon && _map.edge_l<bg.extent.bbox.max_lon) ||
					     (_map.edge_r>bg.extent.bbox.min_lon && _map.edge_r<bg.extent.bbox.max_lon) ||
					     (_map.edge_l<bg.extent.bbox.min_lon && _map.edge_r>bg.extent.bbox.max_lon)) &&
					    ((_map.edge_b>bg.extent.bbox.min_lat && _map.edge_b<bg.extent.bbox.max_lat) ||
					     (_map.edge_t>bg.extent.bbox.min_lat && _map.edge_t<bg.extent.bbox.max_lat) ||
					     (_map.edge_b<bg.extent.bbox.min_lat && _map.edge_t>bg.extent.bbox.max_lat))) {
						available.push(bg);
					}
				} else if (!bg.type || bg.type!='wms') {
					// if there's no bbox (i.e. global set) and default is set, include it
					if (bg.name=='None' || bg.default) { available.push(bg); }
				}
			}
			available.sort(function(a:Object,b:Object):int {
				if (a.name=='None') { return -1; }
				else if (b.name=='None') { return 1; }
				else if (a.name<b.name) { return -1; }
				else if (a.name>b.name) { return 1; }
				return 0;
			});
			return new ArrayCollection(available);
		}

		public function pointInPolygon(x:Number,y:Number,vertices:Array):Boolean {
			// http://muongames.com/2013/07/point-in-a-polygon-in-as3-theory-and-code/
			// Loop through vertices, check if point is left of each line.
			// If it is, check if it line intersects with horizontal ray from point p
			var n:int = vertices.length;
			var j:int;
			var v1:Array, v2:Array;
			var count:int;
			for (var i:int=0; i<n; i++) {
				j = i+1 == n ? 0 : i + 1;
				v1 = vertices[i];
				v2 = vertices[j];
				// does point lie to the left of the line?
				if (isLeft(x,y,v1,v2)) {
					if ((y > v1[1] && y <= v2[1]) || (y > v2[1] && y <= v1[1])) { count++; }
				}
			}
			return (count % 2 == 1);
		}

		public function isLeft(x:Number, y:Number, v1:Array, v2:Array):Boolean {
			if (v1[0] == v2[0]) { return (x <= v1[0]); }
			var m:Number = (v2[1] - v1[1]) / (v2[0] - v1[0]);
			var x2:Number = (y - v1[1]) / m + v1[0];
			return (x <= x2);
		}


	}
	
}
