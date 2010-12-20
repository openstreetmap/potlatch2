package net.systemeD.halcyon.styleparser {

	import flash.utils.ByteArray;
	import flash.net.*;

	public class Style {

		/** Has this style had another style merged into it? */
		public var merged:Boolean=false;
		/** true once a property has been set from a string */
		public var edited:Boolean=false;
		/** Z-index */
		public var sublayer:Number=5;
		/** Should entities with this style respond to interaction like mouse movement? */
		public var interactive:Boolean=true;	
		/** Compiled SWFs for each eval. We keep it here, not in the property itself, so that we can retain typing for each property */
		public var evals:Object={};
		/** Return an exact copy of this object */
		// ** this needs some benchmarking - may be quicker to iterate over .properties, copying each one

		public function deepCopy():* {
			registerClassAlias("net.systemeD.halcyon.styleparser.ShapeStyle",ShapeStyle);
			registerClassAlias("net.systemeD.halcyon.styleparser.TextStyle",TextStyle);
			registerClassAlias("net.systemeD.halcyon.styleparser.PointStyle",PointStyle);
			registerClassAlias("net.systemeD.halcyon.styleparser.ShieldStyle",ShieldStyle);
			registerClassAlias("net.systemeD.halcyon.styleparser.InstructionStyle",InstructionStyle);
			var a:ByteArray=new ByteArray();
			a.writeObject(this);
			a.position=0;
			return (a.readObject());
		}

		/** Add properties from another object */

		public function mergeWith(additional:Style):void {
			for each (var prop:String in properties) {
				if (additional[prop]) {
					this[prop]=additional[prop];
				}
			}
			this.merged=true;
		}

		/** Getters (to be overridden) */

		public function get properties():Array {
			return [];
		}
		
		/** Does this style require anything to be drawn? (To be overridden.) */
		public function get drawn():Boolean {
			return false;
		}
		
		/** Are there any eval functions defined? */
		public function hasEvals():Boolean {
			for (var k:String in evals) { return true; }
			return false;
		}
		
		/** If the stylesheet has width=eval('_width+2'), then this will set Style.width to 7 (say). */
		public function runEvals(tags:Object):void {
			for (var k:String in evals) {
				// ** Do we need to do typing here?
				this[k]=evals[k].exec(tags);
				
				
				//    
			}
		}

		/** Set property and cast as correct type (used in stylesheet imports)*/
		
		public function setPropertyFromString(k:String,v:*):Boolean {
			if (!this.hasOwnProperty(k)) { return false; }
			if (v is Eval) { evals[k]=v; v=1; }

			// Arrays don't return a proper typeof, so check manually
			// Note that undefined class variables always have typeof=object,
			// so we need to declare them as empty arrays (cf ShapeStyle)
			if (this[k] is Array) {
				// Split comma-separated array and coerce as numbers
				this[k]=v.split(',').map(function(el:Object,index:int,array:Array):Number { return Number(el); });
				edited=true; return true;
			}

			// Check for other object types
			switch (typeof(this[k])) {
				case "number":	this[k]=Number(v) ; edited=true; return true;
				case "object":	// **for now, just assume objects are undefined strings
								// We'll probably need to fix this in future if we have more complex
								// properties
				case "string":	this[k]=String(v) ; edited=true; return true;
				case "boolean":	this[k]=Boolean(v); edited=true; return true;
			}
			return false;
		}

		/** Serialise properties to a string. */
		public function toString():String {
			var str:String='';
            for each (var k:String in this.properties) {
				if (this.hasOwnProperty(k)) { str+=k+"="+this[k]+"; "; }
			}
			return str;
        }
	}
}
