package hxasm {
	public class Operation extends enum {
		public static const __isenum : Boolean = true;
		public function Operation( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static var OpAdd : Operation = new Operation("OpAdd",6);
		public static var OpAnd : Operation = new Operation("OpAnd",14);
		public static var OpAs : Operation = new Operation("OpAs",0);
		public static var OpBitNot : Operation = new Operation("OpBitNot",5);
		public static var OpDecr : Operation = new Operation("OpDecr",3);
		public static var OpDiv : Operation = new Operation("OpDiv",9);
		public static var OpEq : Operation = new Operation("OpEq",17);
		public static var OpGt : Operation = new Operation("OpGt",21);
		public static var OpGte : Operation = new Operation("OpGte",22);
		public static var OpIAdd : Operation = new Operation("OpIAdd",28);
		public static var OpIDecr : Operation = new Operation("OpIDecr",26);
		public static var OpIIncr : Operation = new Operation("OpIIncr",25);
		public static var OpIMul : Operation = new Operation("OpIMul",30);
		public static var OpINeg : Operation = new Operation("OpINeg",27);
		public static var OpISub : Operation = new Operation("OpISub",29);
		public static var OpIn : Operation = new Operation("OpIn",24);
		public static var OpIncr : Operation = new Operation("OpIncr",2);
		public static var OpIs : Operation = new Operation("OpIs",23);
		public static var OpLt : Operation = new Operation("OpLt",19);
		public static var OpLte : Operation = new Operation("OpLte",20);
		public static var OpMod : Operation = new Operation("OpMod",10);
		public static var OpMul : Operation = new Operation("OpMul",8);
		public static var OpNeg : Operation = new Operation("OpNeg",1);
		public static var OpNot : Operation = new Operation("OpNot",4);
		public static var OpOr : Operation = new Operation("OpOr",15);
		public static var OpPhysEq : Operation = new Operation("OpPhysEq",18);
		public static var OpShl : Operation = new Operation("OpShl",11);
		public static var OpShr : Operation = new Operation("OpShr",12);
		public static var OpSub : Operation = new Operation("OpSub",7);
		public static var OpUShr : Operation = new Operation("OpUShr",13);
		public static var OpXor : Operation = new Operation("OpXor",16);
	}
}
