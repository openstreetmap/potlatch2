package net.systemeD.potlatch2.utils {

	import flash.events.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import mx.graphics.codec.PNGEncoder;

    import net.systemeD.halcyon.ExtendedURLLoader;
	import net.systemeD.halcyon.DebugURLRequest;

	public class CachedDataLoader {

        private static var allData:Object = {};
        private static var requestsMade:Object = {};
        private static var missingImage:ByteArray = null;
        
		public static function loadData(url:String, onLoadHandler:Function = null):ByteArray {
		    var data:ByteArray = allData[url];
		    if ( data != null )
		        return data;
		    
		    var requests:Array = requestsMade[url];
		    if ( requests == null ) {
		        requests = [];
		        requestsMade[url] = requests;

				var request:DebugURLRequest = new DebugURLRequest(url);
       		    var loader:ExtendedURLLoader = new ExtendedURLLoader();
    		    loader.info = url;
                loader.addEventListener(Event.COMPLETE, imageLoaded);
                loader.addEventListener(IOErrorEvent.IO_ERROR, imageLoadFailed);
                loader.dataFormat = URLLoaderDataFormat.BINARY;
                loader.load(request.request);
		    }
		    requests.push(onLoadHandler);
		    
		    return allData[url];
		}

        private static function imageLoaded(event:Event):void {
            var loader:ExtendedURLLoader = ExtendedURLLoader(event.target);
            var url:String = loader.info as String;
            allData[url] = loader.data;
            dispatchEvents(url);
        }
        
        private static function imageLoadFailed(event:Event):void {
            var loader:ExtendedURLLoader = ExtendedURLLoader(event.target);
            var url:String = loader.info as String;
            
            allData[url] = getMissingImage();
            dispatchEvents(url);
        }
        
        private static function dispatchEvents(url:String):void {
            var requests:Array = requestsMade[url];
            for each ( var handler:Function in requests ) {
                handler(url, allData[url]);
            }
            
            delete requestsMade[url];
        }
        
        private static function getMissingImage():ByteArray {
            if ( missingImage == null ) {
                var bitmap:BitmapData = new BitmapData(24, 24, false);
                for ( var i:uint = 0; i < 24; i++ ) {
                    bitmap.setPixel(i, i, 0xff0000);
                    bitmap.setPixel(23-i, i, 0xff0000);
                }
                missingImage = new PNGEncoder().encode(bitmap);
            }
            return missingImage;
        }
	}
}
