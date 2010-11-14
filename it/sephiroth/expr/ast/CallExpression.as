package it.sephiroth.expr.ast
{
	import hxasm.OpCode;
	
	import it.sephiroth.expr.Ident;
	import it.sephiroth.expr.SWFContext;
	import it.sephiroth.expr.errors.ExpressionError;
	
	public class CallExpression implements IExpression
	{
		private var _name: Ident;
		private var _arguments: Array;
		
		public function CallExpression( name: Ident, arguments: Array )
		{
			_name = name;
			_arguments = arguments;
		}
		
		public function evaluate(): Number
		{
			var args: Array = new Array();
			
			for each( var argument: IExpression in _arguments )
			{
				args.push( argument.evaluate() );
			}
			
			if( !_name.value )
			{
				throw new ExpressionError( "Unknown function " + _name.id );
			}
			
			return ( _name.value as Function ).apply( null, args );
		}
		
		public function toString(): String
		{
			var args: Array = new Array();
			
			for each( var argument: IExpression in _arguments )
			{
				args.push( argument.toString() );
			}
			
			return "( " + args.join( ", " ) + " ) " + _name;
		}
		
		public function compile( c: SWFContext ): void
		{
			var l: int = _arguments.length;
			
			c.ctx.op( OpCode.OThis );
			
			for each( var e: IExpression in _arguments )
			{
				e.compile( c );
			}
			
			c.ctx.op( OpCode.OCallProperty( c.ctx.property( _name.id ), l ) );
			
			c.addStack( 2 );
		}

	}
}