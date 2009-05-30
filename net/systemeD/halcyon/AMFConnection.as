package net.systemeD.halcyon {

	import flash.system.Security;
	import flash.net.*;

	public class AMFConnection extends Connection {

		public var readConnection:NetConnection;
		public var writeConnection:NetConnection;
		
		// ------------------------------------------------------------
		// Constructor for new AMFConnection

		public function AMFConnection(readURL:String,writeURL:String,policyURL:String='') {

			if (policyURL!='') { Security.loadPolicyFile(policyURL); }

			readConnection=new NetConnection();
			readConnection.objectEncoding = flash.net.ObjectEncoding.AMF0;
			readConnection.connect(readURL);
			
			writeConnection=new NetConnection();
			writeConnection.objectEncoding = flash.net.ObjectEncoding.AMF0;
			writeConnection.connect(writeURL);
			
		}

		public function getEnvironment(responder:Responder):void {
			readConnection.call("getpresets",responder,"en");
		}
		
		public function getBbox(left:Number,right:Number,
								top:Number,bottom:Number,
								responder:Responder):void {
			readConnection.call("whichways",responder,left,bottom,right,top);
		}

		public function getWay(id:uint,responder:Responder):void {
			readConnection.call("getway",responder,id);
		}

	}
}
