package net.systemeD.halcyon.connection {

    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

	import flash.system.Security;
	import flash.net.*;

	public class AMFConnection extends Connection {

		public var readConnection:NetConnection;
		public var writeConnection:NetConnection;
		private var mapLoader:URLLoader;

		// ------------------------------------------------------------
		// Constructor for new AMFConnection

		public function AMFConnection() {

			if (Connection.policyURL!='')
                Security.loadPolicyFile(Connection.policyURL);

			readConnection=new NetConnection();
			readConnection.objectEncoding = flash.net.ObjectEncoding.AMF0;
			readConnection.connect(Connection.apiBaseURL+"amf/read");
			
			writeConnection=new NetConnection();
			writeConnection.objectEncoding = flash.net.ObjectEncoding.AMF0;
			writeConnection.connect(Connection.apiBaseURL+"amf/write");
			
		}

		override public function getEnvironment(responder:Responder):void {
			readConnection.call("getpresets",responder,"en");
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
			readConnection.call("whichways",new Responder(gotBbox, error),left,bottom,right,top);
		}

        private function gotBbox(r:Object):void {
			var code:uint         =r.shift();
            if (code) {
                error(new Array(r.shift()));
                return;
            }

			var message:String    =r.shift();
			var waylist:Array     =r[0];
			var pointlist:Array   =r[1];
			var relationlist:Array=r[2];
			var id:Number, version:uint;

			for each (var w:Array in waylist) {
				id=Number(w[0]);
                version=uint(w[1]);

                var way:Way = getWay(id);
                if ( way == null ) {
                    loadWay(id);
                }
			}

			for each (var p:Array in pointlist) {
				id = Number(w[0]);
                version = uint(w[4]);

                var node:Node = getNode(id);
                if ( node == null ) {
                    var lat:Number = Number(w[2]);
                    var lon:Number = Number(w[1]);
                    var tags:Object = w[3];
                    node = new Node(id, version, tags, lat, lon);
                    setNode(node);
                }
                registerPOI(node);
			}
        }

        private function error(r:Object):void {}

		private function loadWay(id:uint):void {
			readConnection.call("getway",new Responder(gotWay, error),id);
		}

		private function gotWay(r:Object):void {
			var code:uint = r.shift();
            if (code) {
                error(new Array(r.shift()));
                return;
            }

			var message:String=r.shift();
            var id:Number = Number(r[0]);
			var version:uint = uint(r[3]);

            var way:Way = getWay(id);
            if ( way != null )
                return;

            var nodesAMF:Array = r[1];
			var tags:Object = r[2];
			
            var nodes:Array = [];
			for each (var p:Array in nodesAMF) {
                var nodeID:Number = Number(p[2]);
                var nodeVersion:uint = uint(p[4]);

                var node:Node = getNode(nodeID);
                if ( node == null ) {
                    var lon:Number = Number(p[0]);
                    var lat:Number = Number(p[1]);
                    var nodeTags:Object = p[3];
                    node = new Node(nodeID, nodeVersion, nodeTags, lat, lon);
                    setNode(node);
                }
                nodes.push(node);
			}

            way = new Way(id, version, tags, nodes);
            setWay(way);
		}

	}
}
