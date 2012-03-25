package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    import flash.events.*;
    import flash.net.URLLoader;

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.Globals;
    import net.systemeD.halcyon.MapPaint;

    /**
    * Implements trace objects loaded from the OSM API.
    * See also potlatch2's utils GpxImporter.as and Importer.as classes, which can handle
    * loading GPX files (and other formats) from arbitrary urls.
    */
    public class Trace extends EventDispatcher {
        private var _id:Number; // id of the trace, as reported by the server
        private var _description:String; // description, as reported by the server
        private var tags:Array = []; // N.B. trace tags are NOT k/v pairs
        private var _isLoaded:Boolean; // Flag for when the data has been downloaded and parsed
        private var _filename:String; // The original name of the file, as reported by the server
        private var _traceData:String; // the trace data, saved as a string
        private var map:Map;
        private var _layer:MapPaint;
        private var masterConnection:Connection; // The authenticated connection
        private var _connection:Connection; // The one we store our fake nodes/ways in.
        private var simplify:Boolean = false;

        private static const STYLESHEET:String="stylesheets/gpx.css";

        /** Create a new trace.
        * @param masterConnection The authenticated connection to communicate with the server
        */
        public function Trace(masterConnection:Connection, id:int=0) {
            this.masterConnection = masterConnection;
            map = Globals.vars.root; // REFACTOR this prevents traces being added to arbitrary maps
			if (id!=0) _id=id;
        }

        /** Create a new trace, from the XML description given by the user/traces call.
        * This only creates the object itself, the actual trace contents (trkseg etc) are
        * lazily downloaded later. */
        public function fromXML(xml:XML):Trace {
            _id = Number(xml.@id);
            _filename = xml.@name;
            _description = xml.description;
            tags = [];
            for each(var tag:XML in xml.tag) {
              tags.push(String(tag));
            }
            return this;
        }

        public function get id():Number {
            return _id;
        }

        public function get description():String {
            return _description;
        }

        public function get filename():String {
            return _filename;
        }

        public function get tagsText():String {
            return tags.join(", ");
        }

        private function fetchFromServer():void {
            // todo - needs proper error handling
            masterConnection.fetchTrace(id, saveTraceData);
            dispatchEvent(new Event("loading_data"));
        }

        private function saveTraceData(event:Event):void {
            _traceData = String(URLLoader(event.target).data);
            dispatchEvent(new Event("loaded_data"));
        }

        private function get connection():Connection {
            if (!_connection) {
                // create a new connection so that the ids don't impact the main layer.
                _connection = new Connection(filename, null, null, null);
            }
            return _connection
        }

        private function get layer():MapPaint {
            if (!_layer) {
                // create a new layer for every trace, so they can be turned on/off individually
                _layer = map.addLayer(connection, STYLESHEET);
            }
            return _layer;
        }

        public function addToMap():void {
            // this allows adding and removing traces from the map, without re-downloading
            // the data from the server repeatedly.
            if (!_isLoaded) {
              addEventListener("loaded_data", processEvent);
              fetchFromServer();
              return;
            } else {
              process();
            }
        }

        public function removeFromMap():void {
            //todo
        }

        private function processEvent(e:Event):void {
            removeEventListener("loaded_data", processEvent);
            _isLoaded=true;
            process();
        }

        private function process():void {
            var file:XML = new XML(_traceData);
            var action:CompositeUndoableAction = new CompositeUndoableAction("add trace objects");
			for each (var ns:Namespace in file.namespaceDeclarations()) {
				if (ns.uri.match(/^http:\/\/www\.topografix\.com\/GPX\/1\/[01]$/)) {
					default xml namespace = ns;
				}
			}

			Trace.parseTrkSegs(file,connection,action,false);
			
            for each (var wpt:XML in file.wpt) {
                var tags:Object = {};
                for each (var tag:XML in wpt.children()) {
                    tags[tag.name().localName]=tag.toString().substr(0,255);
                }
                var node:Node = connection.createNode(tags, wpt.@lat, wpt.@lon, action.push);
				connection.registerPOI(node);
            }

            action.doAction(); /* just do it, don't add to undo stack */
			default xml namespace = new Namespace("");
            layer.updateEntityUIs(true, false);
        }

		/* Draw ways from <trkseg>s, with elementary filter to remove points within 3 metres of each other. 
		   Optionally split way if more than 50m from previous point.
		   FIXME: do auto-joining of dupes as per Importer. */

		public static function parseTrkSegs(file:XML, connection:Connection, action:CompositeUndoableAction, smartSplitting:Boolean=false):void {
			for each (var ns:Namespace in file.namespaceDeclarations()) {
				if (ns.uri.match(/^http:\/\/www\.topografix\.com\/GPX\/1\/[01]$/)) { default xml namespace = ns; }
			}
			for each (var trkseg:XML in file..trkseg) {
				var nodestring:Array = [];
				var lat:Number = NaN, lastlat:Number = NaN;
				var lon:Number = NaN, lastlon:Number = NaN;
				var dist:Number=0;
				for each (var trkpt:XML in trkseg.trkpt) {
					lat = trkpt.@lat;
					lon = trkpt.@lon;
					if (isNaN(lastlat)) { lastlat = lat; lastlon = lon; }
					dist=Trace.greatCircle(lat, lon, lastlat, lastlon);
					if (dist>3) {
						if ((dist>50 && smartSplitting) || nodestring.length>500) {
							if (dist<=50 || !smartSplitting) nodestring.push(connection.createNode({}, lat, lon, action.push));
							if (nodestring.length>1) connection.createWay({}, nodestring, action.push);
							nodestring=[];
						}
						nodestring.push(connection.createNode({}, lat, lon, action.push));
						lastlat=lat; lastlon=lon;
					}
				}
				if (nodestring.length > 1) { connection.createWay({}, nodestring, action.push); }
			}
		}
		
		public static function greatCircle(lat1:Number,lon1:Number,lat2:Number,lon2:Number):Number {
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
