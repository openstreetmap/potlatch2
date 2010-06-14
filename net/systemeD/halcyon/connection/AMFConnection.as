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

		private var eventTarget:AMFCounter;
		private var bboxrequests:Array=new Array();

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
			readConnection.call("getpresets",responder,null,"en");
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
			readConnection.call("whichways",new Responder(gotBbox, error),left,bottom,right,top);
		}
		
		override public function sendEvent(e:*,queue:Boolean):void {
			if (queue) { eventTarget.addEvent(e); }
			      else { dispatchEvent(e); }
		}

        private function gotBbox(r:Object):void {
			var code:uint=r.shift();
            if (code) {
                error(new Array(r.shift()));
                return;
            }

			var message:String    =r.shift();
			var waylist:Array     =r[0];
			var pointlist:Array   =r[1];
			var relationlist:Array=r[2];
			var id:Number, version:uint;
			var requests:AMFCounter=new AMFCounter(this);
			eventTarget=requests;

			// Load relations

			for each (var a:Array in relationlist) {
				id=Number(a[0]);
                version=uint(a[1]);

                var relation:Relation = getRelation(id);
                if ( relation == null || !relation.loaded  ) {
                    loadRelation(id);
					requests.addRelationRequest(id);
                }
			}

			// Load ways

			for each (var w:Array in waylist) {
				id=Number(w[0]);
                version=uint(w[1]);

                var way:Way = getWay(id);
                if ( way == null || !way.loaded ) {
                    loadWay(id);
					requests.addWayRequest(id);
                }
			}

			// Create POIs

			for each (var p:Array in pointlist) {
				id = Number(p[0]);
                version = uint(p[4]);

                var node:Node = getNode(id);
                if ( node == null || !node.loaded ) {
                    var lat:Number = Number(p[2]);
                    var lon:Number = Number(p[1]);
                    var tags:Object = p[3];
                    node = new Node(id, version, tags, true, lat, lon);
                    setNode(node,true);
                }
                registerPOI(node);
			}

 			bboxrequests.push(requests);
        }

        private function error(r:Object):void {}

		private function loadWay(id:Number):void {
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
            if ( way != null && way.loaded ) {
				gotRequest(id+"way");
                return;
			}

            var nodesAMF:Array = r[1];
			var tags:Object = r[2];
			
            var nodes:Array = [];
			for each (var p:Array in nodesAMF) {
                var nodeID:Number = Number(p[2]);
                var nodeVersion:uint = uint(p[4]);
                var lon:Number = Number(p[0]);
                var lat:Number = Number(p[1]);

                var node:Node = getNode(nodeID);
                if ( node == null ) {
                    var nodeTags:Object = p[3];
                    node = new Node(nodeID, nodeVersion, nodeTags, true, lat, lon);
                } else if (!node.loaded) {
					node.update(nodeVersion, nodeTags, true, lat, lon);
				}
                setNode(node,true);
                nodes.push(node);
			}

			if (way==null) {
            	way = new Way(id, version, tags, true, nodes);
			} else {
				way.update(version, tags, true, nodes);
			}
           	setWay(way,true);
			gotRequest(id+"way");
		}


		private function loadRelation(id:Number):void {
			readConnection.call("getrelation",new Responder(gotRelation, error),id);
		}

		private function gotRelation(r:Object):void {
			var code:uint = r.shift();
            if (code) { error(new Array(r.shift())); return; }
			var message:String=r.shift();

            var id:Number = Number(r[0]);
			var version:uint = uint(r[3]);

            var relation:Relation = getRelation(id);
            if ( relation != null && relation.loaded ) {
				gotRequest(id+"rel");
				return;
			}

			var tags:Object = r[1];
            var membersAMF:Array = r[2];
			var members:Array = [];
			for each (var p:Array in membersAMF) {
				var type:String=p[0];
				var memid:Number=p[1];
				var role:String=p[2];
				var e:Entity;
				switch (type) {
					case 'Node':
						e=getNode(memid);
						if (e==null) { e=new Node(memid,0,{},false,0,0); setNode(Node(e),true); }
						break;
					case 'Way':
						e=getWay(memid);
						if (e==null) { e=new Way(memid,0,{},false,[]); setWay(Way(e),true); }
						break;
					case 'Relation':
						e=getRelation(memid);
						if (e==null) { e=new Relation(memid,0,{},false,[]); setRelation(Relation(e),true); }
						break;
				}
				members.push(new RelationMember(e,role));
			}
			if (relation==null) {
	            relation = new Relation(id, version, tags, true, members);
			} else {
				relation.update(version,tags,true,members);
			}
            setRelation(relation,true);
			gotRequest(id+"rel");
		}
		
		private function gotRequest(n:String):void {
			for each (var c:AMFCounter in bboxrequests) {
				if (c.removeRequest(n)) { break; }
			}
			while (bboxrequests.length>0 && bboxrequests[0].count==0) {
				bboxrequests.shift();
			}
		}
	}
}
