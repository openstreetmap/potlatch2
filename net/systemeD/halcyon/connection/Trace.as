package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    import flash.events.*;
    import flash.net.URLLoader;

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.Globals;
    import net.systemeD.halcyon.VectorLayer;

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

        public function get traceData():XML {
            return XML(_traceData);
        }

        private function fetchFromServer():void {
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
            if (!_isLoaded) {
              addEventListener("loaded_data", processEvent);
              fetchFromServer();
              return;
            } else {
              process();
            }
        }

        private function processEvent(e:Event):void {
            process();
        }

        private function process():void {
            var xmlnsPattern:RegExp = new RegExp("xmlns[^\"]*\"[^\"]*\"", "gi");
            var xsiPattern:RegExp = new RegExp("xsi[^\"]*\"[^\"]*\"", "gi");
            var raw:String = _traceData.replace(xmlnsPattern, "").replace(xsiPattern, "");
            var file:XML=new XML(raw);

            for each (var trk:XML in file.child("trk")) {
                for each (var trkseg:XML in trk.child("trkseg")) {
                    trace("trkseg");
                    var way:Way;
                    var nodestring:Array=[];
                    for each (var trkpt:XML in trkseg.child("trkpt")) {
                        nodestring.push(layer.createNode({}, trkpt.@lat, trkpt.@lon));
                    }
                    if (nodestring.length>0) {
                        way=layer.createWay({}, nodestring);
                        //if (simplify) { Simplify.simplify(way, paint.map, false); }
                    }
                }
            }
            for each (var wpt:XML in file.child("wpt")) {
                var tags:Object={};
                for each (var tag:XML in wpt.children()) {
                    tags[tag.name()]=tag.toString();
                }
                layer.createNode(tags, wpt.@lat, wpt.@lon);
            }
            layer.paint.redraw();
        }
    }
}