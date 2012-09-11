package net.systemeD.halcyon.connection {

    import flash.net.*;
    import flash.events.*;
    import net.systemeD.halcyon.AttentionEvent;

	public class StatusFetcher {

		/* Class to fetch the status for newly loaded objects.
		   Not currently functional.
		*/

		public var _url:String;
		public var conn:Connection;
		
		private static var STATUSES:Array=["no","partial","unsure",''];
		
		public function StatusFetcher(url:String, connection:Connection) {
			_url=url;
			conn=connection;
		}

		public function fetch(entities:Array):void {
			if (entities.length==0) return;
			// Create URL request
            var vars:URLVariables = new URLVariables();
			vars.nodes='';
			vars.ways='';
			vars.relations='';
			for each (var entity:Entity in entities) {
				if (entity is Node) vars.nodes+=entity.id+",";
				else if (entity is Way) vars.ways+=entity.id+",";
				else if (entity is Relation) vars.relations+=entity.id+",";
			}
			if (vars.ways.substr(vars.ways.length-1,1)==',') vars.ways=vars.ways.substr(0,vars.ways.length-1);
			if (vars.nodes.substr(vars.nodes.length-1,1)==',') vars.nodes=vars.nodes.substr(0,vars.nodes.length-1);
			if (vars.relations.substr(vars.relations.length-1,1)==',') vars.relations=vars.relations.substr(0,vars.relations.length-1);
            var request:URLRequest = new URLRequest(_url);
            request.data = vars;
			request.method = "POST";

			// Make request
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loadedFetch);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorOnFetchLoad);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, fetchLoadStatus);
			loader.load(request);
		}
		
		private function loadedFetch(event:Event):void {
			var xml:XML=new XML(URLLoader(event.target).data);
			var entity:Entity, status:String;

			for each (var exml:XML in xml.*) {
				switch (exml.name().localName) {
					case "way":		entity=conn.getWay(exml.@id); break;
					case "relation":entity=conn.getRelation(exml.@id); break;
					case "node":	entity=conn.getNode(exml.@id); break;
				}

				// FIXME: needs some code to parse the XML, and set 'status' accordingly
				entity.setStatus(status);
			}
		}

        private function errorOnFetchLoad(event:Event):void {
			conn.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Couldn't load status information"));
        }
        private function fetchLoadStatus(event:HTTPStatusEvent):void { }

	}
}
