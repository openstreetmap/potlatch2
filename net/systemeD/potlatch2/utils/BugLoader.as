package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.connection.Marker;
    import net.systemeD.potlatch2.BugLayer;
    import flash.net.*;
    import flash.events.*;
    import flash.system.Security;

    public class BugLoader {

        private var map:Map;
        private var bugBaseURL:String;
        private var bugApiKey:String;
        private var bugDetailsURL:String;
        private var _layer:VectorLayer;
        private var name:String;
        private static const STYLESHEET:String="stylesheets/bugs.css";


        public function BugLoader(map:Map, url:String, bugApiKey:String, name:String, details:String = ''):void {
            this.map = map;
            this.bugBaseURL = url;
            this.bugApiKey = bugApiKey;
            this.name = name;
            this.bugDetailsURL = details;
        }

        public function load():void {
            layer.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }


        private function get layer():VectorLayer {
            if (!_layer) {

                var policyFile:String = bugBaseURL+"crossdomain.xml";
                Security.loadPolicyFile(policyFile);

                _layer=new BugLayer(name,map,STYLESHEET,bugBaseURL,bugApiKey,bugDetailsURL);
                map.addVectorLayer(_layer);
            }
            return _layer;
        }
    }
}