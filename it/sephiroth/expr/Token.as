package it.sephiroth.expr
{
	public class Token
	{
		private var _type: int;
		private var _value: *;
		
		public function Token( type: int, value: * = null )
		{
			_type = type;
			_value = value;
		}
		
		public function get type(): int
		{
			return _type;
		}
		
		public function get value(): *
		{
			return _value;
		}
		
		public function toString(): String
		{
			if( !_value )
			{
				return TokenType.typeToString( _type );
			}else
			{
				return "<" + TokenType.typeToString( _type ) + ", " + value + ">";
			}
		}

	}
}