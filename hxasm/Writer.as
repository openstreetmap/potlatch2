package hxasm {
	
	import flash.utils.ByteArray;
	
	public class Writer {
		public function Writer(out : Output,ctx : Context) : void {
			this.data = out;
			this.ctx = ctx;
			this.emptyIndex = Index.Idx(1);
		}
		protected var ctx : Context;
		protected var data : Output;
		protected var emptyIndex : Index;
		protected function beginTag(id : int,len : int) : void {
			if(len >= 63) {
				this.data.writeUInt16((id << 6) | 63);
				this.data.writeUInt32(len);
			}
			else this.data.writeUInt16((id << 6) | len);
		}
		protected function writeInt(n : int) : void {
			OpWriter.writeInt(this.data,n);
		}
		protected function writeList(a : Array,write : Function) : void {
			if(a.length == 0) {
				this.writeInt(0);
				return;
			}
			this.writeInt(a.length + 1);
			{
				var _g1 : int = 0, _g : int = a.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					write(a[i]);
				}
			}
		}
		protected function writeList2(a : Array,write : Function) : void {
			this.writeInt(a.length);
			{
				var _g1 : int = 0, _g : int = a.length;
				while(_g1 < _g) {
					var i : int = _g1++;
					write(a[i]);
				}
			}
		}
		protected function writeString(s : String) : void {
			this.writeInt(s.length);
			this.data.write(s);
		}
		protected function writeIndex(i : Index) : void {
			var $e : enum = (i);
			switch( $e.index ) {
			case 0:
			var n : int = $e.params[0];
			{
				this.writeInt(n);
			}break;
			}
		}
		protected function writeIndexOpt(i : Index) : void {
			if(i == null) {
				this.data.writeChar(0);
				return;
			}
			this.writeIndex(i);
		}
		protected function writeNamespace(n : HNamespace) : void {
			var $e : enum = (n);
			switch( $e.index ) {
			case 0:
			var id : Index = $e.params[0];
			{
				this.data.writeChar(22);
				this.writeIndex((id == null?this.emptyIndex:id));
			}break;
			case 1:
			var ns : Index = $e.params[0];
			{
				this.data.writeChar(8);
				this.writeIndex(ns);
			}break;
			}
		}
		protected function writeNsSet(n : Array) : void {
			this.data.writeChar(n.length);
			{
				var _g : int = 0;
				while(_g < n.length) {
					var i : Index = n[_g];
					++_g;
					this.writeIndex(i);
				}
			}
		}
		protected function writeName(n : Name) : void {
			var $e : enum = (n);
			switch( $e.index ) {
			case 0:
			var ns : Index = $e.params[1], id : Index = $e.params[0];
			{
				this.data.writeChar(7);
				this.writeIndex(ns);
				this.writeIndex(id);
			}break;
			case 1:
			var nss : Index = $e.params[0];
			{
				this.data.writeChar(27);
				this.writeIndex(nss);
			}break;
			}
		}
		protected function writeField(f : *) : void {
			this.writeIndex(f.name);
			var $e : enum = (f.kind);
			switch( $e.index ) {
			case 0:
			var _const : * = $e.params[1], t : Index = $e.params[0];
			{
				this.data.writeChar((_const?6:0));
				this.writeInt(f.slot);
				this.writeIndexOpt(t);
				this.data.writeChar(0);
			}break;
			case 1:
			var isOverride : * = $e.params[2], isFinal : * = $e.params[1], t2 : Index = $e.params[0];
			{
				var flags : int = ((isFinal?16:0)) | ((isOverride?32:0));
				this.data.writeChar(1 | flags);
				this.writeInt(f.slot);
				this.writeIndex(t2);
			}break;
			}
		}
		protected function writeClass(c : *) : void {
			this.writeIndex(c.name);
			this.writeIndex(c.superclass);
			this.data.writeChar(0);
			this.writeList2([],null);
			this.writeIndex(c.constructorType);
			this.writeList2(c.fields,this.writeField);
		}
		protected function writeStatics(c : *) : void {
			this.writeIndex(c.statics);
			this.writeList2(c.staticFields,this.writeField);
		}
		protected function writeMethodType(m : *) : void {
			this.data.writeChar(m.args.length);
			this.writeIndexOpt(m.ret);
			{
				var _g : int = 0, _g1 : Array = m.args;
				while(_g < _g1.length) {
					var a : Index = _g1[_g];
					++_g;
					this.writeIndexOpt(a);
				}
			}
			this.writeIndexOpt(null);
			this.data.writeChar(0);
		}
		protected function writeMethod(m : *) : void {
			this.writeIndex(m.type);
			this.writeInt(m.maxStack);
			this.writeInt(m.nRegs);
			this.writeInt(0);
			this.writeInt(m.maxScope);
			var b : OpWriter = new OpWriter();
			{
				var _g : int = 0, _g1 : Array = m.opcodes;
				while(_g < _g1.length) {
					var o : OpCode = _g1[_g];
					++_g;
					b.write(o);
				}
			}
			var codeStr : ByteArray = b.getBytes();
			this.writeInt(codeStr.length);
			this.data.writeBinary(codeStr);
			this.writeList2([],null);
			this.writeList2([],null);
		}
		protected function writeInitSlot(c : *) : void {
			this.writeIndex(c.name);
			this.data.writeChar(4);
			this.writeInt(1);
			this.writeIndex(c.index);
		}
		protected function writeInit(init : Index,classes : Array) : void {
			this.writeIndex(init);
			this.writeList2(classes,this.writeInitSlot);
		}
		protected function writeAs3Header() : void {
			var d : * = this.ctx.getDatas();
			this.data.writeInt32(3014672);
			this.writeList(d.ints,this.writeInt);
			this.writeList([],null);
			this.writeList(d.floats,this.data.writeDouble);
			this.writeList(d.strings,this.writeString);
			this.writeList(d.namespaces,this.writeNamespace);
			this.writeList(d.nssets,this.writeNsSet);
			this.writeList(d.names,this.writeName);
			this.writeList2(d.mtypes,this.writeMethodType);
			this.writeList2([],null);
			this.writeList2(d.classes,this.writeClass);
			{
				var _g : int = 0, _g1 : Array = d.classes;
				while(_g < _g1.length) {
					var c : * = _g1[_g];
					++_g;
					this.writeStatics(c);
				}
			}
			this.writeList2([d.classes],function(f : Function,a1 : Index) : Function {
				return function(a2 : Array) : void {
					f(a1,a2);
					return;
				}
			}(this.writeInit,d.init));
			this.writeList2(d.methods,this.writeMethod);
		}
		protected function write() : void {
			var out : Output = this.data;
			out.write("FWS");
			out.writeChar(9);
			var header : Output = new Output();
			this.data = header;
			this.writeAs3Header();
			this.data = out;
			var header1 : ByteArray = header.getBytes();
			var len : int = 23 + 6 + header1.length + (header1.length >= 63?6:2);
			out.writeInt32(len);
			{
				var _g : int = 0, _g1 : Array = [120,0,3,232,0,0,11,184,0];
				while(_g < _g1.length) {
					var c : int = _g1[_g];
					++_g;
					out.writeChar(c);
				}
			}
			out.writeUInt16(7680);
			out.writeUInt16(1);
			this.beginTag(69,4);
			out.writeInt32(25);
			this.beginTag(72,header1.length);
			out.writeBinary(header1);
			this.beginTag(1,0);
			this.beginTag(0,0);
		}
		static public function write(out : Output,ctx : Context) : void {
			var w : Writer = new Writer(out,ctx);
			w.write();
		}
	}
}
