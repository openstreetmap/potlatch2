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

            for each (var trkseg:XML in file..trkseg) {
                var way:Way;
                var nodestring:Array = [];
                for each (var trkpt:XML in trkseg.trkpt) {
                    nodestring.push(connection.createNode({}, trkpt.@lat, trkpt.@lon, action.push));
                }
                if (nodestring.length > 0) {
                    way = connection.createWay({}, nodestring, action.push);
                    //if (simplify) { Simplify.simplify(way, paint.map, false); }
                }
            }

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
    }
}
