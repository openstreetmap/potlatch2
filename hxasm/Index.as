package hxasm {
	public class Index extends enum {
		public static const __isenum : Boolean = true;
		public function Index( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static function Idx(v : int) : Index { return new Index("Idx",0,[v]); }
	}
}
