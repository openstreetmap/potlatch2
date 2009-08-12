package net.systemeD.halcyon.connection {

    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

	import flash.system.Security;
	import flash.net.*;


	public class XMLConnection extends Connection {

        public var readConnection:NetConnection;

		public function XMLConnection() {

			if (Connection.policyURL!='')
                Security.loadPolicyFile(Connection.policyURL);

			readConnection=new NetConnection();
			readConnection.objectEncoding = flash.net.ObjectEncoding.AMF0;
			readConnection.connect(Connection.apiBaseURL+"amf/read");
			
		}

		override public function getEnvironment(responder:Responder):void {
			readConnection.call("getpresets",responder,"en");
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
            var mapVars:URLVariables = new URLVariables();
            mapVars.bbox= left+","+bottom+","+right+","+top;

            var mapRequest:URLRequest = new URLRequest(Connection.apiBaseURL+"map");
            mapRequest.data = mapVars;

            var mapLoader:URLLoader = new URLLoader();
            mapLoader.addEventListener(Event.COMPLETE, loadedMap);
            mapLoader.load(mapRequest);
            dispatchEvent(new Event(LOAD_STARTED));
		}

        private function parseTags(tagElements:XMLList):Object {
            var tags:Object = {};
            for each (var tagEl:XML in tagElements)
                tags[tagEl.@k] = tagEl.@v;
            return tags;
        }

        private function loadedMap(event:Event):void {
            dispatchEvent(new Event(LOAD_COMPLETED));

            var map:XML = new XML(URLLoader(event.target).data);
            var id:Number;
            var version:uint;
            var tags:Object;

            for each(var nodeData:XML in map.node) {
                id = Number(nodeData.@id);
                version = uint(nodeData.@version);

                var node:Node = getNode(id);
                if ( node == null ) {
                    var lat:Number = Number(nodeData.@lat);
                    var lon:Number = Number(nodeData.@lon);
                    tags = parseTags(nodeData.tag);
                    setNode(new Node(id, version, tags, lat, lon));
                }
            }

            for each(var data:XML in map.way) {
                id = Number(data.@id);
                version = uint(data.@version);

                var way:Way = getWay(id);
                if ( way == null ) {
                    var nodes:Array = [];
                    for each(var nd:XML in data.nd)
                        nodes.push(getNode(Number(nd.@ref)));
                    tags = parseTags(data.tag);
                    setWay(new Way(id, version, tags, nodes));
                }
            }
        }

	}
}
