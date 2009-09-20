package net.systemeD.halcyon {

	/*
		=== ImageLoader ===

		This simply allows us to store a filename in the URLLoader object,
		so that the responder knows which image has just been loaded.

	*/

	import flash.events.*;
	import flash.net.*;
	import flash.display.*;

	public class ImageURLLoader extends URLLoader {
		public var filename:*;
	}

}