package net.systemeD.halcyon.connection {

    import flash.events.*;

	import flash.system.Security;
	import flash.net.*;
    import org.iotashan.oauth.*;


	public class XMLConnection extends Connection {

        //public var readConnection:NetConnection;

		public function XMLConnection() {

			if (Connection.policyURL!='')
                Security.loadPolicyFile(Connection.policyURL);
            var oauthPolicy:String = Connection.getParam("oauth_policy", "");
            if ( oauthPolicy != "" ) {
                trace(oauthPolicy);
                Security.loadPolicyFile(oauthPolicy);
            }
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
            var mapVars:URLVariables = new URLVariables();
            mapVars.bbox= left+","+bottom+","+right+","+top;

            var mapRequest:URLRequest = new URLRequest(Connection.apiBaseURL+"map");
            mapRequest.data = mapVars;

            var mapLoader:URLLoader = new URLLoader();
            mapLoader.addEventListener(Event.COMPLETE, loadedMap);
            mapLoader.addEventListener(IOErrorEvent.IO_ERROR, errorOnMapLoad);
            mapLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, mapLoadStatus);
            mapLoader.load(mapRequest);
            dispatchEvent(new Event(LOAD_STARTED));
		}

        private function parseTags(tagElements:XMLList):Object {
            var tags:Object = {};
            for each (var tagEl:XML in tagElements)
                tags[tagEl.@k] = tagEl.@v;
            return tags;
        }

        private function errorOnMapLoad(event:Event):void {
            trace("error loading map");
        }
        private function mapLoadStatus(event:HTTPStatusEvent):void {
            trace("loading map status = "+event.status);
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
            
            registerPOINodes();
        }
        
        protected function registerPOINodes():void {
            for each (var nodeID:Number in getAllNodeIDs()) {
                var node:Node = getNode(nodeID);
                if (!node.hasParentWays)
                    registerPOI(node);
            }
        }

        protected var appID:OAuthConsumer;
        protected var authToken:OAuthToken;
        
	    override public function setAppID(id:Object):void {
	        appID = OAuthConsumer(id);
	    }
	    
	    override public function setAuthToken(id:Object):void {
	        authToken = OAuthToken(id);
	    }

        private var httpStatus:int = 0;
        
        private function recordStatus(event:HTTPStatusEvent):void {
            httpStatus = event.status;
        }
        
        private var lastUploadedChangesetTags:Object;
        
        override public function createChangeset(tags:Object):void {
            lastUploadedChangesetTags = tags;
            
   	        var changesetXML:XML = <osm version="0.6"><changeset /></osm>;
	        var changeset:XML = <changeset />;
	        for (var tagKey:Object in tags) {
              var tagXML:XML = <tag/>;
              tagXML.@k = tagKey;
              tagXML.@v = tags[tagKey];
              changesetXML.changeset.appendChild(tagXML);
            }        

            // make an OAuth query
            var sig:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();
            var url:String = Connection.apiBaseURL+"changeset/create";
            //var params:Object = { _method: "PUT" };
            var oauthRequest:OAuthRequest = new OAuthRequest("PUT", url, null, appID, authToken);
            var urlStr:Object = oauthRequest.buildRequest(sig, OAuthRequest.RESULT_TYPE_URL_STRING)

            // build the actual request
            var urlReq:URLRequest = new URLRequest(String(urlStr));
            urlReq.method = "POST";
            urlReq.data = changesetXML.toXMLString();
            urlReq.contentType = "application/xml";
            urlReq.requestHeaders = new Array(new URLRequestHeader("X_HTTP_METHOD_OVERRIDE", "PUT"));
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, changesetCreateComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, changesetCreateError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, recordStatus);
	        loader.load(urlReq);
	    }

        private function changesetCreateComplete(event:Event):void {
            // response should be a Number changeset id
            var id:Number = Number(URLLoader(event.target).data);
            
            // which means we now have a new changeset!
            setActiveChangeset(new Changeset(id, lastUploadedChangesetTags));
        }

        private function changesetCreateError(event:IOErrorEvent):void {
            dispatchEvent(new Event(NEW_CHANGESET_ERROR));
        }
        
        override public function uploadChanges():void {
            var changeset:Changeset = getActiveChangeset();
            var upload:XML = <osmChange version="0.6"/>
            upload.appendChild(addCreated(changeset, getAllNodeIDs, getNode, serialiseNode));
            upload.appendChild(addCreated(changeset, getAllWayIDs, getWay, serialiseWay));
            upload.appendChild(addCreated(changeset, getAllRelationIDs, getRelation, serialiseRelation));
            upload.appendChild(addModified(changeset, getAllNodeIDs, getNode, serialiseNode));
            upload.appendChild(addModified(changeset, getAllWayIDs, getWay, serialiseWay));
            upload.appendChild(addModified(changeset, getAllRelationIDs, getRelation, serialiseRelation));

            // *** TODO *** deleting items
            
            // now actually upload them
            // make an OAuth query
            var sig:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();
            var url:String = Connection.apiBaseURL+"changeset/" + changeset.id + "/upload";
            var oauthRequest:OAuthRequest = new OAuthRequest("POST", url, null, appID, authToken);
            var urlStr:Object = oauthRequest.buildRequest(sig, OAuthRequest.RESULT_TYPE_URL_STRING)

            // build the actual request
            var urlReq:URLRequest = new URLRequest(String(urlStr));
            urlReq.method = "POST";
            urlReq.data = upload.toXMLString();
            urlReq.contentType = "text/xml";
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, diffUploadComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, diffUploadError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, recordStatus);
	        loader.load(urlReq);
	        
	        dispatchEvent(new Event(SAVE_STARTED));
        }

        private function diffUploadComplete(event:Event):void {
            // response should be XML describing the progress
            var results:XML = new XML((URLLoader(event.target).data));
            
            for each( var update:XML in results.child("*") ) {
                var oldID:Number = Number(update.@old_id);
                var newID:Number = Number(update.@new_id);
                var version:uint = uint(update.@new_version);
                var type:String = update.name();
                
                var entity:Entity;
                if ( type == "node" ) entity = getNode(oldID);
                else if ( type == "way" ) entity = getWay(oldID);
                else if ( type == "relation" ) entity = getRelation(oldID);
                entity.markClean(newID, version);
                
                if ( oldID != newID ) {
                    if ( type == "node" ) renumberNode(oldID, entity as Node, false);
                    else if ( type == "way" ) renumberWay(oldID, entity as Way, false);
                    else if ( type == "relation" ) renumberRelation(oldID, entity as Relation, false);
                }
                // *** TODO *** handle deleting
            }

	        dispatchEvent(new SaveCompleteEvent(SAVE_COMPLETED, true));
        }

        private function diffUploadError(event:IOErrorEvent):void {
            trace("error "+URLLoader(event.target).data + " "+httpStatus+ " " + event.text);

	        dispatchEvent(new SaveCompleteEvent(SAVE_COMPLETED, false));
        }

        private function addCreated(changeset:Changeset, getIDs:Function, get:Function, serialise:Function):XML {
            var create:XML = <create version="0.6"/>
            for each( var id:Number in getIDs() ) {
                if ( id >= 0 )
                    continue;
                    
                var entity:Object = get(id);
                var xml:XML = serialise(entity);
                xml.@changeset = changeset.id;
                create.appendChild(xml);
            }
            return create.hasComplexContent() ? create : <!-- blank create section -->;
        }

        private function addModified(changeset:Changeset, getIDs:Function, get:Function, serialise:Function):XML {
            var modify:XML = <modify version="0.6"/>
            for each( var id:Number in getIDs() ) {
                var entity:Entity = get(id);
                // creates are already included
                if ( id < 0 || !entity.isDirty )
                    continue;
                    
                var xml:XML = serialise(entity);
                xml.@changeset = changeset.id;
                modify.appendChild(xml);
            }
            return modify.hasComplexContent() ? modify : <!-- blank modify section -->;
        }

        private function serialiseNode(node:Node):XML {
            var xml:XML = <node/>
            serialiseEntity(node, xml);
            xml.@lat = node.lat;
            xml.@lon = node.lon;
            return xml;
        }

        private function serialiseWay(way:Way):XML {
            var xml:XML = <way/>
            serialiseEntity(way, xml);
            for ( var i:uint = 0; i < way.length; i++ ) {
                var nd:XML = <nd/>
                nd.@ref = way.getNode(i).id;
                xml.appendChild(nd);
            }
            return xml;
        }

        private function serialiseRelation(relation:Relation):XML {
            var xml:XML = <relation/>
            serialiseEntity(relation, xml);
            for ( var i:uint = 0; i < relation.length; i++ ) {
                var relMember:RelationMember = relation.getMember(i);
                var member:XML = <member/>
                member.@ref = relMember.entity.id;
                member.@type = relMember.entity.getType();
                member.@role = relMember.role;
                xml.appendChild(member);
            }
            return xml;
        }
        
        private function serialiseEntity(entity:Entity, xml:XML):void {
            xml.@id = entity.id;
            xml.@version = entity.version;
            for each( var tag:Tag in entity.getTagArray() ) {
              var tagXML:XML = <tag/>
              tagXML.@k = tag.key;
              tagXML.@v = tag.value;
              xml.appendChild(tagXML);
            }
        }
	}
}
