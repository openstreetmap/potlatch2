package net.systemeD.halcyon.connection {

    import flash.events.*;
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.*;
	import flash.system.Security;
	import flash.net.*;
    import org.iotashan.oauth.*;

	import net.systemeD.halcyon.AttentionEvent;
	import net.systemeD.halcyon.MapEvent;
	import net.systemeD.halcyon.ExtendedURLLoader;
    import net.systemeD.halcyon.connection.bboxes.*;

    /**
    * XMLConnection provides all the methods required to connect to a live
    * OSM server. See OSMConnection for connecting to a read-only .osm file
    *
    * @see OSMConnection
    */
	public class XMLConnection extends XMLBaseConnection {

		private const MARGIN:Number=0.05;

        /**
        * Create a new XML connection
        * @param name The name of the connection
        * @param api The url of the OSM API server, e.g. http://api06.dev.openstreetmap.org/api/0.6/
        * @param policy The url of the flash crossdomain policy to load,
                        e.g. http://api06.dev.openstreetmap.org/api/crossdomain.xml
        * @param initparams Any further parameters for the connection, such as the serverName
        */
		public function XMLConnection(name:String,api:String,policy:String,initparams:Object) {

			super(name,api,policy,initparams);
			if (policyURL != "") Security.loadPolicyFile(policyURL);

            var oauthPolicy:String = getParam("oauth_policy", "");
            if (oauthPolicy != "") Security.loadPolicyFile(oauthPolicy);
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
            purgeIfFull(left,right,top,bottom);
			var requestBox:Box=new Box().fromBbox(left,bottom,right,top);
			var boxes:Array;
			try {
				boxes=fetchSet.getBoxes(requestBox,MAX_BBOXES);
			} catch(err:Error) {
				boxes=[requestBox];
			}
			for each (var box:Box in boxes) {
				// enlarge bbox by given margin on each edge
				var xmargin:Number=(box.right-box.left)*MARGIN;
				var ymargin:Number=(box.top-box.bottom)*MARGIN;
				left  =box.left  -xmargin; right=box.right+xmargin;
				bottom=box.bottom-ymargin; top  =box.top  +ymargin;

				dispatchEvent(new MapEvent(MapEvent.DOWNLOAD, {minlon:left, maxlon:right, maxlat:top, minlat:bottom} ));

				// send HTTP request
				var mapVars:URLVariables = new URLVariables();
				mapVars.bbox=left+","+bottom+","+right+","+top;
				var mapRequest:URLRequest = new URLRequest(apiBaseURL+"map");
				mapRequest.data = mapVars;
				sendLoadRequest(mapRequest);
			}
		}

		override public function loadEntityByID(type:String, id:Number):void {
			var url:String=apiBaseURL + type + "/" + id;
			if (type=='way') url+="/full";
			sendLoadRequest(new URLRequest(url));
		}

		private function sendLoadRequest(request:URLRequest):void {
			var mapLoader:URLLoader = new URLLoader();
            var errorHandler:Function = function(event:IOErrorEvent):void {
                errorOnMapLoad(event, request);
            }
			mapLoader.addEventListener(Event.COMPLETE, loadedMap);
			mapLoader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			mapLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, mapLoadStatus);
            request.requestHeaders.push(new URLRequestHeader("X-Error-Format", "XML"));
			mapLoader.load(request);
			dispatchEvent(new Event(LOAD_STARTED));
		}

        private function errorOnMapLoad(event:Event, request:URLRequest):void {
            var url:String = request.url + '?' + URLVariables(request.data).toString(); // for get reqeusts, at least
            dispatchEvent(new MapEvent(MapEvent.ERROR, { message: "There was a problem loading the map data.\nPlease check your internet connection, or try zooming in.\n\n" + url } ));
            dispatchEvent(new Event(LOAD_COMPLETED));
        }

        private function mapLoadStatus(event:HTTPStatusEvent):void {
        }

        protected var appID:OAuthConsumer;
        protected var authToken:OAuthToken;

	    override public function setAuthToken(id:Object):void {
	        authToken = OAuthToken(id);
	    }

        override public function hasAccessToken():Boolean {
            return !(getAccessToken() == null);
        }

        override public function setAccessToken(key:String, secret:String):void {
            if (key && secret) {
              authToken = new OAuthToken(key, secret);
            }
        }

        /* Get the stored access token, or try setting it up from loader params */
        private function getAccessToken():OAuthToken {
            if (authToken == null) {
              var key:String = getParam("oauth_token", null);
              var secret:String = getParam("oauth_token_secret", null);

              if ( key != null && secret != null ) {
                  authToken = new OAuthToken(key, secret);
              }
            }
            return authToken;
        }

        private function getConsumer():OAuthConsumer {
            if (appID == null) {
              var key:String = getParam("oauth_consumer_key", null);
              var secret:String = getParam("oauth_consumer_secret", null);

              if ( key != null && secret != null ) {
                  appID = new OAuthConsumer(key, secret);
              }
            }
            return appID;
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

			sendOAuthPut(apiBaseURL+"changeset/create",
						 changesetXML,
						 changesetCreateComplete, changesetCreateError, recordStatus);
	    }

        private function changesetCreateComplete(event:Event):void {
            var result:String = URLLoader(event.target).data;

            if (result.match(/^^\d+$/)) {
                // response should be a Number changeset id
                var id:Number = Number(URLLoader(event.target).data);
            
                // which means we now have a new changeset!
                setActiveChangeset(new Changeset(this, id, lastUploadedChangesetTags));
            } else {
                var results:XML = XML(result);

                throwServerError(results.message);
            }
        }

        private function changesetCreateError(event:IOErrorEvent):void {
            dispatchEvent(new Event(NEW_CHANGESET_ERROR));
        }

		override public function closeChangeset():void {
            var cs:Changeset = getActiveChangeset();
			if (!cs) return;
			
			sendOAuthPut(apiBaseURL+"changeset/"+cs.id+"/close",
						 null,
						 changesetCloseComplete, changesetCloseError, recordStatus);
			closeActiveChangeset();
		}
		
		private function changesetCloseComplete(event:Event):void { 
			dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Changeset closed"));
		}
		private function changesetCloseError(event:Event):void { 
			dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Couldn't close changeset", 1));
		}

        private function signedOAuthURL(url:String, method:String):String {
            // method should be PUT, GET, POST or DELETE
            var sig:IOAuthSignatureMethod = new OAuthSignatureMethod_HMAC_SHA1();
            var oauthRequest:OAuthRequest = new OAuthRequest(method, url, null, getConsumer(), authToken);
            var urlStr:Object = oauthRequest.buildRequest(sig, OAuthRequest.RESULT_TYPE_URL_STRING);
            return String(urlStr);
        }

		private function sendOAuthPut(url:String, xml:XML, onComplete:Function, onError:Function, onStatus:Function):void {
            // build the request
            var urlReq:URLRequest = new URLRequest(signedOAuthURL(url, "PUT"));
            urlReq.method = "POST";
			if (xml) { urlReq.data = xml.toXMLString(); } else { urlReq.data = true; }
            urlReq.contentType = "application/xml";
            urlReq.requestHeaders = [ new URLRequestHeader("X_HTTP_METHOD_OVERRIDE", "PUT"), 
			                          new URLRequestHeader("X-Error-Format", "XML") ];
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);
	        loader.load(urlReq);
		}

        private function sendOAuthGet(url:String, onComplete:Function, onError:Function, onStatus:Function):void {
            var urlReq:URLRequest = new URLRequest(signedOAuthURL(url, "GET"));
            urlReq.method = "GET";
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);
            loader.load(urlReq);
        }

		/** Create XML changeset and send it to the server. Returns the XML string for use in the 'Show data' button.
		    (We don't mind what's returned as long as it implements .toString() ) */

        override public function uploadChanges():* {
            var changeset:Changeset = getActiveChangeset();
            var upload:XML = <osmChange version="0.6"/>
            upload.appendChild(addCreated(changeset, getAllNodeIDs, getNode, serialiseNode));
            upload.appendChild(addCreated(changeset, getAllWayIDs, getWay, serialiseWay));
            upload.appendChild(addCreated(changeset, getAllRelationIDs, getRelation, serialiseRelation));
            upload.appendChild(addModified(changeset, getAllNodeIDs, getNode, serialiseNode));
            upload.appendChild(addModified(changeset, getAllWayIDs, getWay, serialiseWay));
            upload.appendChild(addModified(changeset, getAllRelationIDs, getRelation, serialiseRelation));
            upload.appendChild(addDeleted(changeset, getAllRelationIDs, getRelation, serialiseEntityRoot, false));
            upload.appendChild(addDeleted(changeset, getAllRelationIDs, getRelation, serialiseEntityRoot, true));
            upload.appendChild(addDeleted(changeset, getAllWayIDs, getWay, serialiseEntityRoot, false));
            upload.appendChild(addDeleted(changeset, getAllWayIDs, getWay, serialiseEntityRoot, true));
            upload.appendChild(addDeleted(changeset, getAllNodeIDs, getNode, serialiseEntityRoot, false));
            upload.appendChild(addDeleted(changeset, getAllNodeIDs, getNode, serialiseEntityRoot, true));

            // now actually upload them
            // make an OAuth query
            var url:String = apiBaseURL+"changeset/" + changeset.id + "/upload";

            // build the actual request
			var serv:HTTPService=new HTTPService();
			serv.method="POST";
			serv.url=signedOAuthURL(url, "POST");
			serv.contentType = "text/xml";
			serv.headers={'X-Error-Format':'xml'};
			serv.request=" ";
			serv.resultFormat="e4x";
			serv.requestTimeout=0;
			serv.addEventListener(ResultEvent.RESULT, diffUploadComplete);
			serv.addEventListener(FaultEvent.FAULT, diffUploadIOError);
			serv.send(upload);
	        
			dispatchEvent(new Event(SAVE_STARTED));
			return upload;
        }

        private function diffUploadComplete(event:ResultEvent):void {
			var results:XML = XML(event.result);

			// was it an error document?
			if (results.name().localName=='osmError') {
		        dispatchEvent(new SaveCompleteEvent(SAVE_COMPLETED, false));
				diffUploadAPIError(results.status, results.message);
				return;
			}

            // response should be XML describing the progress
            
            for each( var update:XML in results.child("*") ) {
                var oldID:Number = Number(update.@old_id);
                var newID:Number = Number(update.@new_id);
                var version:uint = uint(update.@new_version);
                var type:String = update.name();

				if (newID==0) {
					// delete
	                if      (type == "node"    ) { killNode(oldID); }
	                else if (type == "way"     ) { killWay(oldID); }
	                else if (type == "relation") { killRelation(oldID); }
					
				} else {
					// create/update
	                if      (type == "node"    ) { renumberNode(oldID, newID, version); getNode(newID).markClean(); }
	                else if (type == "way"     ) { renumberWay(oldID, newID, version); getWay(newID).markClean(); }
	                else if (type == "relation") { renumberRelation(oldID, newID, version); getRelation(newID).markClean(); }
				}
            }

            dispatchEvent(new SaveCompleteEvent(SAVE_COMPLETED, true));
			freshenActiveChangeset();
            markClean(); // marks the connection clean. Pressing undo from this point on leads to unexpected results
            MainUndoStack.getGlobalStack().breakUndo(); // so, for now, break the undo stack
        }

		private function diffUploadIOError(event:FaultEvent):void {
			trace(event.fault);
			dispatchEvent(new MapEvent(MapEvent.ERROR, { message: "Couldn't upload data: "+event.fault.faultString } ));
			dispatchEvent(new SaveCompleteEvent(SAVE_COMPLETED, false));
		}

		private function diffUploadAPIError(status:String, message:String):void {
			var matches:Array;
			switch (status) {

				case '409 Conflict':
					if (message.match(/changeset/i)) { throwChangesetError(message); return; }
					matches=message.match(/mismatch.+had: (\d+) of (\w+) (\d+)/i);
					if (matches) { throwConflictError(findEntity(matches[2],matches[3]), Number(matches[1]), message); return; }
					break;
				
				case '410 Gone':
					matches=message.match(/The (\w+) with the id (\d+)/i);
					if (matches) { throwAlreadyDeletedError(findEntity(matches[1],matches[2]), message); return; }
					break;
				
				case '412 Precondition Failed':
					matches=message.match(/Node (\d+) is still used/i);
					if (matches) { throwInUseError(findEntity('Node',matches[1]), message); return; }
					matches=message.match(/relation (\d+) is used/i);
					if (matches) { throwInUseError(findEntity('Relation',matches[1]), message); return; }
					matches=message.match(/Way (\d+) still used/i);
					if (matches) { throwInUseError(findEntity('Way',matches[1]), message); return; }
					matches=message.match(/Cannot update (\w+) (\d+)/i);
					if (matches) { throwEntityError(findEntity(matches[1],matches[2]), message); return; }
					matches=message.match(/Relation with id (\d+)/i);
					if (matches) { throwEntityError(findEntity('Relation',matches[1]), message); return; }
					matches=message.match(/Way (\d+) requires the nodes/i);
					if (matches) { throwEntityError(findEntity('Way',matches[1]), message); return; }
					throwBugError(message); return;
				
				case '404 Not Found':
					throwBugError(message); return;
					
				case '400 Bad Request':
					matches=message.match(/Element (\w+)\/(\d+)/i);
					if (matches) { throwEntityError(findEntity(matches[1],matches[2]), message); return; }
					matches=message.match(/You tried to add \d+ nodes to way (\d+)/i);
					if (matches) { throwEntityError(findEntity('Way',matches[1]), message); return; }
					throwBugError(message); return;
			}

			// Not caught, so just throw a generic server error
			throwServerError(message);
		}

        private function addCreated(changeset:Changeset, getIDs:Function, get:Function, serialise:Function):XML {
            var create:XML = <create version="0.6"/>
            for each( var id:Number in getIDs() ) {
                var entity:Entity = get(id);
                if ( id >= 0 || entity.deleted )
                    continue;
                    
                var xml:XML = serialise(entity);
                xml.@changeset = changeset.id;
                create.appendChild(xml);
            }
            return create.hasComplexContent() ? create : <!-- blank create section -->;
        }

		private function addDeleted(changeset:Changeset, getIDs:Function, get:Function, serialise:Function, ifUnused:Boolean):XML {
            var del:XML = <delete version="0.6"/>
            if (ifUnused) del.@["if-unused"] = "true";
            for each( var id:Number in getIDs() ) {
                var entity:Entity = get(id);
                // creates are already included
                if ( id < 0 || !entity.deleted || entity.parentsLoaded==ifUnused)
                    continue;
                    
                var xml:XML = serialise(entity);
                xml.@changeset = changeset.id;
                del.appendChild(xml);
            }
            return del.hasComplexContent() ? del : <!-- blank delete section -->;
		}

        private function addModified(changeset:Changeset, getIDs:Function, get:Function, serialise:Function):XML {
            var modify:XML = <modify version="0.6"/>
            for each( var id:Number in getIDs() ) {
                var entity:Entity = get(id);
                // creates and deletes are already included
                if ( id < 0 || entity.deleted || !entity.isDirty )
                    continue;
                    
                var xml:XML = serialise(entity);
                xml.@changeset = changeset.id;
                modify.appendChild(xml);
            }
            return modify.hasComplexContent() ? modify : <!-- blank modify section -->;
        }

        private function serialiseNode(node:Node):XML {
            var xml:XML = serialiseEntityRoot(node); //<node/>
            serialiseEntityTags(node, xml);
            xml.@lat = node.lat;
            xml.@lon = node.lon;
            return xml;
        }

        private function serialiseWay(way:Way):XML {
            var xml:XML = serialiseEntityRoot(way); //<node/>
            serialiseEntityTags(way, xml);
            for ( var i:uint = 0; i < way.length; i++ ) {
                var nd:XML = <nd/>
                nd.@ref = way.getNode(i).id;
                xml.appendChild(nd);
            }
            return xml;
        }

        private function serialiseRelation(relation:Relation):XML {
            var xml:XML = serialiseEntityRoot(relation); //<node/>
            serialiseEntityTags(relation, xml);
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
        
		private function serialiseEntityRoot(entity:Object):XML {
			var xml:XML;
			if      (entity is Way     ) { xml = <way/> }
			else if (entity is Node    ) { xml = <node/> }
			else if (entity is Relation) { xml = <relation/> }
			xml.@id = entity.id;
			xml.@version = entity.version;
			return xml;
		}

        private function serialiseEntityTags(entity:Entity, xml:XML):void {
            xml.@id = entity.id;
            xml.@version = entity.version;
            for each( var tag:Tag in entity.getTagArray() ) {
              if (tag.key == 'created_by') {
                entity.setTag('created_by', null, MainUndoStack.getGlobalStack().addAction);
                continue;
              }
              var tagXML:XML = <tag/>
              tagXML.@k = tag.key;
              tagXML.@v = tag.value;
              xml.appendChild(tagXML);
            }
        }

        override public function fetchUserTraces(refresh:Boolean=false):void {
            if (traces_loaded && !refresh) {
              dispatchEvent(new Event(TRACES_LOADED));
            } else {
              sendOAuthGet(apiBaseURL+"user/gpx_files", tracesLoadComplete, errorOnMapLoad, mapLoadStatus); //needs error handlers
              dispatchEvent(new Event(LOAD_STARTED)); //specific to map or reusable?
            }
        }

		private function tracesLoadComplete(event:Event):void {
			var files:XML = new XML(URLLoader(event.target).data);
			for each(var traceData:XML in files.gpx_file) {
				var t:Trace = findTrace(traceData.@id);
				if (!t) { t=new Trace(this); addTrace(t); }
				t.fromXML(traceData);
			}
			traces_loaded = true;
			dispatchEvent(new Event(LOAD_COMPLETED));
			dispatchEvent(new Event(TRACES_LOADED));
		}

        override public function fetchTrace(id:Number, callback:Function):void {
            sendOAuthGet(apiBaseURL+"gpx/"+id+"/data.xml", 
				function(e:Event):void { 
            		dispatchEvent(new Event(LOAD_COMPLETED));
					callback(e);
				}, errorOnTraceLoad, mapLoadStatus); // needs error handlers
            dispatchEvent(new Event(LOAD_STARTED)); //specifc to map or reusable?
        }

        private function errorOnTraceLoad(event:Event):void {
            trace("Trace load error");
            dispatchEvent(new Event(LOAD_COMPLETED));
		}

        /** Fetch the history for the given entity. The callback function will be given an array of entities of that type, representing the different versions */
        override public function fetchHistory(entity:Entity, callback:Function):void {
            if (entity.id >= 0) {
              var request:URLRequest = new URLRequest(apiBaseURL + entity.getType() + "/" + entity.id + "/history");
              var loader:ExtendedURLLoader = new ExtendedURLLoader();
              loader.addEventListener(Event.COMPLETE, loadedHistory);
              loader.addEventListener(IOErrorEvent.IO_ERROR, errorOnMapLoad); //needs error handlers
              loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, mapLoadStatus);
              loader.info['callback'] = callback; //store the callback so we can use it later
              loader.load(request);
              dispatchEvent(new Event(LOAD_STARTED));
            } else {
              // objects created locally only have one state, their current one
              callback([entity]);
            }
        }

        private function loadedHistory(event:Event):void {
            var _xml:XML = new XML(ExtendedURLLoader(event.target).data);
            var results:Array = [];
            var dummyConn:Connection = new Connection("dummy", null, null);

            dispatchEvent(new Event(LOAD_COMPLETED));

            // only one type of entity should be returned, but this handles any

            for each(var nodeData:XML in _xml.node) {
                var newNode:Node = new Node(
                    dummyConn,
                    Number(nodeData.@id),
                    uint(nodeData.@version),
                    parseTags(nodeData.tag),
                    true,
                    Number(nodeData.@lat),
                    Number(nodeData.@lon),
                    Number(nodeData.@uid),
                    nodeData.@timestamp,
                    nodeData.@user
                    );
                newNode.lastChangeset=nodeData.@changeset;
                results.push(newNode);
            }

            for each(var wayData:XML in _xml.way) {
                var nodes:Array = [];
                for each(var nd:XML in wayData.nd) {
                  nodes.push(new Node(dummyConn,Number(nd.@ref), NaN, null, false, NaN, NaN));
                }
                var newWay:Way = new Way(
                    dummyConn,
                    Number(wayData.@id),
                    uint(wayData.@version),
                    parseTags(wayData.tag),
                    true,
                    nodes,
                    Number(wayData.@uid),
                    wayData.@timestamp,
                    wayData.@user
                    );
                newWay.lastChangeset=wayData.@changeset;
                results.push(newWay);
            }

            for each(var relData:XML in _xml.relation) {
                trace("relation history not implemented");
            }

            // use the callback we stored earlier, and pass it the results
            ExtendedURLLoader(event.target).info['callback'](results);
        }
	}
}
