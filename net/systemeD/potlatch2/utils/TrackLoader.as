package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
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

		private var map:Map;
		private var apiBaseURL:String;
		private var connection:Connection; /* to store the nodes/ways that are faked up for GPX tracks */

		private static const STYLESHEET:String="stylesheets/gpx.css";
		private static const LAYER:String="GPS tracks";
		
		public function TrackLoader(map:Map, url:String) {
			this.map=map;
			apiBaseURL=url;
			connection = new Connection(LAYER,apiBaseURL,null, null);
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
				if (!keep) { } // ** TODO: blank the connection objects
			}

            /* This isn't great - conceptially it would be nicer for the connection to do the request */
			var loader:URLLoader = new URLLoader();
			loader.load(new URLRequest(apiBaseURL+"trackpoints?bbox="+left+","+bottom+","+right+","+top+"&page="+page));
			loader.addEventListener(Event.COMPLETE, parseGPX);
		}

		public function parseGPX(event:Event):void {
			var file:XML = new XML(event.target.data);
			var action:CompositeUndoableAction = new CompositeUndoableAction("add track objects");
			for each (var ns:Namespace in file.namespaceDeclarations()) {
				if (ns.uri.match(/^http:\/\/www\.topografix\.com\/GPX\/1\/[01]$/)) {
					default xml namespace = ns;
				}
			}

			for each (var trkseg:XML in file..trkseg) {
				var nodestring:Array = [];
				var lat:Number = NaN, lastlat:Number = NaN;
				var lon:Number = NaN, lastlon:Number = NaN;
                for each (var trkpt:XML in trkseg.trkpt) {
					lat = trkpt.@lat;
                    lon = trkpt.@lon;
                    if (lastlat && nodestring.length > 0 && greatCircle(lat, lon, lastlat, lastlon) > 30) {
                        connection.createWay({}, nodestring, action.push);
                        nodestring = [];
                    }
                    nodestring.push(connection.createNode({}, lat, lon, action.push));
                    lastlat = lat; lastlon = lon;
				}
                if (nodestring.length > 0) { connection.createWay({}, nodestring, action.push); trace("create way");}
			}

            action.doAction(); /* just do it, don't add to undo stack */
			default xml namespace = new Namespace("");
			layer.updateEntityUIs(false, false);
		}

		private function get layer():MapPaint {
            var mp:MapPaint = map.findLayer(LAYER);
            if (!mp) {
                mp = map.addLayer(connection, STYLESHEET);
            }
            return mp;
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
