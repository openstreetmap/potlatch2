package net.systemeD.halcyon.connection {

    import flash.net.*;

    import flash.events.EventDispatcher;
    import flash.events.Event;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.MapEvent;

	public class Connection extends EventDispatcher {

        private static var connectionInstance:Connection = null;

        protected static var policyURL:String;
        protected static var apiBaseURL:String;
        protected static var params:Object;

        public static function getConnection(initparams:Object=null):Connection {
            if ( connectionInstance == null ) {
            
                params = initparams == null ? new Object() : initparams;
                policyURL = getParam("policy", "http://127.0.0.1:3000/api/crossdomain.xml");
                apiBaseURL = getParam("api", "http://127.0.0.1:3000/api/0.6/");
                var connectType:String = getParam("connection", "XML");
                
                if ( connectType == "XML" )
                    connectionInstance = new XMLConnection();
                else if ( connectType == "OSM" )
                    connectionInstance = new OSMConnection();
                else
                    connectionInstance = new AMFConnection();
            }
            return connectionInstance;
        }

        public static function getParam(name:String, defaultValue:String):String {
            return params[name] == null ? defaultValue : params[name];
        }

        public function get apiBase():String {
            return apiBaseURL;
        }

        public static function get serverName():String {
            return getParam("serverName", "Localhost");
        }
                
		public static function getConnectionInstance():Connection {
            return connectionInstance;
		}

		public function getEnvironment(responder:Responder):void {}

        // connection events
        public static var LOAD_STARTED:String = "load_started";
        public static var LOAD_COMPLETED:String = "load_completed";
        public static var SAVE_STARTED:String = "save_started";
        public static var SAVE_COMPLETED:String = "save_completed";
        public static var DATA_DIRTY:String = "data_dirty";
        public static var DATA_CLEAN:String = "data_clean";
        public static var NEW_CHANGESET:String = "new_changeset";
        public static var NEW_CHANGESET_ERROR:String = "new_changeset_error";
        public static var NEW_NODE:String = "new_node";
        public static var NEW_WAY:String = "new_way";
        public static var NEW_RELATION:String = "new_relation";
        public static var NEW_POI:String = "new_poi";
        public static var NODE_RENUMBERED:String = "node_renumbered";
        public static var WAY_RENUMBERED:String = "way_renumbered";
        public static var RELATION_RENUMBERED:String = "relation_renumbered";
        public static var TAG_CHANGED:String = "tag_change";
        public static var NODE_MOVED:String = "node_moved";
        public static var NODE_ALTERED:String = "node_altered";
        public static var WAY_NODE_ADDED:String = "way_node_added";
        public static var WAY_NODE_REMOVED:String = "way_node_removed";
        public static var WAY_REORDERED:String = "way_reordered";
        public static var WAY_DRAGGED:String = "way_dragged";
		public static var NODE_DELETED:String = "node_deleted";
		public static var WAY_DELETED:String = "way_deleted";
		public static var RELATION_DELETED:String = "relation_deleted";
		public static var RELATION_MEMBER_ADDED:String = "relation_member_added";
		public static var RELATION_MEMBER_REMOVED:String = "relation_member_deleted";
		public static var ADDED_TO_RELATION:String = "added_to_relation";
		public static var REMOVED_FROM_RELATION:String = "removed_from_relation";
		public static var SUSPEND_REDRAW:String = "suspend_redraw";
		public static var RESUME_REDRAW:String = "resume_redraw";
        public static var TRACES_LOADED:String = "traces_loaded";

        // store the data we download
        private var negativeID:Number = -1;
        private var nodes:Object = {};
        private var ways:Object = {};
        private var relations:Object = {};
        private var pois:Array = [];
        private var changeset:Changeset = null;
		private var changesetUpdated:Number;
		private var modified:Boolean = false;
		public var nodecount:int=0;
		public var waycount:int=0;
		public var relationcount:int=0;
        private var traces:Array = [];
        private var nodePositions:Object = {};
        protected var traces_loaded:Boolean = false;

        protected function get nextNegative():Number {
            return negativeID--;
        }

        protected function setNode(node:Node, queue:Boolean):void {
			if (!nodes[node.id]) { nodecount++; }
            nodes[node.id] = node;
            addDupe(node);
            if (node.loaded) { sendEvent(new EntityEvent(NEW_NODE, node),queue); }
        }

        protected function setWay(way:Way, queue:Boolean):void {
			if (!ways[way.id] && way.loaded) { waycount++; }
            ways[way.id] = way;
            if (way.loaded) { sendEvent(new EntityEvent(NEW_WAY, way),queue); }
        }

        protected function setRelation(relation:Relation, queue:Boolean):void {
			if (!relations[relation.id]) { relationcount++; }
            relations[relation.id] = relation;
            if (relation.loaded) { sendEvent(new EntityEvent(NEW_RELATION, relation),queue); }
        }

		protected function setOrUpdateNode(newNode:Node, queue:Boolean):void {
        	if (nodes[newNode.id]) {
				var wasDeleted:Boolean=nodes[newNode.id].isDeleted();
				nodes[newNode.id].update(newNode.version, newNode.getTagsHash(), true, newNode.parentsLoaded, newNode.lat, newNode.lon, newNode.uid, newNode.timestamp);
				if (wasDeleted) sendEvent(new EntityEvent(NEW_NODE, nodes[newNode.id]), false);
			} else {
				setNode(newNode, queue);
			}
		}

		protected function renumberNode(oldID:Number, newID:Number, version:uint):void {
			var node:Node=nodes[oldID];
			if (oldID!=newID) { removeDupe(node); }
			node.renumber(newID, version);
			if (oldID==newID) return;					// if only a version change, return
			nodes[newID]=node;
			addDupe(node);
			if (node.loaded) { sendEvent(new EntityRenumberedEvent(NODE_RENUMBERED, node, oldID),false); }
			delete nodes[oldID];
		}

		protected function renumberWay(oldID:Number, newID:Number, version:uint):void {
			var way:Way=ways[oldID];
			way.renumber(newID, version);
			if (oldID==newID) return;
			ways[newID]=way;
			if (way.loaded) { sendEvent(new EntityRenumberedEvent(WAY_RENUMBERED, way, oldID),false); }
			delete ways[oldID];
		}

		protected function renumberRelation(oldID:Number, newID:Number, version:uint):void {
			var relation:Relation=relations[oldID];
			relation.renumber(newID, version);
			if (oldID==newID) return;
			relations[newID] = relation;
			if (relation.loaded) { sendEvent(new EntityRenumberedEvent(RELATION_RENUMBERED, relation, oldID),false); }
			delete relations[oldID];
		}


		public function sendEvent(e:*,queue:Boolean):void {
			// queue is only used for AMFConnection
			dispatchEvent(e);
		}

        public function registerPOI(node:Node):void {
            if ( pois.indexOf(node) < 0 ) {
                pois.push(node);
                sendEvent(new EntityEvent(NEW_POI, node),false);
            }
        }

        public function unregisterPOI(node:Node):void {
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

		protected function findEntity(type:String, id:*):Entity {
			var i:Number=Number(id);
			switch (type.toLowerCase()) {
				case 'node':     return getNode(id);
				case 'way':      return getWay(id);
				case 'relation': return getRelation(id);
				default:         return null;
			}
		}

		// Remove data from Connection
		// These functions are used only internally to stop redundant data hanging around
		// (either because it's been deleted on the server, or because we have panned away
		//  and need to reduce memory usage)

		protected function killNode(id:Number):void {
			if (!nodes[id]) return;
            nodes[id].dispatchEvent(new EntityEvent(Connection.NODE_DELETED, nodes[id]));
			removeDupe(nodes[id]);
			if (nodes[id].parentRelations.length>0) {
				nodes[id].nullify();
			} else {
				delete nodes[id];
			}
			nodecount--;
		}

		protected function killWay(id:Number):void {
			if (!ways[id]) return;
            ways[id].dispatchEvent(new EntityEvent(Connection.WAY_DELETED, ways[id]));
			if (ways[id].parentRelations.length>0) {
				ways[id].nullify();
			} else {
				delete ways[id];
			}
			waycount--;
		}

		protected function killRelation(id:Number):void {
			if (!relations[id]) return;
            relations[id].dispatchEvent(new EntityEvent(Connection.RELATION_DELETED, relations[id]));
			if (relations[id].parentRelations.length>0) {
				relations[id].nullify();
			} else {
				delete relations[id];
			}
			relationcount--;
		}

		protected function killWayWithNodes(id:Number):void {
			var way:Way=ways[id];
			var node:Node;
			for (var i:uint=0; i<way.length; i++) {
				node=way.getNode(i);
				if (node.isDirty) { continue; }
				if (node.parentWays.length>1) {
					node.removeParent(way);
				} else {
					killNode(node.id);
				}
			}
			killWay(id);
		}
		
		protected function killEntity(entity:Entity):void {
			if (entity is Way) { killWay(entity.id); }
			else if (entity is Node) { killNode(entity.id); }
			else if (entity is Relation) { killRelation(entity.id); }
		}

        public function createNode(tags:Object, lat:Number, lon:Number, performCreate:Function):Node {
            var node:Node = new Node(nextNegative, 0, tags, true, lat, lon);
            performCreate(new CreateEntityAction(node, setNode));
			//markDirty();
            return node;
        }

        public function createWay(tags:Object, nodes:Array, performCreate:Function):Way {
            var way:Way = new Way(nextNegative, 0, tags, true, nodes.concat());
            performCreate(new CreateEntityAction(way, setWay));
			//markDirty();
            return way;
        }

        public function createRelation(tags:Object, members:Array, performCreate:Function):Relation {
            var relation:Relation = new Relation(nextNegative, 0, tags, true, members.concat());
            performCreate(new CreateEntityAction(relation, setRelation));
			//markDirty();
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

        public function getMatchingRelationIDs(match:Object):Array {
            var list:Array = [];
			var ok:Boolean;
            for each (var relation:Relation in relations) {
				ok=true;
				if (relation.deleted) { ok=false; }
				for (var k:String in match) {
					if (!relation.getTagsHash()[k] || relation.getTagsHash()[k]!=match[k]) { ok=false; }
				}
				if (ok) { list.push(relation.id); }
			}
            return list;
        }

		public function getObjectsByBbox(left:Number, right:Number, top:Number, bottom:Number):Object {
			var o:Object = { poisInside: [], poisOutside: [], waysInside: [], waysOutside: [] };
			for each (var way:Way in ways) {
				if (way.within(left,right,top,bottom)) { o.waysInside.push(way); }
				                                  else { o.waysOutside.push(way); }
			}
			for each (var poi:Node in pois) {
				if (poi.within(left,right,top,bottom)) { o.poisInside.push(poi); }
				                                  else { o.poisOutside.push(poi); }
			}
			return o;
		}

		public function purgeOutside(left:Number, right:Number, top:Number, bottom:Number):void {
			for each (var way:Way in ways) {
				if (!way.within(left,right,top,bottom) && !way.isDirty && !way.locked && !way.hasLockedNodes()) {
					killWayWithNodes(way.id);
				}
			}
			for each (var poi:Node in pois) {
				if (!poi.within(left,right,top,bottom) && !poi.isDirty && !poi.locked) {
					killNode(poi.id);
				}
			}
			// ** should purge relations too, if none of their members are on-screen
		}

		public function markDirty():void {
            if (!modified) { dispatchEvent(new Event(DATA_DIRTY)); }
			modified=true;
		}
		public function markClean():void {
            if (modified) { dispatchEvent(new Event(DATA_CLEAN)); }
			modified=false;
		}
		public function get isDirty():Boolean {
			return modified;
		}

		// Changeset tracking

        protected function setActiveChangeset(changeset:Changeset):void {
            this.changeset = changeset;
			changesetUpdated = new Date().getTime();
            sendEvent(new EntityEvent(NEW_CHANGESET, changeset),false);
        }

		protected function freshenActiveChangeset():void {
			changesetUpdated = new Date().getTime();
		}
		
		protected function closeActiveChangeset():void {
			changeset = null;
		}
        
        public function getActiveChangeset():Changeset {
			if (changeset && (new Date().getTime()) > (changesetUpdated+58*60*1000)) {
				closeActiveChangeset();
			}
            return changeset;
        }

        protected function addTrace(t:Object):void {
            traces.push(t);
        }

        protected function clearTraces():void {
            traces = [];
        }

        public function getTraces():Array {
            return traces;
        }

        public function addDupe(node:Node):void {
            if (getNode(node.id) != node) { return; } // make sure it's on this connection
            var a:String = node.lat+","+node.lon;
            if(!nodePositions[a]) {
              nodePositions[a] = [];
            }
            nodePositions[a].push(node);
            if (nodePositions[a].length > 1) { // don't redraw if it's the only node in town
              for each (var n:Node in nodePositions[a]) {
                n.dispatchEvent(new Event(Connection.NODE_ALTERED));
              }
            }
        }

        public function removeDupe(node:Node):void {
            if (getNode(node.id) != node) { return; } // make sure it's on this connection
            var a:String = node.lat+","+node.lon;
            var redraw:Boolean=node.isDupe();
            var dupes:Array = [];
            for each (var dupe:Node in nodePositions[a]) {
              if (dupe!=node) { dupes.push(dupe); }
            }
            nodePositions[a] = dupes;
            for each (var n:Node in nodePositions[a]) { // redraw any nodes remaining
              n.dispatchEvent(new Event(Connection.NODE_ALTERED));
            }
            if (redraw) { node.dispatchEvent(new Event(Connection.NODE_ALTERED)); } //redraw the one being moved
        }

        public function nodesAtPosition(lat:Number, lon:Number):uint {
            if (nodePositions[lat+","+lon]) {
              return nodePositions[lat+","+lon].length;
            }
            return 0;
        }

        public function getNodesAtPosition(lat:Number, lon:Number):Array {
            if (nodePositions[lat+","+lon]) {
              return nodePositions[lat+","+lon];
            }
            return [];
        }

		// Error-handling
		
		protected function throwConflictError(entity:Entity,serverVersion:uint,message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "An item you edited has been changed by another mapper. Download their version and try again? (The server said: "+message+")",
				yes: function():void { revertBeforeUpload(entity) },
				no: cancelUpload }));
			// ** FIXME: this should also offer the choice of 'overwrite?'
		}
		protected function throwAlreadyDeletedError(entity:Entity,message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "You tried to delete something that's already been deleted. Forget it and try again? (The server said: "+message+")",
				yes: function():void { deleteBeforeUpload(entity) },
				no: cancelUpload }));
		}
		protected function throwInUseError(entity:Entity,message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "You tried to delete something that's since been used elsewhere. Restore it and try again? (The server said: "+message+")",
				yes: function():void { revertBeforeUpload(entity) },
				no: cancelUpload }));
		}
		protected function throwEntityError(entity:Entity,message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "There is a problem with your changes which needs to be fixed before you can save: "+message+". Click 'OK' to see the offending item.",
				ok: function():void { goToEntity(entity) } }));
		}
		protected function throwChangesetError(message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "The changeset in which you're saving changes is no longer valid. Start a new one and retry? (The server said: "+message+")",
				yes: retryUploadWithNewChangeset,
				no: cancelUpload }));
		}
		protected function throwBugError(message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "An unexpected error occurred, probably due to a bug in Potlatch 2. Do you want to retry? (The server said: "+message+")",
				yes: retryUpload,
				no: cancelUpload }));
		}
		protected function throwServerError(message:String):void {
			dispatchEvent(new MapEvent(MapEvent.ERROR, {
				message: "A server error occurred. Do you want to retry? (The server said: "+message+")",
				yes: retryUpload,
				no: cancelUpload }));
		}

		public function retryUpload():void { uploadChanges(); }
		public function cancelUpload():void { return; }
		public function retryUploadWithNewChangeset():void { 
			// ** FIXME: we need to move the create-changeset-then-upload logic out of SaveDialog
		}
		public function goToEntity(entity:Entity):void { 
			dispatchEvent(new MapEvent(MapEvent.ATTENTION, { entity: entity }));
		}
		public function revertBeforeUpload(entity:Entity):void { 
			// ** FIXME: implement a 'revert entity' method, then retry upload on successful download
		}
		public function deleteBeforeUpload(entity:Entity):void {
            var a:CompositeUndoableAction = new CompositeUndoableAction("Delete refs");            
            entity.remove(a.push);
            a.doAction();
			killEntity(entity);
			uploadChanges();
		}

        // these are functions that the Connection implementation is expected to
        // provide. This class has some generic helpers for the implementation.
		public function loadBbox(left:Number, right:Number,
								top:Number, bottom:Number):void {
	    }
	    
	    public function setAuthToken(id:Object):void {}
        public function setAccessToken(key:String, secret:String):void {}
	    public function createChangeset(tags:Object):void {}
		public function closeChangeset():void {}
	    public function uploadChanges():void {}
        public function fetchUserTraces(refresh:Boolean=false):void {}
        public function fetchTrace(id:Number, callback:Function):void {}
        public function hasAccessToken():Boolean { return false; }
    }

}

