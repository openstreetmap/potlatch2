package net.systemeD.halcyon.connection {

	import flash.events.*;

	import flash.system.Security;
	import flash.net.*;
	import org.iotashan.oauth.*;

	import net.systemeD.halcyon.MapEvent;
    import net.systemeD.halcyon.connection.bboxes.*;

	/**
	* XMLBaseConnection is the common code between connecting to an OSM server
	* (i.e. XMLConnection) and connecting to a standalone .osm file (i.e. OSMConnection)
	* and so mainly concerns itself with /map -call-ish related matters
	*/
	public class XMLBaseConnection extends Connection {

		public function XMLBaseConnection(name:String,api:String,policy:String,initparams:Object) {
			super(name,api,policy,initparams);
		}
		
		protected function loadedMap(event:Event):void {
			var map:XML = new XML(URLLoader(event.target).data);
			
			if (map.name().localName=="osmError") {
				dispatchEvent(new MapEvent(MapEvent.ERROR, { message: "Couldn't load the map: " + map.message } ));
			} else {
				var id:Number;
				var version:uint;
				var uid:Number;
				var timestamp:String;
				var tags:Object;
				var node:Node, newNode:Node;
				var unusedNodes:Object={};
				var createdEntities:Array=[];

				var minlon:Number, maxlon:Number, minlat:Number, maxlat:Number;
				var singleEntityRequest:Boolean=true;
				if (map.bounds.@minlon.length()) {
					minlon=map.bounds.@minlon;
					maxlon=map.bounds.@maxlon;
					minlat=map.bounds.@minlat;
					maxlat=map.bounds.@maxlat;
					singleEntityRequest=false;
					fetchSet.add(new Box().fromBbox(minlon,minlat,maxlon,maxlat));
				}

				for each(var relData:XML in map.relation) {
					id = Number(relData.@id);
					version = uint(relData.@version);
					uid = Number(relData.@uid);
					timestamp = relData.@timestamp;
			   
					var rel:Relation = getRelation(id);
					if ( rel == null || !rel.loaded || singleEntityRequest ) {
						tags = parseTags(relData.tag);
						var members:Array = [];
						for each(var memberXML:XML in relData.member) {
							var type:String = memberXML.@type.toLowerCase();
							var role:String = memberXML.@role;
							var memberID:Number = Number(memberXML.@ref);
							var member:Entity = null;
							if ( type == "node" ) {
								member = getNode(memberID);
								if ( member == null ) {
									member = new Node(this,memberID,0,{},false,0,0);
									setNode(Node(member),true);
								} else if (member.isDeleted()) {
									member.setDeletedState(false);
								}
							} else if ( type == "way" ) {
								member = getWay(memberID);
								if (member == null) {
									member = new Way(this,memberID,0,{},false,[]);
									setWay(Way(member),true);
								}
							} else if ( type == "relation" ) {
								member = getRelation(memberID);
								if (member == null) {
									member = new Relation(this,memberID,0,{},false,[]);
									setRelation(Relation(member),true);
								}
							}
						
							if ( member != null )
								members.push(new RelationMember(member, role));
						}
					
						if ( rel == null ) {
							rel=new Relation(this, id, version, tags, true, members, uid, timestamp);
							setRelation(rel, false);
							createdEntities.push(rel);
						} else {
							rel.update(version, tags, true, false, members, uid, timestamp);
							sendEvent(new EntityEvent(NEW_RELATION, rel), false);
						}
					}
				}

				for each(var nodeData:XML in map.node) {
					id = Number(nodeData.@id);
					node = getNode(id);
					newNode = new Node(this,
									   id, 
									   uint(nodeData.@version), 
									   parseTags(nodeData.tag),
									   true, 
									   Number(nodeData.@lat),
									   Number(nodeData.@lon),
									   Number(nodeData.@uid),
									   nodeData.@timestamp);
                if ( inlineStatus ) { newNode.status = nodeData.@status; }
				
					if ( singleEntityRequest ) {
						// it's a revert request, so create/update the node
						setOrUpdateNode(newNode, true);
					} else if ( node == null || !node.loaded) {
						// the node didn't exist before, so create/update it
						newNode.parentsLoaded=newNode.within(minlon,maxlon,minlat,maxlat);
						setOrUpdateNode(newNode, true);
						createdEntities.push(newNode);
					} else {
						// the node's already in memory, but store it in case one of the new ways needs it
						if (newNode.within(minlon,maxlon,minlat,maxlat)) newNode.parentsLoaded=true;
						unusedNodes[id]=newNode;
					}
				}
			
				for each(var data:XML in map.way) {
					id = Number(data.@id);
					version = uint(data.@version);
					uid = Number(data.@uid);
					timestamp = data.@timestamp;

					var way:Way = getWay(id);
					if ( way == null || !way.loaded || singleEntityRequest) {
						var nodelist:Array = [];
						for each(var nd:XML in data.nd) {
							var nodeid:Number=Number(nd.@ref)
							if (getNode(nodeid).isDeleted() && unusedNodes[nodeid]) { 
								setOrUpdateNode(unusedNodes[nodeid], true); 
							}
							nodelist.push(getNode(nodeid));
						}
						tags = parseTags(data.tag);
						if ( way == null ) {
							way=new Way(this, id, version, tags, true, nodelist, uid, timestamp)
							if ( inlineStatus ) { way.status = data.@status; }
							setWay(way,false);
							createdEntities.push(way);
						} else {
							if (!way.loaded) createdEntities.push(way);
							waycount++;
							way.update(version, tags, true, true, nodelist, uid, timestamp);
							if ( inlineStatus ) { way.status = data.@status; }
							sendEvent(new EntityEvent(NEW_WAY, way), false);
						}
					}
				}
				registerPOINodes();
			}

			dispatchEvent(new Event(LOAD_COMPLETED));

			if (statusFetcher) statusFetcher.fetch(createdEntities); 
		}
		
		protected function registerPOINodes():void {
			for each (var nodeID:Number in getAllNodeIDs()) {
				var node:Node = getNode(nodeID);
				if (!node.hasParentWays)
					registerPOI(node);
			}
		}

		private function parseTags(tagElements:XMLList):Object {
			var tags:Object = {};
			for each (var tagEl:XML in tagElements)
				tags[tagEl.@k] = tagEl.@v;
			return tags;
		}

	}
}
