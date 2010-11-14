package hxasm {

	public class Context {
		public function Context() : void {
			this.lints = new Array();
			this.lfloats = new Array();
			this.lstrings = new Array();
			this.lnamespaces = new Array();
			this.lnssets = new Array();
			this.lmtypes = new Array();
			this.lnames = new Array();
			this.lclasses = new Array();
			this.lmethods = new Array();
			this.hstrings = new Hash();
			this.bytepos = 0;
			this.emptyString = this.string("");
			this.nsPublic = this.namespace(HNamespace.NPublic(this.emptyString));
			this.arrayProp = this.name(Name.NMultiNameLate(this.nsset([this.nsPublic])));
			this.beginFunction({ args : [], ret : null});
			this.ops([OpCode.OThis,OpCode.OScope]);
			this.init = this.curMethod;
			this.init.maxStack = 2;
			this.init.maxScope = 2;
		}
		protected var lints : Array;
		protected var lfloats : Array;
		protected var lstrings : Array;
		protected var lnamespaces : Array;
		protected var lnssets : Array;
		protected var lnames : Array;
		protected var hstrings : Hash;
		protected var lclasses : Array;
		protected var lmtypes : Array;
		protected var lmethods : Array;
		protected var curClass : *;
		protected var curMethod : *;
		protected var init : *;
		protected var fieldSlot : int;
		protected var bytepos : int;
		protected var registers : Array;
		public var emptyString : Index;
		public var nsPublic : Index;
		public var arrayProp : Index;
		public function _int(i : int) : Index {
			return this.lookup(this.lints,i);
		}
		public function float(f : Number) : Index {
			return this.lookup(this.lfloats,f);
		}
		public function string(s : String) : Index {
			var n : * = this.hstrings.get(s);
			if(n == null) {
				this.lstrings.push(s);
				n = this.lstrings.length;
				this.hstrings.set(s,n);
			}
			return Index.Idx(n);
		}
		public function namespace(n : HNamespace) : Index {
			return this.elookup(this.lnamespaces,n);
		}
		public function nsset(ns : Array) : Index {
			{
				var _g1 : int = 0, _g : int = this.lnssets.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					var s : Array = this.lnssets[i];
					if(s.length != ns.length) continue;
					var ok : Boolean = true;
					{
						var _g3 : int = 0, _g2 : int = s.length;
						while(_g3 < _g2) {
							var j : int = _g3++;
							if(!Type.enumEq(s[j],ns[j])) {
								ok = false;
								break;
							}
						}
					}
					if(ok) return Index.Idx(i + 1);
				}
			}
			this.lnssets.push(ns);
			return Index.Idx(this.lnssets.length);
		}
		public function name(n : Name) : Index {
			return this.elookup(this.lnames,n);
		}
		public function type(path : String) : Index {
			if(path == "*") return null;
			var path1 : Array = path.split(".");
			var cname : String = path1.pop();
			var pid : Index = this.string(path1.join("."));
			var nameid : Index = this.string(cname);
			var pid1 : Index = this.namespace(HNamespace.NPublic(pid));
			var tid : Index = this.name(Name.NName(nameid,pid1));
			return tid;
		}
		public function property(pname : String,ns : Index = null) : Index {
			var pid : Index = this.string("");
			var nameid : Index = this.string(pname);
			var pid1 : Index = (ns == null?this.namespace(HNamespace.NPublic(pid)):ns);
			var tid : Index = this.name(Name.NName(nameid,pid1));
			return tid;
		}
		public function methodType(m : *) : Index {
			this.lmtypes.push(m);
			return Index.Idx(this.lmtypes.length - 1);
		}
		protected function lookup(arr : Array,n : *) : Index {
			{
				var _g1 : int = 0, _g : int = arr.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					if(arr[i] == n) return Index.Idx(i + 1);
				}
			}
			arr.push(n);
			return Index.Idx(arr.length);
		}
		protected function elookup(arr : Array,n : *) : Index {
			{
				var _g1 : int = 0, _g : int = arr.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					if(Type.enumEq(arr[i],n)) return Index.Idx(i + 1);
				}
			}
			arr.push(n);
			return Index.Idx(arr.length);
		}
		public function getDatas() : * {
			return { ints : this.lints, floats : this.lfloats, strings : this.lstrings, namespaces : this.lnamespaces, nssets : this.lnssets, names : this.lnames, mtypes : this.lmtypes, classes : this.lclasses, methods : this.lmethods, init : Index.Idx(0)}
		}
		protected function beginFunction(mt : *) : Index {
			this.curMethod = { type : this.methodType(mt), nRegs : mt.args.length + 1, maxScope : 0, maxStack : 0, opcodes : []}
			this.lmethods.push(this.curMethod);
			this.registers = new Array();
			{
				var _g1 : int = 0, _g : int = this.curMethod.nRegs;
				while(_g1 < _g) {
					var x : int = _g1++;
					this.registers.push(true);
				}
			}
			return Index.Idx(this.lmethods.length - 1);
		}
		public function allocRegister() : int {
			{
				var _g1 : int = 0, _g : int = this.registers.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					if(!this.registers[i]) {
						this.registers[i] = true;
						return i;
					}
				}
			}
			this.registers.push(true);
			this.curMethod.nRegs++;
			return this.registers.length - 1;
		}
		public function freeRegister(i : int) : void {
			this.registers[i] = false;
		}
		public function beginClass(path : String) : * {
			this.endClass();
			var index : Index = Index.Idx(this.lclasses.length);
			var tpath : Index = this.type(path);
			var st : Index = this.beginFunction({ args : [], ret : null});
			this.op(OpCode.ORetVoid);
			var m : Index = this.beginFunction({ args : [], ret : null});
			this.op(OpCode.ORetVoid);
			this.fieldSlot = 1;
			this.curClass = { index : index, name : tpath, superclass : this.type("Object"), constructorType : this.curMethod.type, constructor : m, statics : st, fields : [], staticFields : []}
			this.lclasses.push(this.curClass);
			this.curMethod = null;
			return this.curClass;
		}
		protected function endClass() : void {
			if(this.curClass == null) return;
			this.curMethod = this.init;
			this.ops([OpCode.OGetGlobalScope,OpCode.OGetLex(this.type("Object")),OpCode.OScope,OpCode.OGetLex(this.curClass.superclass),OpCode.OClassDef(this.curClass.index),OpCode.OPopScope,OpCode.OInitProp(this.curClass.name)]);
			this.curMethod = null;
			this.curClass = null;
		}
		public function beginMethod(mname : String,targs : Array,tret : Index,isStatic : * = null,isOverride : * = null,isFinal : * = null) : * {
			var m : Index = this.beginFunction({ args : targs, ret : tret});
			var fl : Array = (isStatic?this.curClass.staticFields:this.curClass.fields);
			fl.push({ name : this.property(mname), slot : 0, kind : FieldKind.FMethod(m,isFinal,isOverride)});
			return this.curMethod;
		}
		public function defineField(fname : String,t : Index,isStatic : * = null) : int {
			var fl : Array = (isStatic?this.curClass.staticFields:this.curClass.fields);
			var slot : int = this.fieldSlot++;
			fl.push({ name : this.property(fname), slot : slot, kind : FieldKind.FVar(t)});
			return slot;
		}
		public function op(o : OpCode) : void {
			this.curMethod.opcodes.push(o);
			var w : OpWriter = new OpWriter();
			w.write(o);
			this.bytepos += w.getBytes().length;
		}
		public function ops(ops : Array) : void {
			{
				var _g1 : int = 0, _g : int = ops.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					this.op(ops[i]);
				}
			}
		}
		public function backwardJump() : Function {
			var start : int = this.bytepos;
			var me : Context = this;
			this.op(OpCode.OLabel);
			return function(jcond : JumpStyle) : void {
				me.op(OpCode.OJump(jcond,start - me.bytepos - 4));
			}
		}
		public function jump(jcond : JumpStyle) : Function {
			var ops : Array = this.curMethod.opcodes;
			var pos : int = ops.length;
			this.op(OpCode.OJump(JumpStyle.JTrue,-1));
			var start : int = this.bytepos;
			var me : Context = this;
			return function() : void {
				ops[pos] = OpCode.OJump(jcond,me.bytepos - start);
			}
		}
		public function finalize() : void {
			this.endClass();
			this.curMethod = this.init;
			this.op(OpCode.ORetVoid);
			this.curMethod = null;
			this.curClass = null;
		}
	}
}
