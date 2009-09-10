package  hxasm{
	public class StringBuf {
		public function StringBuf() : void {
			this.b = "";
		}
		public function add(x : * = null) : void {
			this.b += x;
		}
		public function addSub(s : String,pos : int,len : * = null) : void {
			if(len == null) this.b += s.substr(pos);
			else this.b += s.substr(pos,len);
		}
		public function addChar(c : int) : void {
			this.b += String["fromCharCode"](c);
		}
		public function toString() : String {
			return this.b;
		}
		protected var b : *;
	}
}
