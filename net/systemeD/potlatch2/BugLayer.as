package net.systemeD.potlatch2 {

    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
    import flash.net.*;
    import flash.events.*;
    import com.adobe.serialization.json.JSON;

    public class BugLayer extends VectorLayer {

        private var baseUrl:String;
        private var apiKey:String;

        // as strings, since that's how they are in tags and http calls
        public static var BUG_STATUS_OPEN:String = "1";
        public static var BUG_STATUS_FIXED:String = "2";
        public static var BUG_STATUS_INVALID:String = "3"; // or 'non-reproduceable'
        public static const status:Array = ["", "open", "fixed", "invalid"];

        public function BugLayer(n:String, map:Map, s:String, baseUrl:String, apiKey:String) {
            this.baseUrl = baseUrl;
            this.apiKey = apiKey;
            super(n,map,s);
        }

        public function closeBug(m:Marker, nickname:String = "NoName", comment:String = "No Comment", status:String = null):void {
            var id:String = m.getTag('bug_id');
            status ||= BUG_STATUS_FIXED;
            var urlReq:URLRequest = new URLRequest(baseUrl+"changeBugStatus?id="+id+"&status="+status+"&comment="+encodeURIComponent(comment)+"&nickname="+encodeURIComponent(nickname)+"&key="+apiKey);
            urlReq.method = "POST";
            urlReq.data = '    '; // dear Adobe, this is nuts, kthxbye (you can't POST with an empty payload)
            var loader:URLLoader = new URLLoader();
            loader.load(urlReq);
            loader.addEventListener(Event.COMPLETE, function(e:Event):void { bugClosed(e, m, status); } );
        }

        private function bugClosed(event:Event, marker:Marker, s:String):void {
            var action:UndoableEntityAction = new SetTagAction(marker, "status", status[int(s)]);
            action.doAction(); // just do it, don't add to undo stack
        }

        public override function loadBbox(left:Number, right:Number,
                                top:Number, bottom:Number):void {
            var loader:URLLoader = new URLLoader();
            loader.load(new URLRequest(baseUrl+"getBugs?bbox="+map.edge_l+","+map.edge_b+","+map.edge_r+","+map.edge_t+"&key="+apiKey));
            loader.addEventListener(Event.COMPLETE, parseJSON);
        }

        private function parseJSON(event:Event):void {
            var result:String = String(event.target.data);
            if (result) { // api returns 204 no content for no bugs, and the JSON parser treats '' as an error
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
                var marker:Marker = createMarker(tags, lat, lon);
              }
              paint.updateEntityUIs(getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), true, false);
            }
        }

    }
}
