package net.systemeD.potlatch2 {

    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
    import flash.net.*;
    import flash.events.*;
    import com.adobe.serialization.json.JSON;

    /** A VectorLayer that can be used to load and display bugs from MapDust-compatible APIs.
        See utils/BugLoader.as for the corresponding loader. */

    public class BugLayer extends VectorLayer {

        private var baseUrl:String;
        private var apiKey:String;
        private var detailsUrl:String;
        /** A comma-separated list of statuses that we wish to fetch. But TBH we only want open ones. */
        private var filter_status:String = BUG_STATUS_OPEN;
        /** A comma-separated list of types of bugs. We don't want ones classed as routing problems, they are likely to be skobbler-app specific. */
        /* Possible values: wrong_turn,bad_routing,oneway_road,blocked_street,missing_street,wrong_roundabout,missing_speedlimit,other */
        private var filter_type:String = "wrong_turn,oneway_road,blocked_street,missing_street,wrong_roundabout,missing_speedlimit,other";
        /** Type of comments. "idd = 0" means no comments with default description, "idd = 1" means only comments with default description.
        * Use empty string (i.e. don't pass any parameter) to indicate all comments. */
        private var commentType:String = "&idd=0";

        // as strings, since that's how they are in tags and http calls
        public static var BUG_STATUS_OPEN:String = "1";
        public static var BUG_STATUS_FIXED:String = "2";
        public static var BUG_STATUS_INVALID:String = "3"; // or 'non-reproduceable'
        public static const status:Array = ["", "open", "fixed", "invalid"];

        public function BugLayer(n:String, map:Map, s:String, baseUrl:String, apiKey:String, detailsURL:String) {
            this.baseUrl = baseUrl;
            this.apiKey = apiKey;
            this.detailsUrl = detailsURL;
            super(n,map,s);
        }

        public function closeBug(m:Marker, nickname:String, comment:String, status:String = null):void {
            var id:String = m.getTag('bug_id');
            nickname ||= 'NoName';
            // nicknames have length and character restictions. The character restrictions should be taken care of
            // by the BugPanel.mxml restriction.
            if (nickname.length < 3 || nickname.length > 16) {
              nickname = 'NoName';
            }
            comment ||= 'No Comment';
            if (comment.length > 1000) {
              comment = comment.substr(0,1000); // that's index, length
            }
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
            loader.load(new URLRequest(baseUrl+"getBugs?bbox="+map.edge_l+","+map.edge_b+","+map.edge_r+","+map.edge_t+"&key="+apiKey+"&filter_status="+filter_status+"&filter_type="+filter_type+commentType));
            loader.addEventListener(Event.COMPLETE, parseJSON);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleError);
            loader.addEventListener(IOErrorEvent.IO_ERROR, handleError);
        }

		private function handleError(event:Event):void {
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
                var marker:Marker = createMarker(tags, lat, lon, Number(feature.id));
              }
              paint.updateEntityUIs(getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), true, false);
            }
        }

        public function bugDetailsUrl(m:Marker):String {
            if (detailsUrl == '')
              return null;
            return detailsUrl+m.id;
        }

    }
}
