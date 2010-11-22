package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.connection.Marker;
    import net.systemeD.potlatch2.BugLayer;
    import flash.net.*;
    import flash.events.*;
    import com.adobe.serialization.json.JSON;
    import flash.system.Security;

    public class BugLoader {

        private var map:Map;
        private var bugBaseURL:String;
        private var bugApiKey:String;
        private var _layer:VectorLayer;
        private static const STYLESHEET:String="bugs.css";
        private static const status:Array = ["", "open", "fixed", "invalid"];

        public function BugLoader(map:Map, url:String, bugApiKey:String):void {
            this.map = map;
            this.bugBaseURL = url;
            this.bugApiKey = bugApiKey;
            var policyFile:String = bugBaseURL+"crossdomain.xml";
            Security.loadPolicyFile(policyFile);
        }

        public function load():void {
            var loader:URLLoader = new URLLoader();
            loader.load(new URLRequest(bugBaseURL+"getBugs?bbox="+map.edge_l+","+map.edge_b+","+map.edge_r+","+map.edge_t+"&key="+bugApiKey));
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, balls);
            loader.addEventListener(Event.COMPLETE, parseJSON);
        }

        public function balls(event:SecurityErrorEvent):void {
            trace(event);
        }

        private function parseJSON(event:Event):void {
            var result:String = String(event.target.data);
            var featureCollection:Object = JSON.decode(result);

            for each (var feature:Object in featureCollection.features) {
              // geoJSON spec is x,y,z i.e. lon, lat, ele
              var lon:Number = feature.geometry.coordinates[0];
              var lat:Number = feature.geometry.coordinates[1];
              var tags:Object = {};
              tags["name"] = String(feature.properties.description).substr(0,10)+'...';
              tags["description"] = feature.properties.description;
              tags["bug_id"] = feature.id;
              tags["nickname"] = feature.properties.nickname;
              tags["type"] = feature.properties.type;
              tags["date_created"] = feature.properties.date_created;
              tags["date_updated"] = feature.properties.date_updated;
              tags["source"] = feature.properties.source;
              tags["status"] = status[int(feature.properties.status)];
              var marker:Marker = layer.createMarker(tags, lat, lon);
            }
            layer.paint.updateEntityUIs(layer.getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), true, false);
        }

        private function get layer():VectorLayer {
            if (!_layer) {
                var n:String='Bugs';
                _layer=new BugLayer(n,map,STYLESHEET,bugBaseURL,bugApiKey);
                map.addVectorLayer(_layer);
            }
            return _layer;
        }
    }
}