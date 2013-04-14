package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import flash.net.*;
    import flash.events.*;

    /* still to do:
    - empty layer on reload
    - cope with tracks with timestamps */

    /** A TrackLoader will load the public GPX traces for the current map bounding box into a separate layer */
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

        /** Create a new TrackLoader
        *   @param map The map object you want to the GPS tracks layer to be added to
        *   @param url The url of the server api base
        */
        public function TrackLoader(map:Map, url:String) {
            this.map=map;
            apiBaseURL=url;
            connection = new Connection(LAYER,apiBaseURL,null, null);
        }

        /** Load the public traces for the current map extent
        *   @param keep not implemented
        */
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

        /* Load GPX data and add it to the connection as nodes/ways. */

        private function parseGPX(event:Event):void {
            var file:XML = new XML(event.target.data);
            var action:CompositeUndoableAction = new CompositeUndoableAction("add track objects");
            Trace.parseTrkSegs(file,connection,action,true);
            action.doAction(); /* just do it, don't add to undo stack */
            layer.updateEntityUIs(false, false);
        }

        private function get layer():MapPaint {
            var mp:MapPaint = map.findLayer(LAYER);
            if (!mp) {
                mp = map.addLayer(connection, STYLESHEET);
            }
            return mp;
        }
        
    }
}
