package net.systemeD.halcyon {

	// ** Need to support different zoom levels
	//    When zoom level changes: 
	//		- double or halve xoffset/yoffset accordingly
	//		- blank the tile queue

	import flash.display.DisplayObjectContainer;
	import flash.display.Bitmap;
	import flash.events.*;
	import flash.net.*;
	
	import net.systemeD.halcyon.ImageLoader;
	import net.systemeD.halcyon.Globals;

    public class TileSet extends DisplayObjectContainer {

		public var baseurl:String;

		public var tile_l:int;
		public var tile_r:int;
		public var tile_b:int;
		public var tile_t:int;

		public var xoffset:Number;
		public var yoffset:Number;

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
			tile_l=lon2tile(map.coord2lon(-xoffset-map.x));
			tile_r=lon2tile(map.coord2lon(-xoffset-map.x+map.mapwidth));
			tile_t=lat2tile(map.coord2lat(-yoffset-map.y));
			tile_b=lat2tile(map.coord2lat(-yoffset-map.y+map.mapheight));

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
			var loader:ImageLoader, urlreq:URLRequest;

			for (var i:uint=0; i<Math.min(requests.length, 4-waiting); i++) {
				r=requests.shift(); tz=r[0]; tx=r[1]; ty=r[2];
				if (tx>=tile_l && tx<=tile_r && ty>=tile_t && ty<=tile_b) {
					// Tile is on-screen, so load
					urlreq=new URLRequest(tileURL(tx,ty));
					loader=new ImageLoader();
					loader.dataFormat=URLLoaderDataFormat.BINARY;
					loader.filename=[tz,tx,ty];
					loader.addEventListener(Event.COMPLETE, 					loadedTile,				false, 0, true);
					loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler,	false, 0, true);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler,			false, 0, true);
					loader.load(urlreq);
				}
			}
		}

		// Tile has loaded, so place on display list

		private function loadedTile(event:Event):void {
			var r:Array=event.target.filename as Array;
			var tz:int=r[0]; var tx:int=r[1]; var ty:int=r[2];
			
			var image:Bitmap = event.target.content as Bitmap;
			addChild(image);
			image.x=map.lon2coord(tile2lon(tx));
			image.y=map.lat2coord(tile2lat(ty));

			waiting--;
		}

		
		// Assemble tile URL
		
		private function tileURL(tx:int,ty:int):String {
			// ***** to do
			return '';
		}

		private function httpStatusHandler( event:HTTPStatusEvent ):void { }
		private function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		private function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }

		
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
