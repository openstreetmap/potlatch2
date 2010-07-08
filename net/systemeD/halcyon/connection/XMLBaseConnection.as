package net.systemeD.halcyon.connection {

    import flash.events.*;

	import flash.system.Security;
	import flash.net.*;
    import org.iotashan.oauth.*;

	import net.systemeD.halcyon.Globals;

	public class XMLBaseConnection extends Connection {

		public function XMLBaseConnection() {
		}
		
        protected function loadedMap(event:Event):void {
            dispatchEvent(new Event(LOAD_COMPLETED));

            var map:XML = new XML(URLLoader(event.target).data);
            var id:Number;
            var version:uint;
            var tags:Object;

            for each(var relData:XML in map.relation) {
                id = Number(relData.@id);
                version = uint(relData.@version);
                
                var rel:Relation = getRelation(id);
                if ( rel == null || !rel.loaded ) {
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
                                member = new Node(memberID,0,{},false,0,0);
                                setNode(Node(member),true);
                            }
                        } else if ( type == "way" ) {
                            member = getWay(memberID);
                            if (member == null) {
                                member = new Way(memberID,0,{},false,[]);
                                setWay(Way(member),true);
                            }
                        } else if ( type == "relation" ) {
                            member = getRelation(memberID);
                            if (member == null) {
                                member = new Relation(memberID,0,{},false,[]);
                                setRelation(Relation(member),true);
                            }
                        }
                        
                        if ( member != null )
                            members.push(new RelationMember(member, role));
                    }
                    
                    if ( rel == null )
                        setRelation(new Relation(id, version, tags, true, members), false);
                    else {
                        rel.update(version,tags,true,members);
                        sendEvent(new EntityEvent(NEW_RELATION, rel), false);
                    }
                }
            }
            
            for each(var nodeData:XML in map.node) {
                id = Number(nodeData.@id);
                version = uint(nodeData.@version);

                var node:Node = getNode(id);
                if ( node == null || !node.loaded ) {
                    var lat:Number = Number(nodeData.@lat);
                    var lon:Number = Number(nodeData.@lon);
                    tags = parseTags(nodeData.tag);
                    if ( node == null )
                        setNode(new Node(id, version, tags, true, lat, lon),false);
                    else {
                        node.update(version, tags, true, lat, lon);
                        sendEvent(new EntityEvent(NEW_NODE, node), false);
                    }
                }
            }

            for each(var data:XML in map.way) {
                id = Number(data.@id);
                version = uint(data.@version);

                var way:Way = getWay(id);
                if ( way == null || !way.loaded ) {
                    var nodes:Array = [];
                    for each(var nd:XML in data.nd)
                        nodes.push(getNode(Number(nd.@ref)));
                    tags = parseTags(data.tag);
                    if ( way == null )
                        setWay(new Way(id, version, tags, true, nodes),false);
                    else {
                        way.update(version, tags, true, nodes);
                        sendEvent(new EntityEvent(NEW_WAY, way), false);
                    }
                }
            }
            
            registerPOINodes();
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
