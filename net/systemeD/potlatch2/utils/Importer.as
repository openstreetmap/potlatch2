package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.ExtendedURLLoader;
	import net.systemeD.halcyon.DebugURLRequest;
    import net.systemeD.halcyon.connection.*;
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

		public function Importer(container:*, paint:MapPaint, filenames:Array, callback:Function, simplify:Boolean) {
			Globals.vars.root.addDebug("starting importer"); 
			Globals.vars.root.addDebug("container is "+container);
			Globals.vars.root.addDebug("paint is "+paint);
			this.container = container;
			this.paint = paint;
			this.filenames=filenames;
			this.callback=callback;
			this.simplify=simplify;

			var sp:uint=0;
			for each (var fn:String in filenames) {
				var thissp:uint=sp;		// scope within this block for the URLLoader 'complete' closure
				Globals.vars.root.addDebug("requesting file "+fn);
				var request:DebugURLRequest = new DebugURLRequest(fn);
				var loader:URLLoader = new URLLoader();
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE,function(e:Event):void { fileLoaded(e,thissp); });
				if (callback!=null) {
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
				}
				loader.load(request.request);
				sp++;
			}
		}
		
		protected function fileLoaded(e:Event,filenum:uint):void {
			Globals.vars.root.addDebug("loaded file "+filenum); 
			files[filenum]=e.target.data;
			filesloaded++;
			if (filesloaded==filenames.length) { 
				doImport();
				paint.updateEntityUIs(container.getObjectsByBbox(paint.map.edge_l, paint.map.edge_r, paint.map.edge_t, paint.map.edge_b), false, false);
				if (callback!=null) { callback(true); }
			}
		}
		
		protected function doImport():void {
		}

		protected function securityErrorHandler( event:SecurityErrorEvent ):void { callback(false,"You don't have permission to open that file."); }
		protected function ioErrorHandler( event:IOErrorEvent ):void { callback(false,"The file could not be loaded."); }

	}
}
