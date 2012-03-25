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
		protected var filenames:Array;			// array of filenames _or_ FileReference objects
		protected var filesloaded:uint=0;
		protected var callback:Function;
		protected var simplify:Boolean;
		protected var options:Object;

		public function Importer(connection:Connection, map:Map, callback:Function, simplify:Boolean, options:Object) {
			this.connection = connection;
			this.map = map;
			this.callback=callback;
			this.simplify=simplify;
			this.options=options;
		}
		
		public function importFromRemoteFiles(filenames:Array):void {
			this.filenames=filenames;
			// Use forEach to avoid closure problem (http://stackoverflow.com/questions/422784/how-to-fix-closure-problem-in-actionscript-3-as3#3971784)
			filenames.forEach(function(file:*, index:int, array:Array):void {
				trace("requesting file "+index);
				var loader:URLLoader = new URLLoader();
				loader.dataFormat=URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE,function(e:Event):void { fileLoaded(e,index); });
				if (callback!=null) {
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
					loader.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
				}
				loader.load(new URLRequest(file));
			});
		}
		
		public function importFromLocalFiles():void {
			// ** FIXME: if it's a zip, do something clever
		}
		
		protected function fileLoaded(e:Event,filenum:uint):void {
			files[filenum]=e.target.data;
			filesloaded++;
			trace("loaded file "+filenum+" ("+filesloaded+"/"+filenames.length+")"); 
			if (filesloaded==filenames.length) {
                var action:CompositeUndoableAction = new CompositeUndoableAction("Import layer "+connection.name);
				doImport(action.push);
				action.doAction(); // just do it, don't add to undo stack
				if (callback!=null) { callback(connection,options,true); }
			}
		}
		
		protected function doImport(push:Function):void {
		}

		protected function securityErrorHandler( event:SecurityErrorEvent ):void { callback(connection,options,false,"You don't have permission to open that file."); }
		protected function ioErrorHandler( event:IOErrorEvent ):void { callback(connection,options,false,"The file could not be loaded."); }

	}
}
