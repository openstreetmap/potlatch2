package hxasm {
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.describeType;
	import flash.utils.getQualifiedSuperclassName;
	public class Type {
		static public function toEnum(t : *) : Class {
			try {
				if(!t.__isenum) return null;
				return t;
			}
			catch( e : * ){
				null;
			}
			return null;
		}
		static public function toClass(t : *) : Class {
			try {
				if(!t.hasOwnProperty("prototype")) return null;
				return t;
			}
			catch( e : * ){
				null;
			}
			return null;
		}
		static public function getClass(o : *) : Class {
			var cname : String = getQualifiedClassName(o);
			if(cname == "null" || cname == "Object" || cname == "int" || cname == "Number" || cname == "Boolean") return null;
			if(o.hasOwnProperty("prototype")) return null;
			var c : * = getDefinitionByName(cname) as Class;
			if(c.__isenum) return null;
			return c;
		}
		static public function getEnum(o : *) : Class {
			var cname : String = getQualifiedClassName(o);
			if(cname == "null" || cname.substr(0,8) == "builtin.") return null;
			if(o.hasOwnProperty("prototype")) return null;
			var c : * = getDefinitionByName(cname) as Class;
			if(!c.__isenum) return null;
			return c;
		}
		static public function getSuperClass(c : Class) : Class {
			var cname : String = getQualifiedSuperclassName(c);
			if(cname == "Object") return null;
			return getDefinitionByName(cname) as Class;
		}
		static public function getClassName(c : Class) : String {
			if(c == null) return null;
			var str : String = getQualifiedClassName(c);
			return str.split("::").join(".");
		}
		static public function getEnumName(e : Class) : String {
			var n : String = getQualifiedClassName(e);
			return n;
		}
		static public function resolveClass(name : String) : Class {
			var cl : Class;
			{
				try {
					cl = getDefinitionByName(name) as Class;
					if(cl.__isenum) return null;
					return cl;
				}
				catch( e : * ){
					return null;
				}
				if(cl == null || cl.__name__ == null) return null;
				else null;
			}
			return cl;
		}
		static public function resolveEnum(name : String) : Class {
			var e : *;
			{
				try {
					e = getDefinitionByName(name);
					if(!e.__isenum) return null;
					return e;
				}
				catch( e1 : * ){
					return null;
				}
				if(e == null || e.__ename__ == null) return null;
				else null;
			}
			return e;
		}
		static public function createInstance(cl : Class,args : Array) : * {
			return function() : * {
				var $r : *;
				switch(args.length) {
				case 0:{
					$r = new cl();
				}break;
				case 1:{
					$r = new cl(args[0]);
				}break;
				case 2:{
					$r = new cl(args[0],args[1]);
				}break;
				case 3:{
					$r = new cl(args[0],args[1],args[2]);
				}break;
				case 4:{
					$r = new cl(args[0],args[1],args[2],args[3]);
				}break;
				case 5:{
					$r = new cl(args[0],args[1],args[2],args[3],args[4]);
				}break;
				default:{
					$r = function() : * {
						var $r2 : *;
						throw "Too many arguments";
						return $r2;
					}();
				}break;
				}
				return $r;
			}();
		}
		static public function getEnumConstructs(e : Class) : Array {
			return e.__constructs__;
		}
		static public function enumEq(a : *,b : *) : Boolean {
			if(a == b) return true;
			try {
				if(a.tag != b.tag) return false;
				{
					var _g1 : int = 0, _g : int = a.params.length;
					while(_g1 < _g) {
						var i : int = _g1++;
						if(!enumEq(a.params[i],b.params[i])) return false;
					}
				}
			}
			catch( e : * ){
				return false;
			}
			return true;
		}
		static public function enumConstructor(e : *) : String {
			return e.tag;
		}
		static public function enumParameters(e : *) : Array {
			return (e.params == null?[]:e.params);
		}
		static public function enumIndex(e : *) : int {
			return e.index;
		}
	}
}
