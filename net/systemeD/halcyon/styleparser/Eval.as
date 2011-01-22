package net.systemeD.halcyon.styleparser {

	/*
		=== Eval ===

		This serves as the EventListener for an eval rule and copes with subsequent invocations.

	*/

	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	import it.sephiroth.expr.CompiledExpression;
	import it.sephiroth.expr.Parser;
	import it.sephiroth.expr.Scanner;

	public class Eval extends Loader {

		private var swfclass:Class;

		public function Eval(s:String) {
			var scanner:Scanner=new Scanner(s);
			var parser:Parser=new Parser(scanner);
			var compiled:CompiledExpression=parser.parse();
			var swfdata:ByteArray=compiled.compile();

			this.contentLoaderInfo.addEventListener(Event.COMPLETE, swfLoaded, false, 0, true);
			this.loadBytes(swfdata, new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain)));
		}
		
		private function swfLoaded(event:Event):void {
			var info:LoaderInfo = event.target as LoaderInfo;
			swfclass=info.applicationDomain.getDefinition( "CompiledExpression" ) as Class;
			dispatchEvent(new Event("swf_loaded"));
		}
		
		public function exec(tags:Object):* {
			if (!swfclass) { return null; }
			var cp:Object=new swfclass();
			for (var k:String in tags) { cp[k]=tags[k]; }
			return cp.execute();
		}
	}
}