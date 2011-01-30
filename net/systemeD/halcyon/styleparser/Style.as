package net.systemeD.halcyon.styleparser {

	import flash.utils.ByteArray;
	import flash.net.*;

	/** A Style is a set of graphic properties (e.g. stroke colour and width, casing colour and width, 
		font and text size), typically derived from a MapCSS descriptor. This is the base class
		for particular style groupings such as ShapeStyle and PointStyle.
		
		@see net.systemeD.halcyon.styleparser.StyleList
		@see net.systemeD.halcyon.styleparser.StyleChooser
	*/

	public class Style {

		/** Has this style had another style merged into it?
			(When styles cascade, then we need to merge the first style with any subsequent styles that apply.) */
		public var merged:Boolean=false;

		/** Is the style active (properties have been set)? */
		public var edited:Boolean=false;

		/** The sublayer is the z-index property _within_ an OSM layer.
			It enables (for example) trunk roads to be rendered above primary roads within that OSM layer, 
			and so on. "OSM layer 1 / sublayer 5" will render above "OSM layer 1 / sublayer 4", but below 
			"OSM layer 2 / sublayer 4". */
		public var sublayer:Number=5;

		/** Does this style permit mouse interaction?
			(Some styling, such as P2's back-level yellow highlight for selected ways, should not respond 
			to mouse events.) */
		public var interactive:Boolean=true;	

		/** Compiled SWFs for each eval. We keep it here, not in the property itself, so that we can retain typing for each property. */
		public var evals:Object={};
		
		/** Make an exact copy of an object.
			Used when merging cascading styles. (FIXME: this needs some benchmarking - it may be quicker to simply iterate over .properties, 
			copying each one. */
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

		/** Merge two Style objects. */
		public function mergeWith(additional:Style):void {
			for each (var prop:String in properties) {
				if (additional[prop]) {
					this[prop]=additional[prop];
				}
			}
			this.merged=true;
		}

		/** Properties getter, to be overridden. */
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
		
		/** Run all evals for this Style over the supplied tags.
			If, for example, the stylesheet contains width=eval('_width+2'), then this will set Style.width to 7. */
		public function runEvals(tags:Object):void {
			for (var k:String in evals) {
				// ** Do we need to do typing here?
				this[k]=evals[k].exec(tags);
			}
		}

		/** Set a property, casting as correct type. */
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

		/** Summarise Style as String - for debugging. */
		public function toString():String {
			var str:String='';
            for each (var k:String in this.properties) {
				if (this.hasOwnProperty(k)) { str+=k+"="+this[k]+"; "; }
			}
			return str;
        }
	}
}
