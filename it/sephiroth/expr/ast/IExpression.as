package it.sephiroth.expr.ast
{
	import hxasm.Context;
	
	import it.sephiroth.expr.SWFContext;
	
	public interface IExpression
	{
		function evaluate(): Number;
		function compile( stack: SWFContext ): void;
		
		function toString(): String;
	}
}