package hxasm {

	public class OpCode extends enum {
		public static const __isenum : Boolean = true;
		public function OpCode( t : String, index : int, p : Array = null ) : void { this.tag = t; this.index = index; this.params = p; }
		public static function OArray(nvalues : int) : OpCode { return new OpCode("OArray",45,[nvalues]); }
		public static var OAsAny : OpCode = new OpCode("OAsAny",73);
		public static var OAsObject : OpCode = new OpCode("OAsObject",76);
		public static var OAsString : OpCode = new OpCode("OAsString",74);
		public static function OAsType(t : Index) : OpCode { return new OpCode("OAsType",75,[t]); }
		public static var OBreakPoint : OpCode = new OpCode("OBreakPoint",0);
		public static function OBreakPointLine(n : int) : OpCode { return new OpCode("OBreakPointLine",89,[n]); }
		public static function OByte(byte : int) : OpCode { return new OpCode("OByte",92,[byte]); }
		public static function OCallMethod(slot : int, nargs : int) : OpCode { return new OpCode("OCallMethod",33,[slot,nargs]); }
		public static function OCallPropLex(name : Index, nargs : int) : OpCode { return new OpCode("OCallPropLex",41,[name,nargs]); }
		public static function OCallPropVoid(name : Index, nargs : int) : OpCode { return new OpCode("OCallPropVoid",43,[name,nargs]); }
		public static function OCallProperty(name : Index, nargs : int) : OpCode { return new OpCode("OCallProperty",36,[name,nargs]); }
		public static function OCallStack(nargs : int) : OpCode { return new OpCode("OCallStack",31,[nargs]); }
		public static function OCallStatic(meth : Index, nargs : int) : OpCode { return new OpCode("OCallStatic",34,[meth,nargs]); }
		public static function OCallSuper(name : Index, nargs : int) : OpCode { return new OpCode("OCallSuper",35,[name,nargs]); }
		public static function OCallSuperVoid(name : Index, nargs : int) : OpCode { return new OpCode("OCallSuperVoid",42,[name,nargs]); }
		public static function OCast(t : Index) : OpCode { return new OpCode("OCast",72,[t]); }
		public static function OCatch(c : int) : OpCode { return new OpCode("OCatch",48,[c]); }
		public static var OCheckIsXml : OpCode = new OpCode("OCheckIsXml",71);
		public static function OClassDef(c : Index) : OpCode { return new OpCode("OClassDef",47,[c]); }
		public static function OConstruct(nargs : int) : OpCode { return new OpCode("OConstruct",32,[nargs]); }
		public static function OConstructProperty(name : Index, nargs : int) : OpCode { return new OpCode("OConstructProperty",40,[name,nargs]); }
		public static function OConstructSuper(nargs : int) : OpCode { return new OpCode("OConstructSuper",39,[nargs]); }
		public static function ODebugFile(file : Index) : OpCode { return new OpCode("ODebugFile",88,[file]); }
		public static function ODebugLine(line : int) : OpCode { return new OpCode("ODebugLine",87,[line]); }
		public static function ODebugReg(name : Index, r : int, line : int) : OpCode { return new OpCode("ODebugReg",86,[name,r,line]); }
		public static function ODecrIReg(r : int) : OpCode { return new OpCode("ODecrIReg",83,[r]); }
		public static function ODecrReg(r : int) : OpCode { return new OpCode("ODecrReg",78,[r]); }
		public static function ODeleteProp(p : Index) : OpCode { return new OpCode("ODeleteProp",60,[p]); }
		public static var ODup : OpCode = new OpCode("ODup",22);
		public static var OFalse : OpCode = new OpCode("OFalse",19);
		public static function OFindDefinition(d : Index) : OpCode { return new OpCode("OFindDefinition",51,[d]); }
		public static function OFindProp(p : Index) : OpCode { return new OpCode("OFindProp",50,[p]); }
		public static function OFindPropStrict(p : Index) : OpCode { return new OpCode("OFindPropStrict",49,[p]); }
		public static function OFloat(v : Index) : OpCode { return new OpCode("OFloat",26,[v]); }
		public static var OForEach : OpCode = new OpCode("OForEach",15);
		public static var OForIn : OpCode = new OpCode("OForIn",11);
		public static function OFunction(f : Index) : OpCode { return new OpCode("OFunction",30,[f]); }
		public static var OGetGlobalScope : OpCode = new OpCode("OGetGlobalScope",56);
		public static function OGetLex(p : Index) : OpCode { return new OpCode("OGetLex",52,[p]); }
		public static function OGetProp(p : Index) : OpCode { return new OpCode("OGetProp",58,[p]); }
		public static function OGetScope(n : int) : OpCode { return new OpCode("OGetScope",57,[n]); }
		public static function OGetSlot(s : int) : OpCode { return new OpCode("OGetSlot",61,[s]); }
		public static function OGetSuper(v : Index) : OpCode { return new OpCode("OGetSuper",3,[v]); }
		public static var OHasNext : OpCode = new OpCode("OHasNext",12);
		public static function OIncrIReg(r : int) : OpCode { return new OpCode("OIncrIReg",82,[r]); }
		public static function OIncrReg(r : int) : OpCode { return new OpCode("OIncrReg",77,[r]); }
		public static function OInitProp(p : Index) : OpCode { return new OpCode("OInitProp",59,[p]); }
		public static var OInstanceOf : OpCode = new OpCode("OInstanceOf",80);
		public static function OInt(v : int) : OpCode { return new OpCode("OInt",17,[v]); }
		public static function OIntRef(v : Index) : OpCode { return new OpCode("OIntRef",25,[v]); }
		public static function OIsType(t : Index) : OpCode { return new OpCode("OIsType",81,[t]); }
		public static function OJump(j : JumpStyle, delta : int) : OpCode { return new OpCode("OJump",7,[j,delta]); }
		public static var OLabel : OpCode = new OpCode("OLabel",6);
		public static var ONaN : OpCode = new OpCode("ONaN",20);
		public static function ONamespace(v : Index) : OpCode { return new OpCode("ONamespace",28,[v]); }
		public static var ONewBlock : OpCode = new OpCode("ONewBlock",46);
		public static function ONext(r1 : int, r2 : int) : OpCode { return new OpCode("ONext",29,[r1,r2]); }
		public static var ONop : OpCode = new OpCode("ONop",1);
		public static var ONull : OpCode = new OpCode("ONull",13);
		public static function OObject(nfields : int) : OpCode { return new OpCode("OObject",44,[nfields]); }
		public static function OOp(op : Operation) : OpCode { return new OpCode("OOp",91,[op]); }
		public static var OPop : OpCode = new OpCode("OPop",21);
		public static var OPopScope : OpCode = new OpCode("OPopScope",10);
		public static var OPushWith : OpCode = new OpCode("OPushWith",9);
		public static function OReg(r : int) : OpCode { return new OpCode("OReg",54,[r]); }
		public static function ORegKill(r : int) : OpCode { return new OpCode("ORegKill",5,[r]); }
		public static var ORet : OpCode = new OpCode("ORet",38);
		public static var ORetVoid : OpCode = new OpCode("ORetVoid",37);
		public static var OScope : OpCode = new OpCode("OScope",27);
		public static function OSetProp(p : Index) : OpCode { return new OpCode("OSetProp",53,[p]); }
		public static function OSetReg(r : int) : OpCode { return new OpCode("OSetReg",55,[r]); }
		public static function OSetSlot(s : int) : OpCode { return new OpCode("OSetSlot",62,[s]); }
		public static function OSetSuper(v : Index) : OpCode { return new OpCode("OSetSuper",4,[v]); }
		public static var OSetThis : OpCode = new OpCode("OSetThis",85);
		public static function OSmallInt(v : int) : OpCode { return new OpCode("OSmallInt",16,[v]); }
		public static function OString(v : Index) : OpCode { return new OpCode("OString",24,[v]); }
		public static var OSwap : OpCode = new OpCode("OSwap",23);
		public static function OSwitch(def : int, deltas : Array) : OpCode { return new OpCode("OSwitch",8,[def,deltas]); }
		public static var OThis : OpCode = new OpCode("OThis",84);
		public static var OThrow : OpCode = new OpCode("OThrow",2);
		public static var OTimestamp : OpCode = new OpCode("OTimestamp",90);
		public static var OToBool : OpCode = new OpCode("OToBool",69);
		public static var OToInt : OpCode = new OpCode("OToInt",66);
		public static var OToNumber : OpCode = new OpCode("OToNumber",68);
		public static var OToObject : OpCode = new OpCode("OToObject",70);
		public static var OToString : OpCode = new OpCode("OToString",63);
		public static var OToUInt : OpCode = new OpCode("OToUInt",67);
		public static var OToXml : OpCode = new OpCode("OToXml",64);
		public static var OToXmlAttr : OpCode = new OpCode("OToXmlAttr",65);
		public static var OTrue : OpCode = new OpCode("OTrue",18);
		public static var OTypeof : OpCode = new OpCode("OTypeof",79);
		public static var OUndefined : OpCode = new OpCode("OUndefined",14);
	}
}
