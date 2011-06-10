package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.*;
    import flash.events.Event;
    import flash.net.*;

    public class SnapshotConnection extends XMLConnection {

        public function SnapshotConnection(cname:String,api:String,policy:String,initparams:Object=null) {
            super(cname,api,policy,initparams);
        }

        /** Send a "complete" call to the server, and remove it from the current layer */
        public function markComplete(entity:Entity):void {
            if (entity is Node) {
              var node:Node = Node(entity);
              if (node == getNode(node.id)) { // confirm it's from this connection
                  var urlReq:URLRequest = new URLRequest(apiBaseURL+"node/"+node.id+"/complete");
                  urlReq.method = "POST";
                  urlReq.data = '   ';
                  urlReq.contentType = "application/xml";
                  urlReq.requestHeaders = [ new URLRequestHeader("X_HTTP_METHOD_OVERRIDE", "PUT"),
                                            new URLRequestHeader("X-Error-Format", "XML") ];
                  var loader:URLLoader = new URLLoader();
                  loader.addEventListener(Event.COMPLETE, function(e:Event):void { killNode(node.id) });
                  loader.load(urlReq);
              }

            } else if (entity is Way) {
              var way:Way = Way(entity);
              trace("not implemented");
            }
        }

    }
}