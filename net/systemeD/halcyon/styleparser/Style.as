package net.systemeD.halcyon.styleparser {

	import flash.utils.ByteArray;
	import flash.net.*;
	import net.systemeD.halcyon.Globals;

	public class Style {

		public var merged:Boolean=false;
		public var edited:Boolean=false;		// true once a property has been set from a string
		public var sublayer:uint=5;

		// Return an exact copy of this object
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

		// Add properties from another object

		public function mergeWith(additional:Style):void {
			for each (var prop:String in properties) {
				if (additional[prop]) {
					this[prop]=additional[prop];
				}
			}
			this.merged=true;
		}

		// Getter (to be overridden) for property list

		public function get properties():Array {
			return [];
		}

		// Set property and cast as correct type (used in stylesheet imports)
		
		public function setPropertyFromString(k:String,v:*):Boolean {
			if (!this.hasOwnProperty(k)) { return false; }
			// ** almost certainly need to do more here, e.g. true|1|yes=Boolean true
			switch (typeof(this[k])) {
				case "number":	this[k]=Number(v) ; edited=true; return true;
				case "string":	this[k]=String(v) ; edited=true; return true;
				case "boolean":	this[k]=Boolean(v); edited=true; return true;
			}
			return false;
		}
	}
}
