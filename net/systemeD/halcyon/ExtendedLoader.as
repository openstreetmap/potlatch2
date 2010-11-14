package net.systemeD.halcyon {

	/*
		=== ExtendedLoader ===

		This simply allows us to store arbitrary data (e.g. a filename) in the Loader object,
		so that the responder knows which image has just been loaded.

	*/

	import flash.events.*;
	import flash.net.*;
	import flash.display.*;

	public class ExtendedLoader extends Loader {
		public var info:Object=new Object();
	}

}