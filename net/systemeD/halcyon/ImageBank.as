package net.systemeD.halcyon {
    import flash.events.*;
	import flash.display.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import nochump.util.zip.*;

	/*
		ImageBank stores and retrieves bitmap images.
		All images are internally stored as Loader.

		See blog.yoz.sk/2009/10/bitmap-bitmapdata-bytearray/ for a really useful conversion guide!
	*/

    public class ImageBank extends EventDispatcher{
		private var images:Object={};
		private var imagesRequested:uint=0;
		private var imagesReceived:uint=0;
		
		public static const IMAGES_LOADED:String="imagesLoaded";
		
		private static const GLOBAL_INSTANCE:ImageBank = new ImageBank();
		public static function getInstance():ImageBank { return GLOBAL_INSTANCE; }

		public function hasImage(name:String):Boolean {
			if (images[name]) return true;
			return false;
		}

		/* ==========================================================================================
		   Populate with images 
		   ========================================================================================== */

		public function loadImage(filename:String):void {
			if (images[filename]) return;
			imagesRequested++;

			var loader:Loader=new Loader();
			images[filename]=loader;
			var request:URLRequest=new URLRequest(filename);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,						loadedImage);
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS,			httpStatusHandler);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	securityErrorHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,				ioErrorHandler);
			loader.load(request);
		}

		private function loadedImage(event:Event):void {
			imageReceived();
		}
		private function httpStatusHandler(event:HTTPStatusEvent):void { }
		private function securityErrorHandler(event:SecurityErrorEvent):void { 
			trace("securityErrorEvent: "+event.target.url);
			imageReceived();
		}
		private function ioErrorHandler(event:IOErrorEvent):void { 
			trace("ioErrorEvent: "+event.target.url); 
			imageReceived();
		}
		private function imageReceived():void {
			imagesReceived++;
			if (imagesReceived==imagesRequested) { dispatchEvent(new Event(IMAGES_LOADED)); }
		}

		/* ==========================================================================================
		   Load from .zip file
		   ========================================================================================== */
		
		public function loadFromZip(filename:String, prefix:String=""):void {
			var urlstream:URLStream = new URLStream();
			urlstream.addEventListener(Event.COMPLETE, function(e:Event):void { zipReady(e,prefix); } );
			urlstream.load(new URLRequest(filename));
		}
		private function zipReady(event:Event, prefix:String):void {
			var zip:ZipFile = new ZipFile(URLStream(event.target));
			for (var i:uint=0; i<zip.entries.length; i++) {
				var fileref:ZipEntry = zip.entries[i];
				var data:ByteArray = zip.getInput(fileref);
				var loader:Loader=new Loader();
				images[prefix+fileref.name]=loader;
				loader.loadBytes(data);
			}
		}


		/* ==========================================================================================
		   Get images 
		   getAsDisplayObject(filename)
		   getAsBitmapData(filename)
		   getAsByteArray(filename)
		   ========================================================================================== */

		public function getAsDisplayObject(name:String):DisplayObject {
			/* If the image hasn't loaded yet, then add an EventListener for when it does. */
			if (getWidth(name)==0) {
				var loader:Loader = new Loader();
				images[name].contentLoaderInfo.addEventListener(Event.COMPLETE,
					function(e:Event):void { loaderReady(e, loader) });
				return loader;
			}
			/* Otherwise, create a new Bitmap, because just returning the raw Loader
		 	   (i.e. images[name]) would only allow it to be added to one parent. (The other 
			   way to do this would be by copying the bytes as loaderReady does.). */
			return new Bitmap(getAsBitmapData(name));
		}
		
		public function getOriginalDisplayObject(name:String):DisplayObject {
			/* But if we're going to clone it later, this'll work fine. */
			return images[name];
		}

		private function loaderReady(event:Event, loader:Loader):void {
			/* The file has loaded, so we can copy the data from there into our new Loader */
			var info:LoaderInfo = event.target as LoaderInfo;
			loader.loadBytes(info.bytes);
		}

		public function getAsBitmapData(name:String):BitmapData {
			var bitmapData:BitmapData=new BitmapData(getWidth(name), getHeight(name), true, 0xFFFFFF);
			bitmapData.draw(images[name]);
			return bitmapData;
		}
		
		public function getAsByteArray(name:String):ByteArray {
			return images[name].contentLoaderInfo.bytes;
		}

		/* ==========================================================================================
		   Get file information
		   ========================================================================================== */

		public function getWidth(name:String):int { 
			try { return images[name].contentLoaderInfo.width; }
			catch (error:Error) { } return 0;
		}

		public function getHeight(name:String):int { 
			try { return images[name].contentLoaderInfo.height; }
			catch (error:Error) { } return 0;
		}

	}
}