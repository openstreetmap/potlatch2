package hxasm {

	public class FieldKind extends enum {
		public static const __isenum : Boolean = true;
		public function FieldKind( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static function FMethod(type : Index, isOverride : * = null, isFinal : * = null) : FieldKind { return new FieldKind("FMethod",1,[type,isOverride,isFinal]); }
		public static function FVar(type : Index = null, _const : * = null) : FieldKind { return new FieldKind("FVar",0,[type,_const]); }
	}
}
