package it.sephiroth.expr.ast
{
	import hxasm.OpCode;
	import hxasm.Operation;
	
	import it.sephiroth.expr.SWFContext;
	
	public class UnaryMinusExpression implements IExpression
	{
		private var _value: IExpression;
		
		public function UnaryMinusExpression( value: IExpression )
		{
			_value = value;
		}
		
		public function evaluate(): Number
		{
			return ( - _value.evaluate() );
		}
		
		public function toString(): String
		{
			return _value + " - ";
		}
		
		public function compile( c: SWFContext ): void
		{
			_value.compile( c );
			
			c.ctx.op( OpCode.OOp( Operation.OpNeg ) );
		}

	}
}