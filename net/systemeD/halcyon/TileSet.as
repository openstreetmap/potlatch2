package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.LoaderContext;
	import flash.utils.Timer;
	import net.systemeD.halcyon.MapEvent;

    public class TileSet extends Sprite {

		public var tile_l:int;
		public var tile_r:int;
		public var tile_b:int;
		public var tile_t:int;

		private var offset_lon:Number=0;
		private var offset_lat:Number=0;

		private var requests:Array=[];
		private var tiles:Object={};		// key is "z,x,y"; value "true" (needed) or reference to sprite
		private var waiting:int=0;			// number of tiles currently being downloaded
		private var baseurl:String;			// e.g. http://npe.openstreetmap.org/$z/$x/$y.png

		private var map:Map;


        public function TileSet(map:Map) {
			this.map=map;
			alpha=0.5;
			createSprites();
			map.addEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}
	
		public function init(url:String=null, update:Boolean=false):void {
			baseurl=url;
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

		public function setDimming(dim:Boolean):void {
			alpha=dim ? 0.5 : 1;
		}

		public function changeScale(scale:uint):void {
			for (var i:uint=map.MINSCALE; i<=map.MAXSCALE; i++) {
				this.getChildAt(i-map.MINSCALE).visible=(scale==i);
			}
			x=map.lon2coord(map.centre_lon+offset_lon)-map.lon2coord(map.centre_lon);
			y=map.lat2coord(map.centre_lat+offset_lat)-map.lat2coord(map.centre_lat);
		}
			
		// Update bounds - called on every move
		
		public function update():void {
			if (!baseurl) { return; }
			tile_l=lon2tile(map.edge_l-offset_lon);
			tile_r=lon2tile(map.edge_r-offset_lon);
			tile_t=lat2tile(map.edge_t-offset_lat);
			tile_b=lat2tile(map.edge_b-offset_lat);
			for (var tx:int=tile_l; tx<=tile_r; tx++) {
				for (var ty:int=tile_t; ty<=tile_b; ty++) {
					if (!tiles[map.scale+','+tx+','+ty]) { addRequest(tx,ty); }
				}
			}
		}

		// Mark that a tile needs to be loaded
		
		public function addRequest(tx:int,ty:int):void {
			tiles[map.scale+','+tx+','+ty]=true;
			requests.push([map.scale,tx,ty]);
		}

		// Service tile queue - called on every frame to download new tiles
		
		public function serviceQueue():void {
			if (waiting==4 || requests.length==0) { return; }
			var r:Array, tx:int, ty:int, tz:int, l:DisplayObject;

			for (var i:uint=0; i<Math.min(requests.length, 4-waiting); i++) {
				r=requests.shift(); tz=r[0]; tx=r[1]; ty=r[2];
				if (tx>=tile_l && tx<=tile_r && ty>=tile_t && ty<=tile_b) {
					// Tile is on-screen, so load
					waiting++;
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.INIT, doImgInit);
            		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, missingTileError);
					loader.load(new URLRequest(tileURL(tx,ty)), 
					            new LoaderContext(true));
					l=this.getChildAt(map.scale-map.MINSCALE);
					Sprite(l).addChild(loader);
					loader.x=map.lon2coord(tile2lon(tx));
					loader.y=map.lat2coord(tile2lat(ty));
//					loader.alpha=0.5;
				}
			}
		}

        private function missingTileError(event:Event):void {
			waiting--;
			return;
		}

		protected function doImgInit(event:Event):void {
			event.target.loader.alpha=0;
			var t:Timer=new Timer(10,10);
			t.addEventListener(TimerEvent.TIMER,function():void { upFade(DisplayObject(event.target.loader)); });
			t.start();
			waiting--;
			return;
		}
		
		protected function upFade(s:DisplayObject):void {
			s.alpha+=0.1;
		}

		
		// Assemble tile URL
		
		private function tileURL(tx:int,ty:int):String {
			return baseurl.replace('$z',map.scale).replace('$x',tx).replace('$y',ty);
		}
		
		public function get url():String {
			return baseurl ? baseurl : '';
		}


		// Update offset
		
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
