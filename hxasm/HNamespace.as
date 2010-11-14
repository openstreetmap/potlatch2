package hxasm {

	public class HNamespace extends enum {
		public static const __isenum : Boolean = true;
		public function HNamespace( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static function NNamespace(ns : Index) : HNamespace { return new HNamespace("Namespace",1,[ns]); }
		public static function NPublic(id : Index = null) : HNamespace { return new HNamespace("NPublic",0,[id]); }
	}
}
