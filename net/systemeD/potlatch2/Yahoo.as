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

		public function Yahoo(w:Number, h:Number, map:Map) {
			super();
			this.init(token, w, h);  
			this.mapType="satellite";
			this.alpha=0.5;
			this.map=map;
		}
		
		public function show():void {
			this.visible=true;
			this.zoomLevel = 18-map.scale;
			this.centerLatLon = new LatLon(map.centre_lat, map.centre_lon);

			this.addEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
			map.addEventListener(MapEvent.MOVE, moveHandler);
			map.addEventListener(MapEvent.RESIZE, resizeHandler);
		}

		public function hide():void {
			this.visible=false;

			this.removeEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
			map.removeEventListener(MapEvent.MOVE, moveHandler);
			map.removeEventListener(MapEvent.RESIZE, resizeHandler);
		}
		
		private function initHandler(event:YahooMapEvent):void {
			moveto(map.centre_lat, map.centre_lon, map.scale);
		}

		private function moveHandler(event:MapEvent):void {
			moveto(event.params.lat, event.params.lon, event.params.scale);
		}

		private function moveto(lat:Number,lon:Number,scale:uint):void {
			if (scale>MAXZOOM) { this.visible=false; return; }
			this.visible=true;
			this.zoomLevel=18-scale;
			this.centerLatLon=new LatLon(lat, lon);
		}

		private function resizeHandler(event:MapEvent):void {
			this.setSize(event.params.width, event.params.height);
		}
	}
}