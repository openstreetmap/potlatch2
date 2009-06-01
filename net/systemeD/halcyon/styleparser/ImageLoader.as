package net.systemeD.halcyon.styleparser {

	/*
		=== ImageLoader ===

		This simply allows us to store a filename in the URLLoader object,
		so that the responder knows which image has just been loaded.

	*/

	import flash.events.*;
	import flash.net.*;

	public class ImageLoader extends URLLoader {
		public var filename:String;
	}
}