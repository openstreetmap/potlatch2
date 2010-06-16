package net.systemeD.potlatch2 {

	import flash.display.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapEvent;
	import com.yahoo.maps.api.YahooMap;
	import com.yahoo.maps.api.YahooMapEvent;
	import com.yahoo.maps.api.core.location.LatLon;
	
    public class Yahoo extends YahooMap {

		private var map:Map;
		private static const token:String="f0a.sejV34HnhgIbNSmVHmndXFpijgGeun0fSIMG9428hW_ifF3pYKwbV6r9iaXojl1lU_dakekR";
		private static const MAXZOOM:int=17;

		private var _lat:Number;
		private var _lon:Number;
		private var _scale:Number;
		private var offset_lat:Number=0;
		private var offset_lon:Number=0;
		private var inited:Boolean;

		public function Yahoo(w:Number, h:Number, map:Map) {
			super();
			this.init(token, w, h);  
			this.mapType="satellite";
			this.alpha=0.5;
			this.map=map;
			this.inited=false;
			this.addEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
		}
		
		public function show():void {
			this.visible=true;
			if (inited) { moveto(map.centre_lat, map.centre_lon, map.scale); }

			map.addEventListener(MapEvent.MOVE, moveHandler);
			map.addEventListener(MapEvent.RESIZE, resizeHandler);
			map.addEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}

		public function hide():void {
			this.visible=false;

			map.removeEventListener(MapEvent.MOVE, moveHandler);
			map.removeEventListener(MapEvent.RESIZE, resizeHandler);
			map.removeEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}
		
		private function initHandler(event:YahooMapEvent):void {
			inited=true;
			if (map.centre_lat) { moveto(map.centre_lat, map.centre_lon, map.scale); }
			this.removeEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
		}

		private function moveHandler(event:MapEvent):void {
			if (!inited) { return; }
			moveto(event.params.lat, event.params.lon, event.params.scale);
		}

		private function moveto(lat:Number,lon:Number,scale:uint):void {
			if (scale>MAXZOOM) { this.visible=false; return; }
			_lat=lat; _lon=lon; _scale=scale;
			
			this.visible=true;
			this.zoomLevel=18-scale;
			this.centerLatLon=new LatLon(lat+offset_lat, lon+offset_lon);
		}

		private function resizeHandler(event:MapEvent):void {
			this.setSize(event.params.width, event.params.height);
		}
		
		private function nudgeHandler(event:MapEvent):void {
			var cx:Number=map.lon2coord(map.centre_lon);
			var cy:Number=map.lat2coord(map.centre_lat);
			offset_lon+=map.coord2lon(cx-event.params.x)-map.centre_lon;
			offset_lat+=map.coord2lat(cy-event.params.y)-map.centre_lat;
			moveto(_lat,_lon,_scale);
		}
	}
}
