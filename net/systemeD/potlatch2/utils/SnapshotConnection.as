package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.*;
    import flash.events.Event;
    import flash.net.*;

    public class SnapshotConnection extends XMLConnection {

        public function SnapshotConnection(cname:String,api:String,policy:String,initparams:Object=null) {
            super(cname,api,policy,initparams);
            inlineStatus = true;
        }

        /** Send a "complete" call to the server, and remove it from the current layer */
        public function markComplete(entity:Entity):void {
            var urlReq:URLRequest;
            var loader:URLLoader = new URLLoader();
            if (entity is Node) {
                var node:Node = Node(entity);
                if (node == getNode(node.id)) { // confirm it's from this connection
                    urlReq = new URLRequest(apiBaseURL+"node/"+node.id+"/status");
                    urlReq.method = "POST";
                    urlReq.data = 'complete';
                    loader.addEventListener(Event.COMPLETE, function(e:Event):void { updateStatus(node, 'complete') });
                    loader.load(urlReq);
                }

            } else if (entity is Way) {
                var way:Way = Way(entity);
                if (way == getWay(way.id)) { // confirm it's from this connection
                    urlReq = new URLRequest(apiBaseURL+"way/"+way.id+"/status");
                    urlReq.method = "POST";
                    urlReq.data = 'complete';
                    loader.addEventListener(Event.COMPLETE, function(e:Event):void { updateStatus(way, 'complete') });
                    loader.load(urlReq);
                }
            }
        }

        private function updateStatus(e:Entity, s:String):void {
            e.setStatus(s);
        }

    }
}