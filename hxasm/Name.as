package hxasm {

	public class Name extends enum {
		public static const __isenum : Boolean = true;
		public function Name( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static function NMultiNameLate(nset : Index) : Name { return new Name("NMultiNameLate",1,[nset]); }
		public static function NName(name : Index, namespace : Index) : Name { return new Name("NName",0,[name,namespace]); }
	}
}
