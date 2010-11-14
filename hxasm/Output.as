package hxasm {
	import flash.utils.Endian;
	import flash.utils.ByteArray;

	public class Output {
		public function Output() : void {
			this.b = new ByteArray();
			this.b.endian = Endian.LITTLE_ENDIAN;
		}
		protected var b : ByteArray;
		public function write(str : String) : void {
			this.b.writeUTFBytes(str);
		}
		public function writeBinary(b : ByteArray) : void {
			this.b.writeBytes(b);
		}
		public function writeChar(c : int) : void {
			this.b.writeByte(c);
		}
		public function writeInt32(i : int) : void {
			this.b.writeInt(i);
		}
		public function writeUInt32(i : int) : void {
			this.b.writeUnsignedInt(i);
		}
		public function writeDouble(f : Number) : void {
			this.b.writeDouble(f);
		}
		public function writeUInt16(x : int) : void {
			if(x < 0 || x > 65535) throw "Overflow";
			this.writeChar(x & 255);
			this.writeChar(x >> 8);
		}
		public function writeUInt24(x : int) : void {
			if(x < 0 || x > 16777215) throw "Overflow";
			this.writeChar(x & 255);
			this.writeChar((x >> 8) & 255);
			this.writeChar(x >> 16);
		}
		public function writeInt24(x : int) : void {
			if(x < -8388608 || x > 8388607) throw "Overflow";
			if(x < 0) this.writeUInt24(16777216 + x);
			else this.writeUInt24(x);
		}
		public function writeInt8(c : int) : void {
			if(c < -128 || c > 127) throw "Overflow";
			this.writeChar(c & 255);
		}
		public function getBytes() : ByteArray {
			return this.b;
		}
	}
}
