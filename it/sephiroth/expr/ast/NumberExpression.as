package it.sephiroth.expr.ast
{
	import hxasm.OpCode;
	
	import it.sephiroth.expr.SWFContext;
	
	public class NumberExpression implements IExpression
	{
		private var _value: Number;
		
		public function NumberExpression( value: Number )
		{
			_value = value;
		}
		
		public function evaluate(): Number
		{
			return _value;
		}
		
		public function toString(): String
		{
			return "" + _value;
		}
		
		public function compile( c: SWFContext ): void
		{
			c.ctx.op( OpCode.OFloat( c.ctx.float( _value ) ) );
			
			c.addStack( 1 );
		}

	}
}