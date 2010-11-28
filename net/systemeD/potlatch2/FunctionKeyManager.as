package net.systemeD.potlatch2 {

	import mx.collections.ArrayCollection;
    import flash.net.SharedObject;
	import flash.events.EventDispatcher;
	import flash.events.Event;

	/* Still to do:
		- this is keyed by a 'name' value, e.g. 'background'/'Bing'. If the user renames the value (e.g. renames the 'Bing'
		  layer to 'Microsoft'), the mapping will be lost
		- the selectedItem call to getKeyFor generates one of those stupid "warning: unable to bind to property 
		  'name' on class 'Object' (class is not an IEventDispatcher)" binding errors
	*/

    public class FunctionKeyManager extends EventDispatcher {

        private static const GLOBAL_INSTANCE:FunctionKeyManager = new FunctionKeyManager();
        public static function instance():FunctionKeyManager { return GLOBAL_INSTANCE; }

		public static var fkeys:Array=['','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12','F13','F14','F15'];
		[Bindable(event="bogus")]
		public static var fkeysCollection:ArrayCollection=new ArrayCollection(fkeys);

		private var keys:Array=[];
		private var listeners:Object={};

		public function FunctionKeyManager() {
			for (var i:uint=1; i<16; i++) {
				if (SharedObject.getLocal("user_state").data['F'+i]) {
					keys[i]=SharedObject.getLocal("user_state").data['F'+i];
				}
			}
		}

		/* Register a function as the handler for all keypresses with that code (e.g. 'background') */

		public function registerListener(code:String,f:Function):void {
			listeners[code]=f;
		}
		
		/* Set the code (e.g. 'background') and value (e.g. 'Bing') associated with a key */

		public function setKey(fkey:uint, code:String, value:String):void {
			keys[fkey]={ code:code, value:value };
			var obj:SharedObject=SharedObject.getLocal("user_state");
			obj.setProperty('F'+fkey,{ code:code, value:value });
			obj.flush();
			dispatchEvent(new Event("key_changed"));
		}

		public function setKeyFromFString(key:String, code:String, value:String):void {
			if (key=='') {
				var oldKey:String=getKeyFor(code,value);
				keys[Number(oldKey.substr(1))]=null;
				var obj:SharedObject=SharedObject.getLocal("user_state");
				obj.setProperty(oldKey,null);
				obj.flush();
			} else {
				setKey(Number(key.substr(1)),code,value);
			}
		}

		/* Find what key, if any, is currently assigned to a given code and value */

		[Bindable(event="key_changed")]
		public function getKeyFor(code:String, value:String):String {
			for (var i:uint=1; i<16; i++) {
				if (keys[i] && keys[i].code==code && keys[i].value==value) { return 'F'+i; }
			}
			return '';
		}

		/* Dispatch function triggered by this key */
		
		public function handleKeypress(keycode:uint):Boolean {
			if (keycode<112 || keycode>126) { return false; }
			var fkey:uint=keycode-111;
			if (!keys[fkey]) { return false; }
			if (keys[fkey].value=='') { return false; }
			listeners[keys[fkey].code](keys[fkey].value);
			return true;
		}
		
	}
}
