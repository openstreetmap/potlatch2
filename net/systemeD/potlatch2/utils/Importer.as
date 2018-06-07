package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.ExtendedURLLoader;
    import net.systemeD.halcyon.connection.*;
    import flash.net.URLLoader;
    import flash.display.LoaderInfo;
    import flash.events.*;
    import flash.net.*;
    import flash.utils.ByteArray;
    import nochump.util.zip.*;

    public class Importer {

        protected var connection:Connection;    // destination connection for way/node/relations data
        protected var map:Map;                  // map being used - used only in Simplify calls

        public var files:Array=[];
        protected var filenames:Array;            // array of filenames _or_ FileReference objects
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
            filenames.forEach(function(file:String, index:int, array:Array):void {
                trace("requesting file "+index);
                var loader:URLLoader = new URLLoader();
                loader.dataFormat=URLLoaderDataFormat.BINARY;
                loader.addEventListener(Event.COMPLETE,function(e:Event):void { fileLoaded(e,index); });
                if (callback!=null) {
                    loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,    securityErrorHandler);
                    loader.addEventListener(IOErrorEvent.IO_ERROR,                ioErrorHandler);
                }
                loader.load(new URLRequest(file));
            });
        }

        public function importFromLocalFile(file:FileReference):void {
            filenames=['local'];
            file.addEventListener(Event.COMPLETE, fileLoaded);
            file.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler);
            file.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityErrorHandler);
            file.load();
        }

        protected function fileLoaded(e:Event,filenum:uint=0):void {
            var rawData:ByteArray=e.target.data;
            var firstFour:ByteArray=new ByteArray();
            rawData.readBytes(firstFour,0,4);
            rawData.position=0;
            
            if (firstFour.toString()=="PK"+String.fromCharCode(3)+String.fromCharCode(4)) {
                // Zip file (we assume there'll only be one of these...)
                var zip:ZipFile = new ZipFile(rawData);
                for (var i:uint=0; i<zip.entries.length; i++) {
                    filenames[i]=zip.entries[i].name;
                    files[i]=zip.getInput(zip.entries[i]);
                    filesloaded++;
                }
                doImport();
            } else {
                // Standard file
                files[filenum]=rawData;
                filesloaded++;
                trace("loaded file "+filenum+" ("+filesloaded+"/"+filenames.length+")"); 
                if (filesloaded==filenames.length) { doImport(); }
            }
        }

        protected function finish():void {
            connection.registerPOINodes();
            if (callback!=null) { callback(connection,options,true); }
        }

        protected function getFileByName(regex:RegExp):* {
            for (var i:uint=0; i<filenames.length; i++) {
                if (filenames[i].match(regex)) { return files[i]; }
            }
            return null;
        }

        protected function doImport():void {
        }

        protected function securityErrorHandler( event:SecurityErrorEvent ):void { callback(connection,options,false,"You don't have permission to open that file."); }
        protected function ioErrorHandler( event:IOErrorEvent ):void { callback(connection,options,false,"The file could not be loaded."); }

    }
}
