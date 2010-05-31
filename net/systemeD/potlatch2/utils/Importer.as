package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.ExtendedURLLoader;
	import flash.net.URLLoader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.net.*;

	import net.systemeD.halcyon.Globals;

	public class Importer {

		protected var container:Object;				// destination object for way/node/relations data
		protected var paint:MapPaint;				// destination sprite for WayUIs/NodeUIs

		public var files:Array=[];
		protected var filenames:Array;
		protected var filesloaded:uint=0;
		protected var callback:Function;
		protected var simplify:Boolean;

		public function Importer(container:*, paint:MapPaint, filenames:Array, simplify:Boolean) {
			Globals.vars.root.addDebug("starting importer"); 
			Globals.vars.root.addDebug("container is "+container);
			Globals.vars.root.addDebug("paint is "+paint);
			this.container = container;
			this.paint = paint;
			this.filenames=filenames;
			this.simplify=simplify;

			var sp:uint=0;
			for each (var fn:String in filenames) {
				Globals.vars.root.addDebug("requesting file "+fn); 

				var loader:ExtendedURLLoader = new ExtendedURLLoader();
				loader.info['file']=sp;
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE,						fileLoaded);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,		httpStatusHandler);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
				loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
				loader.load(new URLRequest(fn));
				sp++;
			}
		}
		
		protected function fileLoaded(e:Event):void {
			Globals.vars.root.addDebug("loaded file "+e.target.info['file']); 
			files[e.target.info['file']]=e.target.data;
			filesloaded++;
			if (filesloaded==filenames.length) { 
				doImport();
				paint.updateEntityUIs(container.getObjectsByBbox(paint.map.edge_l, paint.map.edge_r, paint.map.edge_t, paint.map.edge_b), false, false);
			}
		}
		
		protected function doImport():void {
		}

		protected function httpStatusHandler( event:HTTPStatusEvent ):void { Globals.vars.root.addDebug("httpstatusevent"); }
		protected function securityErrorHandler( event:SecurityErrorEvent ):void { Globals.vars.root.addDebug("securityerrorevent"); }
		protected function ioErrorHandler( event:IOErrorEvent ):void { Globals.vars.root.addDebug("ioerrorevent"); }

	}
}
