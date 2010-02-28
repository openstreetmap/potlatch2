package net.systemeD.potlatch2.utils {

	import flash.events.*;
	import flash.net.*;
	import flash.utils.ByteArray;

    import net.systemeD.halcyon.ExtendedURLLoader;

	public class CachedDataLoader {

        private static var allData:Object = {};
        private static var requestsMade:Object = {};
        
		public static function loadData(url:String, onLoadHandler:Function = null):ByteArray {
		    var data:ByteArray = allData[url];
		    if ( data != null )
		        return data;
		    
		    var requests:Array = requestsMade[url];
		    if ( requests == null ) {
		        requests = [];
		        requestsMade[url] = requests;

       		    var loader:ExtendedURLLoader = new ExtendedURLLoader();
    		    loader.info = url;
                loader.addEventListener(Event.COMPLETE, imageLoaded);
                loader.dataFormat = URLLoaderDataFormat.BINARY;
                loader.load(new URLRequest(url));
		    }
		    requests.push(onLoadHandler);
		    
		    return allData[url];
		}

        private static function imageLoaded(event:Event):void {
            var loader:ExtendedURLLoader = ExtendedURLLoader(event.target);
            var url:String = loader.info as String;
            allData[url] = loader.data;
            
            var requests:Array = requestsMade[url];
            for each ( var handler:Function in requests ) {
                handler(url, loader.data);
            }
            
            delete requestsMade[url];
        }
	}
}
