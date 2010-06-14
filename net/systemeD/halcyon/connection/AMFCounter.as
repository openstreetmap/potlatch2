package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.events.Event;
	
	public class AMFCounter extends EventDispatcher {
		private var requests:Object;
		public var count:uint;
		public var eventList:Array;
		private var connection:Connection;
		
		public function AMFCounter(conn:Connection) {
			requests={};
			count=0;
			eventList=[];
			connection=conn;
		}
		
		public function addEvent(e:*):void {
			eventList.push(e);
		}
		
		public function addRelationRequest(id:Number):void {
			addRequest(id+"rel");
		}
		public function addWayRequest(id:Number):void {
			addRequest(id+"way");
		}
		private function addRequest(n:String):Boolean {
			if (requests[n]) { return false; }
			requests[n]=true;
			count++;
			return true;
		}
		
		public function removeRequest(n:String):Boolean {
			if (!requests[n]) { return false; }
			delete requests[n];
			count--; if (count==0) { sendEvents(); }
			return true;
		}
		
		private function sendEvents():void {
			for each (var e:* in eventList) {
				connection.dispatchEvent(e);
			}
			this.eventList=[];
		}
	}
}