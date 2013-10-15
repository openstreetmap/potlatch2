package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.net.*;
	import flash.system.LoaderContext;
	import flash.utils.Timer;

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
		private var scheme:String;			// 900913 or microsoft
		public var blocks:Array;			// array of regexes which are verboten

		private var count:Number=0;			// counter incremented to provide a/b/c/d tile swapping
		private static const ROUNDROBIN:RegExp =/\$\{([^}]+)\}/;

		private var map:Map;
		private const MAXTILESLOADED:uint=30;

		private var sharpenFilter:BitmapFilter = new ConvolutionFilter(3, 3, 
			[0, -1, 0,
            -1, 5, -1,
             0, -1, 0], 0);
		private var sharpening:Boolean = false;
		// http://flylib.com/books/en/2.701.1.170/1/

        public function TileSet(map:Map) {
			this.map=map;
			createSprites();
			map.addEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}
	
		/** @param params Currently includes "url" and "scheme"
		 * @param update Trigger update now?
		 * @param dim Start with imagery faded?
		 * @param sharpen Start with sharpen filter applied?
		 */
		public function init(params:Object, update:Boolean=false):void {
			baseurl=params.url;
			scheme =params.scheme ? params.scheme : '900913';
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
			for (var i:uint=map.MINSCALE; i<=map.MAXSCALE; i++) {
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
			for (var i:uint=map.MINSCALE; i<=map.MAXSCALE; i++) {
				this.getChildAt(i-map.MINSCALE).visible=(scale==i);
			}
			x=map.lon2coord(map.centre_lon+offset_lon)-map.lon2coord(map.centre_lon);
			y=map.lat2coord(map.centre_lat+offset_lat)-map.lat2coord(map.centre_lat);
		}
			
		/** Update bounds of tile area, and request new tiles if needed.  */
		
		public function update():void {
			if (!baseurl) { return; }
			tile_l=lon2tile(map.edge_l-offset_lon);
			tile_r=lon2tile(map.edge_r-offset_lon);
			tile_t=lat2tile(map.edge_t-offset_lat);
			tile_b=lat2tile(map.edge_b-offset_lat);
			for (var tx:int=tile_l; tx<=tile_r; tx++) {
				for (var ty:int=tile_t; ty<=tile_b; ty++) {
					if (!tiles[map.scale+','+tx+','+ty]) { 
						var loader:Loader = new Loader();
						tiles[map.scale+','+tx+','+ty]=loader;
						loader.contentLoaderInfo.addEventListener(Event.INIT, doImgInit, false, 0, true);
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, missingTileError, false, 0, true);
						loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(e:HTTPStatusEvent):void { tileLoadStatus(e,map.scale,tx,ty); }, false, 0, true);
						loader.load(new URLRequest(tileURL(tx,ty,map.scale)), 
						            new LoaderContext(true));
						Sprite(this.getChildAt(map.scale-map.MINSCALE)).addChild(loader);
						loader.x=map.lon2coord(tile2lon(tx));
						loader.y=map.lat2coord(tile2lat(ty));
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
					if (tz!=map.scale || tx<tile_l || tx>tile_r || ty<tile_t || ty<tile_b) {
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

				case 'microsoft':
					var u:String='';
					for (var zoom:uint=tz; zoom>0; zoom--) {
						var byte:uint=0;
						var mask:uint=1<<(zoom-1);
						if ((tx & mask)!=0) byte++;
						if ((ty & mask)!=0) byte+=2;
						u+=String(byte);
					}
					t=baseurl.replace('$quadkey',u); break;

				case 'tms':
					t=baseurl.replace('$z',map.scale).replace('$x',tx).replace('$y',tmsy);
					break;

				default:
					if (baseurl.indexOf('$x')>-1) {
						t=baseurl.replace('$z',map.scale).replace('$x',tx).replace('$y',ty).replace('$-y',tmsy);
					} else {
						t=baseurl.replace('!',map.scale).replace('!',tx).replace('!',ty);
					}
					break;

			}
			var o:Object=new Object();
			if ((o=ROUNDROBIN.exec(t))) {
				var prefixes:Array=o[1].split('|');
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
			offset_lat=map.centre_lat-map.coord2lat(map.lat2coord(map.centre_lat)-this.y);
			offset_lon=map.centre_lon-map.coord2lon(map.lon2coord(map.centre_lon)-this.x);
			update();
		}

		
		// ------------------------------------------------------------------
		// Co-ordinate conversion functions

		private function lon2tile(lon:Number):int {
			return (Math.floor((lon+180)/360*Math.pow(2,map.scale)));
		}
		private function lat2tile(lat:Number):int { 
			return (Math.floor((1-Math.log(Math.tan(lat*Math.PI/180) + 1/Math.cos(lat*Math.PI/180))/Math.PI)/2 *Math.pow(2,map.scale)));
		}
		private function tile2lon(t:int):Number {
			return (t/Math.pow(2,map.scale)*360-180);
		}
		private function tile2lat(t:int):Number { 
			var n:Number=Math.PI-2*Math.PI*t/Math.pow(2,map.scale);
			return (180/Math.PI*Math.atan(0.5*(Math.exp(n)-Math.exp(-n))));
		}

	}
}
