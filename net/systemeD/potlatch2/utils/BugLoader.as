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
        private var _layer:VectorLayer;
        private static const STYLESHEET:String="bugs.css";


        public function BugLoader(map:Map, url:String, bugApiKey:String):void {
            this.map = map;
            this.bugBaseURL = url;
            this.bugApiKey = bugApiKey;
        }

        public function load():void {
            layer.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }


        private function get layer():VectorLayer {
            if (!_layer) {
                var n:String='Bugs';

                var policyFile:String = bugBaseURL+"crossdomain.xml";
                Security.loadPolicyFile(policyFile);

                _layer=new BugLayer(n,map,STYLESHEET,bugBaseURL,bugApiKey);
                map.addVectorLayer(_layer);
            }
            return _layer;
        }
    }
}