package net.systemeD.halcyon.styleparser {

	import flash.net.*;
    import flash.events.*;
	import net.systemeD.halcyon.connection.Entity;

    public class CSSTransform {

		private static const GLOBAL_INSTANCE:CSSTransform = new CSSTransform();
		public static function getInstance():CSSTransform { return GLOBAL_INSTANCE; }

		[Bindable] public var url:String='';
		private var ruleset:RuleSet;
		
		public function loadFromUrl(filename:String):void {
			url=filename;
			ruleset=new RuleSet(0,30,cssReady);
			ruleset.loadFromCSS(url);
		}

		public function clear():void {
			ruleset=null;
			url='';
		}

		private function cssReady():void {
		}
		
		public function run(entity:Entity,tags:Object):Object {
			if (ruleset) return ruleset.runInstructions(entity,tags);
			return tags;
		}

	}
}
