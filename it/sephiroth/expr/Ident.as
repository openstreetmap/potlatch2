package it.sephiroth.expr
{
	public class Ident
	{
		private var _id: String;
		private var _value: *;
		
		public function Ident( id: String, value: * = null )
		{
			_id = id;
			_value = value;
		}
		
		public function get id(): String
		{
			return _id;
		}
		
		public function get value(): *
		{
			return _value;
		}
		
		public function set value( v: * ): void
		{
			_value = v;
		}
		
		public function toString(): String
		{
			return _id;
		}
	}
}