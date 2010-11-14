package it.sephiroth.expr.ast
{
	import hxasm.OpCode;
	
	import it.sephiroth.expr.Ident;
	import it.sephiroth.expr.SWFContext;
	
	public class IdentExpression implements IExpression
	{
		private var _value: Ident;
		
		public function IdentExpression( value: Ident )
		{
			_value = value;
		}
		
		public function evaluate(): Number
		{
			return _value.value;
		}
		
		public function toString(): String
		{
			return "" + _value;
		}
		
		public function compile( c: SWFContext ): void
		{
			c.ctx.op( OpCode.OReg( c.getReg( _value.id ) ) );
			
			c.addStack( 1 );

			// added RF to coerce any string values to numbers (so "24"+2 is 26, not "242"). 
			// See http://www.anotherbigidea.com/javaswf/avm2/AVM2Instructions.html .
			// Ideally we need to do proper typing so we can evaluate string expressions
			// too... but not yet!
			c.ctx.op( OpCode.OToNumber );
			c.addStack( 1 );
		}

	}
}