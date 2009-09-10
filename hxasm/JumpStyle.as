package hxasm {
	public class JumpStyle extends enum {
		public static const __isenum : Boolean = true;
		public function JumpStyle( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static var JAlways : JumpStyle = new JumpStyle("JAlways",4);
		public static var JEq : JumpStyle = new JumpStyle("JEq",7);
		public static var JFalse : JumpStyle = new JumpStyle("JFalse",6);
		public static var JGt : JumpStyle = new JumpStyle("JGt",11);
		public static var JGte : JumpStyle = new JumpStyle("JGte",12);
		public static var JLt : JumpStyle = new JumpStyle("JLt",9);
		public static var JLte : JumpStyle = new JumpStyle("JLte",10);
		public static var JNeq : JumpStyle = new JumpStyle("JNeq",8);
		public static var JNotGt : JumpStyle = new JumpStyle("JNotGt",2);
		public static var JNotGte : JumpStyle = new JumpStyle("JNotGte",3);
		public static var JNotLt : JumpStyle = new JumpStyle("JNotLt",0);
		public static var JNotLte : JumpStyle = new JumpStyle("JNotLte",1);
		public static var JPhysEq : JumpStyle = new JumpStyle("JPhysEq",13);
		public static var JPhysNeq : JumpStyle = new JumpStyle("JPhysNeq",14);
		public static var JTrue : JumpStyle = new JumpStyle("JTrue",5);
	}
}
