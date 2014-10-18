package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.net.*;
	import flash.system.LoaderContext;
	import flash.utils.Timer;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import net.systemeD.potlatch2.collections.*;
	/* -------
	   This currently requires potlatch2.collections.Imagery and
	                           potlatch2.collections.CollectionEvent which break Halcyon.
	   ------- */

    public class TileSet extends Sprite {

		public var tile_l:int;
		public var tile_r:int;
		public var tile_b:int;
		public var tile_t:int;

		private var offset_lon:Number=0;
		private var offset_lat:Number=0;

		private var tiles:Object={};		// key is "z,x,y"; value "true" if queued, or reference to loader object if requested
		private var loadcount:int=0;		// number of tiles fully downloaded
		private var baseurl:String;			// e.g. http://npe.openstreetmap.org/$z/$x/$y.png
		private var scheme:String;			// tms or bing
		public var blocks:Array;			// array of regexes which are verboten

		private var count:Number=0;			// counter incremented to provide a/b/c/d tile swapping
		private static const ROUNDROBIN:RegExp =/\{switch\:([^}]+)\}/;

		private var _map:Map;
		private var _overlay:Sprite;
		private const MAXTILESLOADED:uint=30;

		private var sharpenFilter:BitmapFilter = new ConvolutionFilter(3, 3, 
			[0, -1, 0,
            -1, 5, -1,
             0, -1, 0], 0);
		private var sharpening:Boolean = false;
		// http://flylib.com/books/en/2.701.1.170/1/

        public function TileSet(map:Map, overlay:Sprite) {
			_map=map;
			_overlay=overlay;
			createSprites();
			_map.addEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
			_map.addEventListener(MapEvent.MOVE_END, moveHandler);
			_map.addEventListener(MapEvent.RESIZE, resizeHandler);
		}
	
		/** @param params Currently includes "url" and "scheme"
		 * @param update Trigger update now?
		 * @param dim Start with imagery faded?
		 * @param sharpen Start with sharpen filter applied?
		 */
		public function init(params:Object, update:Boolean=false):void {
			baseurl=params.url;
			scheme =params.type ? params.type : 'tms';
			loadcount=0;
			for (var tilename:String in tiles) {
				if (tiles[tilename] is Loader) tiles[tilename].unload();
				tiles[tilename]=null;
			}
			tiles={};
			offset_lon=offset_lat=x=y=0;
			while (numChildren) { removeChildAt(0); }
			createSprites();
			if (update) { this.update(); }
		}

		private function createSprites():void {
			for (var i:uint=_map.MINSCALE; i<=_map.MAXSCALE; i++) {
				this.addChild(new Sprite());
			}
		}

		/** Toggle fading of imagery. */
		public function setDimming(dim:Boolean):void {
			alpha=dim ? 0.5 : 1;
		}
		/** Is imagery currently set faded? */
		public function getDimming():Boolean {
			return (alpha<1);
		}

        /** Toggle sharpen filter. */
		public function setSharpen(sharpen:Boolean):void {
			var f:Array=[]; if (sharpen) { f=[sharpenFilter]; }
			for (var i:uint=0; i<numChildren; i++) {
				var s:Sprite=Sprite(getChildAt(i));
				for (var j:uint=0; j<s.numChildren; j++) {
					s.getChildAt(j).filters=f;
				}
			}
			sharpening=sharpen;
		}
		
		/** Is sharpen filter applied? */
		public function getSharpen():Boolean {
			return sharpening;
		}

		/** Set zoom scale (no update triggerd). */
		public function changeScale(scale:uint):void {
			for (var i:uint=_map.MINSCALE; i<=_map.MAXSCALE; i++) {
				this.getChildAt(i-_map.MINSCALE).visible=(scale==i);
			}
			x=_map.lon2coord(_map.centre_lon+offset_lon)-_map.lon2coord(_map.centre_lon);
			y=_map.lat2coord(_map.centre_lat+offset_lat)-_map.lat2coord(_map.centre_lat);
		}
			
		/** Update bounds of tile area, and request new tiles if needed.  */
		
		public function update():void {
			if (!baseurl) { return; }
			tile_l=lon2tile(_map.edge_l-offset_lon);
			tile_r=lon2tile(_map.edge_r-offset_lon);
			tile_t=lat2tile(_map.edge_t-offset_lat);
			tile_b=lat2tile(_map.edge_b-offset_lat);
			for (var tx:int=tile_l; tx<=tile_r; tx++) {
				for (var ty:int=tile_t; ty<=tile_b; ty++) {
					if (!tiles[_map.scale+','+tx+','+ty]) { 
						var loader:Loader = new Loader();
						tiles[_map.scale+','+tx+','+ty]=loader;
						loader.contentLoaderInfo.addEventListener(Event.INIT, doImgInit, false, 0, true);
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, missingTileError, false, 0, true);
						loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void { tileLoadStatus(e,_map.scale,tx,ty); }, false, 0, true);
						loader.load(new URLRequest(tileURL(tx,ty,_map.scale)), 
						            new LoaderContext(true));
						Sprite(this.getChildAt(_map.scale-_map.MINSCALE)).addChild(loader);
						loader.x=_map.lon2coord(tile2lon(tx));
						loader.y=_map.lat2coord(tile2lat(ty));
						if (sharpening) { loader.filters=[sharpenFilter]; }
					}
				}
			}
		}

        private function missingTileError(event:Event):void {
			return;
		}
		private function tileLoadStatus(event:HTTPStatusEvent,z:int,x:int,y:int):void {
			if (event.status==200) return;				// fine, carry on
			if (event.status==404) return;				// doesn't exist, so ignore forever
			// Dodgy tile response - probably a 502/503 from Bing - so can be retried
			delete tiles[z+','+x+','+y];
		}

		/** Tile image has been downloaded, so start displaying it. */
		protected function doImgInit(event:Event):void {
			loadcount++;
			if (loadcount>MAXTILESLOADED) purgeTiles();
			return;
		}
		
		protected function purgeTiles():void {
			for (var tile:String in tiles) {
				if (tiles[tile] is Sprite) {
					var coords:Array=tile.split(','); var tz:uint=coords[0]; var tx:uint=coords[1]; var ty:uint=coords[1];
					if (tz!=_map.scale || tx<tile_l || tx>tile_r || ty<tile_t || ty<tile_b) {
						if (tiles[tile].parent) tiles[tile].parent.removeChild(tiles[tile]);
						delete tiles[tile];
						loadcount--;
					}
				}
			}
		}

		
		// Assemble tile URL
		
		private function tileURL(tx:int,ty:int,tz:uint):String {
			var t:String='';
			var tmsy:int=Math.pow(2,tz)-1-ty;
			switch (scheme.toLowerCase()) {

				case 'bing':
					var u:String='';
					for (var zoom:uint=tz; zoom>0; zoom--) {
						var byte:uint=0;
						var mask:uint=1<<(zoom-1);
						if ((tx & mask)!=0) byte++;
						if ((ty & mask)!=0) byte+=2;
						u+=String(byte);
					}
					t=baseurl.replace('{quadkey}',u); break;

				default:
					if (baseurl.indexOf('{x}')>-1) {
						t=baseurl.replace('{zoom}',_map.scale).replace('{x}',tx).replace('{y}',ty).replace('{-y}',tmsy);
					} else if (baseurl.indexOf('$x')>-1) {
						t=baseurl.replace('$z',_map.scale).replace('$x',tx).replace('$y',ty).replace('$-y',tmsy);
					} else {
						t=baseurl.replace('!',_map.scale).replace('!',tx).replace('!',ty);
					}
					// also, someone should invent yet another variable substitution scheme
					break;

			}
			var o:Object=new Object();
			if ((o=ROUNDROBIN.exec(t))) {
				var prefixes:Array=o[1].split(',');
				var p:String = prefixes[count % prefixes.length];
				t=t.replace(ROUNDROBIN,p);
				count++;
			}

			for each (var block:* in blocks) { if (t.match(block)) return ''; }
			return t;
		}
		
		public function get url():String {
			return baseurl ? baseurl : '';
		}

		/** Respond to nudge event by updating offset between imagery and map. */
		public function nudgeHandler(event:MapEvent):void {
			if (!baseurl) { return; }
			this.x+=event.params.x; this.y+=event.params.y;
			offset_lat=_map.centre_lat-_map.coord2lat(_map.lat2coord(_map.centre_lat)-this.y);
			offset_lon=_map.centre_lon-_map.coord2lon(_map.lon2coord(_map.centre_lon)-this.x);
			update();
		}

		
		// ------------------------------------------------------------------
		// Co-ordinate conversion functions

		private function lon2tile(lon:Number):int {
			return (Math.floor((lon+180)/360*Math.pow(2,_map.scale)));
		}
		private function lat2tile(lat:Number):int { 
			return (Math.floor((1-Math.log(Math.tan(lat*Math.PI/180) + 1/Math.cos(lat*Math.PI/180))/Math.PI)/2 *Math.pow(2,_map.scale)));
		}
		private function tile2lon(t:int):Number {
			return (t/Math.pow(2,_map.scale)*360-180);
		}
		private function tile2lat(t:int):Number { 
			var n:Number=Math.PI-2*Math.PI*t/Math.pow(2,_map.scale);
			return (180/Math.PI*Math.atan(0.5*(Math.exp(n)-Math.exp(-n))));
		}

		// ------------------------------------------------------------------
		// Attribution/terms management
		// (moved from Imagery.as)

		private var _selected:Object={};
		public function get selected():Object { return _selected; }

		public function setAttribution():void {
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
		public function positionAttribution():void {
			if (!_selected.attribution) return;
			var tf:TextField=TextField(_overlay.getChildAt(0));
			tf.x=_map.mapwidth  - 5 - tf.textWidth;
			tf.y=_map.mapheight - 5 - tf.textHeight;
		}

		public function setLogo():void {
			while (_overlay.numChildren>2) { _overlay.removeChildAt(2); }
			if (!_selected.logoData) return;
			var logo:Sprite=new Sprite();
			logo.addChild(new Bitmap(_selected.logoData));
			if (_selected.attribution.url) { logo.buttonMode=true; logo.addEventListener(MouseEvent.CLICK, launchLogoLink, false, 0, true); }
			_overlay.addChild(logo);
			positionLogo();
		}
		public function positionLogo():void {
			if (_overlay.numChildren<3) return;
			_overlay.getChildAt(2).x=5;
			_overlay.getChildAt(2).y=_map.mapheight - 5 - _selected.logoHeight - (_selected.terms_url ? 10 : 0);
		}
		private function launchLogoLink(e:Event):void {
			if (!_selected.attribution.url) return;
			navigateToURL(new URLRequest(_selected.attribution.url), '_blank');
		}
		public function setTerms():void {
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

		public function resizeHandler(event:MapEvent):void {
			positionLogo();
			positionTerms();
			positionAttribution();
		}
		private function moveHandler(event:MapEvent):void {
			setAttribution();
			// strictly speaking we should review the collection on every move, but slow
			// dispatchEvent(new Event("collection_changed"));
		}

		// Create overlay sprite
		public static function overlaySprite():Sprite {
			var overlay:Sprite=new Sprite();
			var attribution:TextField=new TextField();
			attribution.width=220; attribution.height=300;
			attribution.multiline=true;
			attribution.wordWrap=true;
			attribution.selectable=false;
			attribution.defaultTextFormat=new TextFormat("_sans", 9, 0, false, false, false);
			overlay.addChild(attribution);
			var terms:TextField=new TextField();
			terms.width=200; terms.height=15;
			terms.selectable=false;
			terms.defaultTextFormat=new TextFormat("_sans", 9, 0, false, false, true);
			overlay.addChild(terms);
			return overlay;
		}

		// ------------------------------------------------------------------
		// Choose a new background
		// (moved from setBackground in Imagery.as)
		
		public function setBackgroundFromImagery(bg:Object,remember:Boolean):void {
			// set background
			_selected=bg;
//			dispatchEvent(new CollectionEvent(CollectionEvent.SELECT, bg));
			_map.tileset.init(bg, bg!='');
			// update attribution and logo
			_overlay.visible=bg.hasOwnProperty('attribution');
			setLogo(); setAttribution(); setTerms();
			// save as SharedObject for next time
			if (remember) {
				var obj:SharedObject = SharedObject.getLocal("user_state","/");
				obj.setProperty('background_url' ,String(bg.url));
				obj.setProperty('background_name',String(bg.name));
				try { obj.flush(); } catch (e:Error) {}
			}
		}

	}
}
