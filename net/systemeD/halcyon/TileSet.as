package net.systemeD.halcyon {

	// ** Need to support different zoom levels
	//    When zoom level changes: 
	//		- double or halve xoffset/yoffset accordingly
	//		- blank the tile queue

	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	
	import net.systemeD.halcyon.ImageURLLoader;
	import net.systemeD.halcyon.Globals;
	import flash.system.LoaderContext;
	
    public class TileSet extends Sprite {

		public var baseurl:String;

		public var tile_l:int;
		public var tile_r:int;
		public var tile_b:int;
		public var tile_t:int;

		public var xoffset:Number=0;
		public var yoffset:Number=0;

		private var requests:Array=[];
		private var tiles:Object={};		// key is "z,x,y"; value "true" (needed) or reference to sprite
		private var waiting:int=0;			// number of tiles currently being downloaded

		private var map:Map;


        public function TileSet(map:Map) {
			this.map=map;
		}
	
		public function init(url:String):void {
		}

		// Update bounds - called on every move
		
		public function update():void {
			tile_l=lon2tile(map.edge_l+xoffset);
			tile_r=lon2tile(map.edge_r+xoffset);
			tile_t=lat2tile(map.edge_t+yoffset);
			tile_b=lat2tile(map.edge_b+yoffset);
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
			var r:Array, tx:int, ty:int, tz:int;

			for (var i:uint=0; i<Math.min(requests.length, 4-waiting); i++) {
				r=requests.shift(); tz=r[0]; tx=r[1]; ty=r[2];
				if (tx>=tile_l && tx<=tile_r && ty>=tile_t && ty<=tile_b) {
					// Tile is on-screen, so load
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.INIT, doImgInit);
					loader.load(new URLRequest(tileURL(tx,ty)), 
					            new LoaderContext(true));
					this.addChild(loader);
					loader.x=map.lon2coord(tile2lon(tx));
					loader.y=map.lat2coord(tile2lat(ty));
					loader.alpha=0.5;
				}
			}
		}

		protected function doImgInit(evt:Event):void {
			waiting--;
			return;
		}

		
		// Assemble tile URL
		
		private function tileURL(tx:int,ty:int):String {
			return "http://npe.openstreetmap.org/"+map.scale+"/"+tx+"/"+ty+".png";
//			return "http://andy.sandbox.cloudmade.com/tiles/cycle/"+map.scale+"/"+tx+"/"+ty+".png";
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
