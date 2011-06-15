package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.ExtendedURLLoader;
    import net.systemeD.halcyon.connection.*;
	import flash.net.URLLoader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.net.*;

	public class Importer {

        protected var connection:Connection;    // destination connection for way/node/relations data
        protected var map:Map;                  // map being used - used only in Simplify calls

		public var files:Array=[];
		protected var filenames:Array;
		protected var filesloaded:uint=0;
		protected var callback:Function;
		protected var simplify:Boolean;

		public function Importer(connection:Connection, map:Map, filenames:Array, callback:Function, simplify:Boolean) {
			this.connection = connection;
			this.map = map;
			this.filenames=filenames;
			this.callback=callback;
			this.simplify=simplify;

			// Use forEach to avoid closure problem (http://stackoverflow.com/questions/422784/how-to-fix-closure-problem-in-actionscript-3-as3#3971784)
			filenames.forEach(function(fn:String, index:int, array:Array):void {
				trace("requesting file "+index);
				var request:URLRequest = new URLRequest(fn);
				var loader:URLLoader = new URLLoader();
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE,function(e:Event):void { fileLoaded(e,index); });
				if (callback!=null) {
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
				}
				loader.load(request);
			});
		}
		
		protected function fileLoaded(e:Event,filenum:uint):void {
			trace("loaded file "+filenum); 
			files[filenum]=e.target.data;
			filesloaded++;
			if (filesloaded==filenames.length) {
                var action:CompositeUndoableAction = new CompositeUndoableAction("Import layer "+connection.name);
				doImport(action.push);
				action.doAction(); // just do it, don't add to undo stack
				if (callback!=null) { callback(true); }
			}
		}
		
		protected function doImport(push:Function):void {
		}

		protected function securityErrorHandler( event:SecurityErrorEvent ):void { callback(false,"You don't have permission to open that file."); }
		protected function ioErrorHandler( event:IOErrorEvent ):void { callback(false,"The file could not be loaded."); }

	}
}
