package net.systemeD.halcyon.connection {

    import flash.net.*;

    import flash.events.EventDispatcher;
    import flash.events.Event;

	public class Connection extends EventDispatcher {

        private static var CONNECTION_TYPE:String = "AMF";
        private static var connectionInstance:Connection = null;

        protected static var policyURL:String = "http://127.0.0.1:3000/api/crossdomain.xml";
        protected static var apiBaseURL:String = "http://127.0.0.1:3000/api/0.6/";

        public static function getConnection(api:String,policy:String,conn:String):Connection {
			
			policyURL=policy;
			apiBaseURL=api;
			CONNECTION_TYPE=conn;
			
            if ( connectionInstance == null ) {
                if ( CONNECTION_TYPE == "XML" )
                    connectionInstance = new XMLConnection();
                else
                    connectionInstance = new AMFConnection();
            }
            return connectionInstance;
        }

		public static function getConnectionInstance():Connection {
            return connectionInstance;
		}

		public function getEnvironment(responder:Responder):void {}

        // connection events
        public static var NEW_NODE:String = "new_node";
        public static var NEW_WAY:String = "new_way";
        public static var NEW_RELATION:String = "new_relation";
        public static var NEW_POI:String = "new_poi";
        public static var TAG_CHANGE:String = "tag_change";

        // store the data we download
        private var negativeID:Number = -1;
        private var nodes:Object = {};
        private var ways:Object = {};
        private var relations:Object = {};
        private var pois:Array = [];

        protected function get nextNegative():Number {
            return negativeID--;
        }

        protected function setNode(node:Node):void {
            nodes[node.id] = node;
            dispatchEvent(new EntityEvent(NEW_NODE, node));
        }

        protected function setWay(way:Way):void {
            ways[way.id] = way;
            dispatchEvent(new EntityEvent(NEW_WAY, way));
        }

        protected function setRelation(relation:Relation):void {
            relations[relation.id] = relation;
            dispatchEvent(new EntityEvent(NEW_RELATION, relation));
        }

        protected function registerPOI(node:Node):void {
            if ( pois.indexOf(node) < 0 ) {
                pois.push(node);
                dispatchEvent(new EntityEvent(NEW_POI, node));
            }
        }

        protected function unregisterPOI(node:Node):void {
            var index:uint = pois.indexOf(node);
            if ( index >= 0 ) {
                pois.splice(index,1);
            }
        }

        public function getNode(id:Number):Node {
            return nodes[id];
        }

        public function getWay(id:Number):Way {
            return ways[id];
        }

        public function getRelation(id:Number):Relation {
            return relations[id];
        }

        public function createNode(tags:Object, lat:Number, lon:Number):Node {
            var node:Node = new Node(nextNegative, 0, tags, lat, lon);
            setNode(node);
            return node;
        }

        public function createWay(tags:Object, nodes:Array):Way {
            var way:Way = new Way(nextNegative, 0, tags, nodes.concat());
            setWay(way);
            return way;
        }

        public function createRelation(tags:Object, members:Array):Relation {
            var relation:Relation = new Relation(nextNegative, 0, tags, members.concat());
            setRelation(relation);
            return relation;
        }

        public function getAllNodeIDs():Array {
            var list:Array = [];
            for each (var node:Node in nodes)
                list.push(node.id);
            return list;
        }

        public function getAllWayIDs():Array {
            var list:Array = [];
            for each (var way:Way in ways)
                list.push(way.id);
            return list;
        }

        public function getAllRelationIDs():Array {
            var list:Array = [];
            for each (var relation:Relation in relations)
                list.push(relation.id);
            return list;
        }

        // these are functions that the Connection implementation is expected to
        // provide. This class has some generic helpers for the implementation.
		public function loadBbox(left:Number, right:Number,
								top:Number, bottom:Number):void {
	    }
    }

}

