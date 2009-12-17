package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.ExtendedURLLoader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.net.*;

	import net.systemeD.halcyon.Globals;

	public class Importer {

		protected var map:Map;
		protected var files:Array=[];
		protected var filenames:Array;
		protected var filesloaded:uint=0;

		public function Importer(map:Map, filenames:Array) {
			Globals.vars.root.addDebug("starting importer"); 
			this.map = map;
			this.filenames=filenames;

			var sp:uint=0;
			for each (var fn:String in filenames) {
				Globals.vars.root.addDebug("requesting file "+fn); 

				var loader:ExtendedURLLoader = new ExtendedURLLoader();
				loader.info['file']=sp;
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE,						fileLoaded,				false, 0, true);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler,		false, 0, true);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler,	false, 0, true);
				loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler,			false, 0, true);
				loader.load(new URLRequest(fn));
				sp++;
			}
		}
		
		protected function fileLoaded(e:Event):void {
			Globals.vars.root.addDebug("loaded file "+e.target.info['file']); 
			files[e.target.info['file']]=e.target.data;
			filesloaded++;
			if (filesloaded==filenames.length) { doImport(); }
		}
		
		protected function doImport():void { }

		protected function httpStatusHandler( event:HTTPStatusEvent ):void { }
		protected function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		protected function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }

	}
}
