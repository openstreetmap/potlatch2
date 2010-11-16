package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.connection.Marker;
    import flash.net.*;
    import flash.events.*;
    import com.adobe.serialization.json.JSON;

    public class BugLoader {

        private var map:Map;
        private var bugBaseURL:String;
        private var bugApiKey:String;
        private var _layer:VectorLayer;
        private static const STYLESHEET:String="bugs.css";

        public function BugLoader(map:Map, url:String, bugApiKey:String):void {
            this.map = map;
            this.bugBaseURL = url;
            this.bugApiKey = bugApiKey;
        }

        public function load():void {
            var loader:URLLoader = new URLLoader();
            loader.load(new URLRequest(bugBaseURL+"getBugs.json?bbox="+map.edge_l+","+map.edge_b+","+map.edge_r+","+map.edge_t+"&key="+bugApiKey));
            loader.addEventListener(Event.COMPLETE, parseJSON);
        }

        public function parseJSON(event:Event):void {
            trace("parseJSON");
            var result:String = String(event.target.data);
            var featureCollection:Object = JSON.decode(result);
            trace(featureCollection);
            trace(featureCollection.type);
            trace(featureCollection.features[0].type);
            trace(featureCollection.features.length);
            for each (var feature:Object in featureCollection.features) {
              // geoJSON spec is x,y,z i.e. lon, lat, ele
              var lon:Number = feature.geometry.coordinates[0];
              var lat:Number = feature.geometry.coordinates[1];
              trace(lat, lon);
              var marker:Marker = layer.createMarker({"name":feature.properties.description,"bug_id":feature.id}, lat, lon);
              //layer.registerPOI(node);
            }
            layer.paint.updateEntityUIs(layer.getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), false, false);
            //var json:Array =
        }

        private function get layer():VectorLayer {
            if (!_layer) {
                var n:String='Bugs';
                _layer=new VectorLayer(n,map,STYLESHEET);
                map.addVectorLayer(_layer);
            }
            return _layer;
        }
    }
}