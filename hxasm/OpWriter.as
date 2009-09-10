package hxasm {
	
	import flash.utils.ByteArray;
	
	public class OpWriter {
		public function OpWriter() : void {
			this.o = new Output();
		}
		protected var o : Output;
		protected function _int(i : int) : void {
			writeInt(this.o,i);
		}
		protected function b(v : int) : void {
			this.o.writeChar(v);
		}
		protected function reg(v : int) : void {
			this.o.writeChar(v);
		}
		protected function idx(i : Index) : void {
			var $e : enum = (i);
			switch( $e.index ) {
			case 0:
			var i1 : int = $e.params[0];
			{
				this._int(i1);
			}break;
			}
		}
		protected function jumpCode(j : JumpStyle) : int {
			return function($this:OpWriter) : int {
				var $r : int;
				var $e : enum = (j);
				switch( $e.index ) {
				case 0:
				{
					$r = 12;
				}break;
				case 1:
				{
					$r = 13;
				}break;
				case 2:
				{
					$r = 14;
				}break;
				case 3:
				{
					$r = 15;
				}break;
				case 4:
				{
					$r = 16;
				}break;
				case 5:
				{
					$r = 17;
				}break;
				case 6:
				{
					$r = 18;
				}break;
				case 7:
				{
					$r = 19;
				}break;
				case 8:
				{
					$r = 20;
				}break;
				case 9:
				{
					$r = 21;
				}break;
				case 10:
				{
					$r = 22;
				}break;
				case 11:
				{
					$r = 23;
				}break;
				case 12:
				{
					$r = 24;
				}break;
				case 13:
				{
					$r = 25;
				}break;
				case 14:
				{
					$r = 26;
				}break;
				default:{
					$r = null;
				}break;
				}
				return $r;
			}(this);
		}
		protected function operationCode(o : Operation) : int {
			return function($this:OpWriter) : int {
				var $r : int;
				var $e : enum = (o);
				switch( $e.index ) {
				case 0:
				{
					$r = 135;
				}break;
				case 1:
				{
					$r = 144;
				}break;
				case 2:
				{
					$r = 145;
				}break;
				case 3:
				{
					$r = 147;
				}break;
				case 4:
				{
					$r = 150;
				}break;
				case 5:
				{
					$r = 151;
				}break;
				case 6:
				{
					$r = 160;
				}break;
				case 7:
				{
					$r = 161;
				}break;
				case 8:
				{
					$r = 162;
				}break;
				case 9:
				{
					$r = 163;
				}break;
				case 10:
				{
					$r = 164;
				}break;
				case 11:
				{
					$r = 165;
				}break;
				case 12:
				{
					$r = 166;
				}break;
				case 13:
				{
					$r = 167;
				}break;
				case 14:
				{
					$r = 168;
				}break;
				case 15:
				{
					$r = 169;
				}break;
				case 16:
				{
					$r = 170;
				}break;
				case 17:
				{
					$r = 171;
				}break;
				case 18:
				{
					$r = 172;
				}break;
				case 19:
				{
					$r = 173;
				}break;
				case 20:
				{
					$r = 174;
				}break;
				case 21:
				{
					$r = 175;
				}break;
				case 22:
				{
					$r = 176;
				}break;
				case 23:
				{
					$r = 179;
				}break;
				case 24:
				{
					$r = 180;
				}break;
				case 25:
				{
					$r = 192;
				}break;
				case 26:
				{
					$r = 193;
				}break;
				case 27:
				{
					$r = 196;
				}break;
				case 28:
				{
					$r = 197;
				}break;
				case 29:
				{
					$r = 198;
				}break;
				case 30:
				{
					$r = 199;
				}break;
				default:{
					$r = null;
				}break;
				}
				return $r;
			}(this);
		}
		public function write(op : OpCode) : void {
			var $e : enum = (op);
			switch( $e.index ) {
			case 0:
			{
				this.b(1);
			}break;
			case 1:
			{
				this.b(2);
			}break;
			case 2:
			{
				this.b(3);
			}break;
			case 3:
			var v : Index = $e.params[0];
			{
				this.b(4);
				this.idx(v);
			}break;
			case 4:
			var v2 : Index = $e.params[0];
			{
				this.b(5);
				this.idx(v2);
			}break;
			case 5:
			var r : int = $e.params[0];
			{
				this.b(8);
				this.reg(r);
			}break;
			case 6:
			{
				this.b(9);
			}break;
			case 7:
			var delta : int = $e.params[1], j : JumpStyle = $e.params[0];
			{
				this.b(this.jumpCode(j));
				this.o.writeInt24(delta);
			}break;
			case 8:
			var deltas : Array = $e.params[1], def : int = $e.params[0];
			{
				this.b(27);
				this.o.writeInt24(def);
				this._int(deltas.length - 1);
				{
					var _g : int = 0;
					while(_g < deltas.length) {
						var d : int = deltas[_g];
						++_g;
						this.o.writeInt24(d);
					}
				}
			}break;
			case 9:
			{
				this.b(28);
			}break;
			case 10:
			{
				this.b(29);
			}break;
			case 11:
			{
				this.b(30);
			}break;
			case 12:
			{
				this.b(31);
			}break;
			case 13:
			{
				this.b(32);
			}break;
			case 14:
			{
				this.b(33);
			}break;
			case 15:
			{
				this.b(35);
			}break;
			case 16:
			var v3 : int = $e.params[0];
			{
				this.b(36);
				this.o.writeInt8(v3);
			}break;
			case 17:
			var v4 : int = $e.params[0];
			{
				this.b(37);
				this._int(v4);
			}break;
			case 18:
			{
				this.b(38);
			}break;
			case 19:
			{
				this.b(39);
			}break;
			case 20:
			{
				this.b(40);
			}break;
			case 21:
			{
				this.b(41);
			}break;
			case 22:
			{
				this.b(42);
			}break;
			case 23:
			{
				this.b(43);
			}break;
			case 24:
			var v5 : Index = $e.params[0];
			{
				this.b(44);
				this.idx(v5);
			}break;
			case 25:
			var v6 : Index = $e.params[0];
			{
				this.b(45);
				this.idx(v6);
			}break;
			case 26:
			var v7 : Index = $e.params[0];
			{
				this.b(47);
				this.idx(v7);
			}break;
			case 27:
			{
				this.b(48);
			}break;
			case 28:
			var v8 : Index = $e.params[0];
			{
				this.b(49);
				this.idx(v8);
			}break;
			case 29:
			var r2 : int = $e.params[1], r1 : int = $e.params[0];
			{
				this.b(50);
				this._int(r1);
				this._int(r2);
			}break;
			case 30:
			var f : Index = $e.params[0];
			{
				this.b(64);
				this.idx(f);
			}break;
			case 31:
			var n : int = $e.params[0];
			{
				this.b(65);
				this._int(n);
			}break;
			case 32:
			var n2 : int = $e.params[0];
			{
				this.b(66);
				this._int(n2);
			}break;
			case 33:
			var n3 : int = $e.params[1], s : int = $e.params[0];
			{
				this.b(67);
				this._int(s);
				this._int(n3);
			}break;
			case 34:
			var n4 : int = $e.params[1], m : Index = $e.params[0];
			{
				this.b(68);
				this.idx(m);
				this._int(n4);
			}break;
			case 35:
			var n5 : int = $e.params[1], p : Index = $e.params[0];
			{
				this.b(69);
				this.idx(p);
				this._int(n5);
			}break;
			case 36:
			var n6 : int = $e.params[1], p2 : Index = $e.params[0];
			{
				this.b(70);
				this.idx(p2);
				this._int(n6);
			}break;
			case 37:
			{
				this.b(71);
			}break;
			case 38:
			{
				this.b(72);
			}break;
			case 39:
			var n7 : int = $e.params[0];
			{
				this.b(73);
				this._int(n7);
			}break;
			case 40:
			var n8 : int = $e.params[1], p3 : Index = $e.params[0];
			{
				this.b(74);
				this.idx(p3);
				this._int(n8);
			}break;
			case 41:
			var n9 : int = $e.params[1], p4 : Index = $e.params[0];
			{
				this.b(76);
				this.idx(p4);
				this._int(n9);
			}break;
			case 42:
			var n10 : int = $e.params[1], p5 : Index = $e.params[0];
			{
				this.b(78);
				this.idx(p5);
				this._int(n10);
			}break;
			case 43:
			var n11 : int = $e.params[1], p6 : Index = $e.params[0];
			{
				this.b(79);
				this.idx(p6);
				this._int(n11);
			}break;
			case 44:
			var n12 : int = $e.params[0];
			{
				this.b(85);
				this._int(n12);
			}break;
			case 45:
			var n13 : int = $e.params[0];
			{
				this.b(86);
				this._int(n13);
			}break;
			case 46:
			{
				this.b(87);
			}break;
			case 47:
			var c : Index = $e.params[0];
			{
				this.b(88);
				this.idx(c);
			}break;
			case 48:
			var c2 : int = $e.params[0];
			{
				this.b(90);
				this._int(c2);
			}break;
			case 49:
			var p7 : Index = $e.params[0];
			{
				this.b(93);
				this.idx(p7);
			}break;
			case 50:
			var p8 : Index = $e.params[0];
			{
				this.b(94);
				this.idx(p8);
			}break;
			case 51:
			var d2 : Index = $e.params[0];
			{
				this.b(95);
				this.idx(d2);
			}break;
			case 52:
			var p9 : Index = $e.params[0];
			{
				this.b(96);
				this.idx(p9);
			}break;
			case 53:
			var p10 : Index = $e.params[0];
			{
				this.b(97);
				this.idx(p10);
			}break;
			case 54:
			var r3 : int = $e.params[0];
			{
				switch(r3) {
				case 0:{
					this.b(208);
				}break;
				case 1:{
					this.b(209);
				}break;
				case 2:{
					this.b(210);
				}break;
				case 3:{
					this.b(211);
				}break;
				default:{
					this.b(98);
					this.reg(r3);
				}break;
				}
			}break;
			case 55:
			var r4 : int = $e.params[0];
			{
				switch(r4) {
				case 0:{
					this.b(212);
				}break;
				case 1:{
					this.b(213);
				}break;
				case 2:{
					this.b(214);
				}break;
				case 3:{
					this.b(215);
				}break;
				default:{
					this.b(99);
					this.reg(r4);
				}break;
				}
			}break;
			case 56:
			{
				this.b(100);
			}break;
			case 57:
			var n14 : int = $e.params[0];
			{
				this.b(101);
				this.b(n14);
			}break;
			case 58:
			var p11 : Index = $e.params[0];
			{
				this.b(102);
				this.idx(p11);
			}break;
			case 59:
			var p12 : Index = $e.params[0];
			{
				this.b(104);
				this.idx(p12);
			}break;
			case 60:
			var p13 : Index = $e.params[0];
			{
				this.b(106);
				this.idx(p13);
			}break;
			case 61:
			var s2 : int = $e.params[0];
			{
				this.b(108);
				this._int(s2);
			}break;
			case 62:
			var s3 : int = $e.params[0];
			{
				this.b(109);
				this._int(s3);
			}break;
			case 63:
			{
				this.b(112);
			}break;
			case 64:
			{
				this.b(113);
			}break;
			case 65:
			{
				this.b(114);
			}break;
			case 66:
			{
				this.b(115);
			}break;
			case 67:
			{
				this.b(116);
			}break;
			case 68:
			{
				this.b(117);
			}break;
			case 69:
			{
				this.b(118);
			}break;
			case 70:
			{
				this.b(119);
			}break;
			case 71:
			{
				this.b(120);
			}break;
			case 72:
			var t : Index = $e.params[0];
			{
				this.b(128);
				this.idx(t);
			}break;
			case 73:
			{
				this.b(130);
			}break;
			case 74:
			{
				this.b(133);
			}break;
			case 75:
			var t2 : Index = $e.params[0];
			{
				this.b(134);
				this.idx(t2);
			}break;
			case 76:
			{
				this.b(137);
			}break;
			case 77:
			var r5 : int = $e.params[0];
			{
				this.b(146);
				this.reg(r5);
			}break;
			case 78:
			var r6 : int = $e.params[0];
			{
				this.b(148);
				this.reg(r6);
			}break;
			case 79:
			{
				this.b(149);
			}break;
			case 80:
			{
				this.b(177);
			}break;
			case 81:
			var t3 : Index = $e.params[0];
			{
				this.b(178);
				this.idx(t3);
			}break;
			case 82:
			var r7 : int = $e.params[0];
			{
				this.b(194);
				this.reg(r7);
			}break;
			case 83:
			var r8 : int = $e.params[0];
			{
				this.b(195);
				this.reg(r8);
			}break;
			case 84:
			{
				this.b(208);
			}break;
			case 85:
			{
				this.b(212);
			}break;
			case 86:
			var line : int = $e.params[2], r9 : int = $e.params[1], name : Index = $e.params[0];
			{
				this.b(239);
				this.idx(name);
				this.reg(r9);
				this._int(line);
			}break;
			case 87:
			var line2 : int = $e.params[0];
			{
				this.b(240);
				this._int(line2);
			}break;
			case 88:
			var file : Index = $e.params[0];
			{
				this.b(241);
				this.idx(file);
			}break;
			case 89:
			var n15 : int = $e.params[0];
			{
				this.b(242);
				this._int(n15);
			}break;
			case 90:
			{
				this.b(243);
			}break;
			case 91:
			var op1 : Operation = $e.params[0];
			{
				this.b(this.operationCode(op1));
			}break;
			case 92:
			var byte : int = $e.params[0];
			{
				this.b(byte);
			}break;
			}
		}
		public function getBytes() : ByteArray {
			return this.o.getBytes();
		}
		static public function writeInt(o : Output,n : int) : void {
			var e : int = n >>> 28;
			var d : int = (n >> 21) & 127;
			var c : int = (n >> 14) & 127;
			var b : int = (n >> 7) & 127;
			var a : int = n & 127;
			if(b != 0 || c != 0 || d != 0 || e != 0) {
				o.writeChar(a | 128);
				if(c != 0 || d != 0 || e != 0) {
					o.writeChar(b | 128);
					if(d != 0 || e != 0) {
						o.writeChar(c | 128);
						if(e != 0) {
							o.writeChar(d | 128);
							o.writeChar(e);
						}
						else o.writeChar(d);
					}
					else o.writeChar(c);
				}
				else o.writeChar(b);
			}
			else o.writeChar(a);
		}
	}
}
