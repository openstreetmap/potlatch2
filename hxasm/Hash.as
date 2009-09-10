package  hxasm{
	import flash.utils.Dictionary;
	
	public class Hash {
		public function Hash() : void {
			this.h = new Dictionary();
		}
		public function set(key : String,value : *) : void {
			this.h["$" + key] = value;
		}
		public function get(key : String) : * {
			return this.h["$" + key];
		}
		public function exists(key : String) : Boolean {
			return this.h.hasOwnProperty("$" + key);
		}
		public function remove(key : String) : Boolean {
			key = "$" + key;
			if(!this.h.hasOwnProperty(key)) return false;
			delete(this.h[key]);
			return true;
		}
		public function keys() : * {
			return (function($this:Hash) : * {
				var $r : *;
				$r = new Array();
				for(var $k : String in $this.h) $r.push($k.substr(1));
				return $r;
			}(this)).iterator();
		}
		public function iterator() : * {
			return { ref : this.h, it : function($this:Hash) : * {
				var $r : *;
				$r = new Array();
				for(var $k : String in $this.h) $r.push($k);
				return $r;
			}(this).iterator(), hasNext : function() : * {
				return this.it.hasNext();
			}, next : function() : * {
				var i : * = this.it.next();
				return this.ref[i];
			}}
		}
		public function toString() : String {
			var s : StringBuf = new StringBuf();
			s.add("{");
			var it : * = this.keys();
			{ var $it : * = it;
			while( $it.hasNext() ) { var i : String = $it.next();
			{
				s.add(i);
				s.add(" => ");
				s.add((this.get(i)).toString());
				if(it.hasNext()) s.add(", ");
			}
			}}
			s.add("}");
			return s.toString();
		}
		protected var h : *;
	}
}
