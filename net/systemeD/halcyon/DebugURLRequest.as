package net.systemeD.halcyon {

	/*
		=== DebugURLRequest ===

		If this is running under a Flash debug player, this will make the URLRequest using POST 
		rather than GET - thereby preventing FP from caching it
		(see http://www.ultrashock.com/forums/actionscript/force-reload-files-only-using-as3-123408.html).
		
		Sadly we can't just subclass URLRequest, which is defined as final. So you need to create your 
		new DebugURLRequest, then refer to its .request property.

	*/

	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;

	public class DebugURLRequest {

		public var request:URLRequest;

		public function DebugURLRequest(url:String=null) {
			request=new URLRequest(url);
			if (Capabilities.isDebugger) {
				request.method=URLRequestMethod.POST;
				request.data=true;
			}
		}

	}

}
