package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.VectorLayer;
	import flash.net.*;
	import flash.events.*;

	/* still to do:
	- empty layer on reload
	- cope with tracks with timestamps */

	public class TrackLoader {

		private var left:Number=0;
		private var right:Number=0;
		private var top:Number=0;
		private var bottom:Number=0;
		private var page:uint=0;
		private var _layer:VectorLayer;

		private var map:Map;
		private var apiBaseURL:String;

		private static const STYLESHEET:String="gpx.css";
		
		public function TrackLoader(map:Map, url:String) {
			this.map=map;
			apiBaseURL=url;
		}
		
		public function load(keep:Boolean=false):void {
			if (map.edge_l==left && map.edge_r==right && map.edge_t==top && map.edge_b==bottom) {
				page++;
			} else {
				left  =map.edge_l;
				right =map.edge_r;
				top   =map.edge_t;
				bottom=map.edge_b;
				page=0;
				if (!keep) { } // ** TODO: blank the vector layer
			}

			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest(apiBaseURL+"trackpoints?bbox="+left+","+bottom+","+right+","+top+"&page="+page));
			loader.addEventListener(Event.COMPLETE, parseGPX);
		}

		public function parseGPX(event:Event):void {
			var xmlnsPattern:RegExp = new RegExp("xmlns[^\"]*\"[^\"]*\"", "gi");
			var xsiPattern:RegExp = new RegExp("xsi[^\"]*\"[^\"]*\"", "gi");
			var raw:String = String(event.target.data).replace(xmlnsPattern, "").replace(xsiPattern, "");
			var file:XML=new XML(raw);

			for each (var trk:XML in file.child("trk")) {
				for each (var trkseg:XML in trk.child("trkseg")) {
					var nodestring:Array=[];
					var lat:Number=NaN, lastlat:Number=NaN;
					var lon:Number=NaN, lastlon:Number=NaN;
					for each (var trkpt:XML in trkseg.child("trkpt")) {
						lat=trkpt.@lat;
						lon=trkpt.@lon;
						if (lastlat && nodestring.length>0 && greatCircle(lat,lon,lastlat,lastlon)>30) {
							layer.createWay({}, nodestring);
							nodestring=[];
						}
						nodestring.push(layer.createNode({}, lat, lon));
						lastlat=lat; lastlon=lon;
					}
					if (nodestring.length>0) { layer.createWay({}, nodestring); }
				}
			}
			layer.paint.updateEntityUIs(layer.getObjectsByBbox(left,right,top,bottom), false, false);
		}

		
		private function get layer():VectorLayer {
			if (!_layer) {
				var n:String='GPS tracks';
				_layer=new VectorLayer(n,map,STYLESHEET);
				map.addVectorLayer(_layer);
			}
			return _layer;
		}
		
		private function greatCircle(lat1:Number,lon1:Number,lat2:Number,lon2:Number):Number {
			var dlat:Number=(lat2-lat1)*Math.PI/180;
			var dlon:Number=(lon2-lon1)*Math.PI/180;
			var a:Number=Math.pow(Math.sin(dlat / 2),2) + 
			             Math.cos(lat1*Math.PI/180) * 
			             Math.cos(lat2*Math.PI/180) * 
			             Math.pow(Math.sin(dlon / 2),2);
			a=Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
			return a*3958.75*1609;
		}
		
	}
}
