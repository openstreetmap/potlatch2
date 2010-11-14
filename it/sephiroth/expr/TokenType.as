package it.sephiroth.expr
{
	public final class TokenType
	{
		public static const ADD: int = 1;
		public static const SUB: int = 2;
		public static const MUL: int = 3;
		public static const DIV: int = 4;
		public static const NUM: int = 5;
		public static const IDENT: int = 6;
		public static const LEFT_PAR: int = 7;
		public static const RIGHT_PAR: int = 8;
		public static const COMMA: int = 9;
		public static const NULL: int = 0;
		public static const EOF: int = -1;
		
		public static function typeToString( type: int ): String
		{
			switch( type )
			{
				case 0:		return "NULL";
				case 1:		return "ADD";
				case 2:		return "SUB";
				case 3:		return "MUL";
				case 4:		return "DIV";
				case 5:		return "NUM";
				case 6:		return "IDENT";
				case 7:		return "LEFT_PAR";
				case 8:		return "RIGHT_PAR";
				case 9:		return "COMMA";
				default:	return "EOF";
			}
			
			return null;
		}
	}
}