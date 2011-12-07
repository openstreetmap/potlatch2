package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.*;
    import flash.events.Event;
    import flash.net.*;

    /**
    * A connection to a Snapshot server. A Snapshot server serves OSM map requests and can also
    * track the "status" of an entity. Most other types of XMLConnection requests will fail. See
    * http://www.github.com/gravitystorm/snapshot-server for example code based on the database
    * structure created by osmosis pgsnapshot schema.
    */

    public class SnapshotConnection extends XMLConnection {

        public function SnapshotConnection(cname:String,api:String,policy:String,initparams:Object=null) {
            super(cname,api,policy,initparams);
            inlineStatus = true;
        }

        // As it stands, the following two functions could be refactored further.

        /**
        * Post a status update call to the server and update entity.status if successful.
        */
        public function markComplete(entity:Entity):void {
            var urlReq:URLRequest;

            if (entity is Node) {
                var node:Node = Node(entity);
                if (node == getNode(node.id)) { // confirm it's from this connection
                    makeRequest(entity, 'complete');
                }

            } else if (entity is Way) {
                var way:Way = Way(entity);
                if (way == getWay(way.id)) { // confirm it's from this connection
                    makeRequest(entity, 'complete');
                }
            }
        }

        /**
        * Send a "complete" call to the server and update entity.status if successful.
        */
        public function markNotComplete(entity:Entity):void {
            var urlReq:URLRequest;

            if (entity is Node) {
                var node:Node = Node(entity);
                if (node == getNode(node.id)) { // confirm it's from this connection
                    makeRequest(entity, 'incomplete');
                }

            } else if (entity is Way) {
                var way:Way = Way(entity);
                if (way == getWay(way.id)) { // confirm it's from this connection
                    makeRequest(entity, 'incomplete');
                }
            }
        }

        private function makeRequest(entity:Entity, status:String):void {
            var urlReq:URLRequest = new URLRequest(apiBaseURL+entity.getType()+"/"+entity.id+"/status");
            urlReq.method = "POST";
            urlReq.data = status;
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, function(e:Event):void { updateStatus(entity, status) });
            loader.load(urlReq);
        }

        private function updateStatus(e:Entity, s:String):void {
            e.setStatus(s);
        }

    }
}