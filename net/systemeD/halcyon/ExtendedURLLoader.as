package net.systemeD.halcyon {

	/*
		=== ExtendedURLLoader ===

		This simply allows us to store arbitrary data (e.g. a filename) in the URLLoader object,
		so that the responder knows which image has just been loaded.

	*/

	import flash.events.*;
	import flash.net.*;
	import flash.display.*;

	public class ExtendedURLLoader extends URLLoader {
		public var info:Object=new Object();
	}

}