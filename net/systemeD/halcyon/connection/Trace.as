package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    import flash.events.*;
    import flash.net.URLLoader;

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.Globals;
    import net.systemeD.halcyon.VectorLayer;

    /**
    * Implements trace objects loaded from the OSM API.
    * See also potlatch2's utils GpxImporter.as and Importer.as classes, which can handle
    * loading GPX files (and other formats) from arbitrary urls.
    */
    public class Trace extends EventDispatcher {
        private var _id:Number;
        private var _description:String;
        private var tags:Array = []; // N.B. trace tags are NOT k/v pairs
        private var _isLoaded:Boolean;
        private var _filename:String;
        private var _traceData:String;
        private var map:Map;
        private var _layer:VectorLayer;
        private var simplify:Boolean = false;

        private static const STYLESHEET:String="gpx.css";

        public function Trace() {
            map = Globals.vars.root;
        }

        /* Create a new trace, from the XML description given by the user/traces call */
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
            Connection.getConnectionInstance().fetchTrace(id, saveTraceData);
            dispatchEvent(new Event("loading_data"));
        }

        private function saveTraceData(event:Event):void {
            _traceData = String(URLLoader(event.target).data);
            dispatchEvent(new Event("loaded_data"));
        }

        private function get layer():VectorLayer {
            if (!_layer) {
                _layer=new VectorLayer(filename,map,STYLESHEET);
                map.addVectorLayer(_layer);
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
            process();
        }

        private function process():void {
            default xml namespace = new Namespace("http://www.topografix.com/GPX/1/0");
            var file:XML = new XML(_traceData);

            for each (var trkseg:XML in file..trkseg) {
                var way:Way;
                var nodestring:Array = [];
                for each (var trkpt:XML in trkseg.trkpt) {
                    nodestring.push(layer.createNode({}, trkpt.@lat, trkpt.@lon));
                }
                if (nodestring.length > 0) {
                    way = layer.createWay({}, nodestring);
                    //if (simplify) { Simplify.simplify(way, paint.map, false); }
                }
            }

            for each (var wpt:XML in file.wpt) {
                var tags:Object = {};
                for each (var tag:XML in wpt.children()) {
                    tags[tag.name()]=tag.toString();
                }
                var node:Node = layer.createNode(tags, wpt.@lat, wpt.@lon);
				layer.registerPOI(node);
            }

            layer.paint.updateEntityUIs(layer.getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), true, false);
        }
    }
}
