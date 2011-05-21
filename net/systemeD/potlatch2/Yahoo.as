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

		private static const UNINITIALISED:uint=0;
		private static const INITIALISING:uint=1;
		private static const HIDDEN:uint=2;
		private static const SHOWING:uint=3;
		private var currentState:uint=UNINITIALISED;

		private var _lat:Number;
		private var _lon:Number;
		private var _scale:Number;
		private var offset_lat:Number=0;
		private var offset_lon:Number=0;

		public function Yahoo(map:Map) {
			super();
			currentState=UNINITIALISED;
			this.map=map;
			visible=false;
		}
		
		public function show():void {
			visible=true;
			if (currentState==UNINITIALISED) {
				currentState=INITIALISING;
				this.addEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
				this.init(token, map.mapwidth, map.mapheight);
				this.mapType="satellite";
				this.alpha=0.5;				// ** FIXME - should take the value the user has chosen
				activateListeners();
			} else if (currentState==HIDDEN) { 
				currentState=SHOWING;
				moveto(map.centre_lat, map.centre_lon, map.scale);
				this.setSize(map.mapwidth,map.mapheight);
				activateListeners();
			}
		}

		public function hide():void {
			deactivateListeners();
			visible=false;
			if (currentState==SHOWING) currentState=HIDDEN;
		}

		private function activateListeners():void {
			map.addEventListener(MapEvent.MOVE, moveHandler);
			map.addEventListener(MapEvent.RESIZE, resizeHandler);
			map.addEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}
		
		private function deactivateListeners():void {
			map.removeEventListener(MapEvent.MOVE, moveHandler);
			map.removeEventListener(MapEvent.RESIZE, resizeHandler);
			map.removeEventListener(MapEvent.NUDGE_BACKGROUND, nudgeHandler);
		}
		
		private function initHandler(event:YahooMapEvent):void {
			currentState=visible ? SHOWING : HIDDEN;
			if (map.centre_lat) { moveto(map.centre_lat, map.centre_lon, map.scale); }
			this.removeEventListener(YahooMapEvent.MAP_INITIALIZE, initHandler);
		}

		private function moveHandler(event:MapEvent):void {
			if (currentState!=SHOWING) { return; }
			moveto(event.params.lat, event.params.lon, event.params.scale);
		}

		private function moveto(lat:Number,lon:Number,scale:uint):void {
			if (scale>MAXZOOM) { visible=false; return; }
			_lat=lat; _lon=lon; _scale=scale;
			
			visible=true;
			this.zoomLevel=18-scale;
			this.centerLatLon=new LatLon(lat+offset_lat, lon+offset_lon);
		}
		
		private function resizeHandler(event:MapEvent):void {
			moveto(map.centre_lat, map.centre_lon, map.scale);
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
