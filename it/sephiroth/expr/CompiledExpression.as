package it.sephiroth.expr
{
	import flash.utils.ByteArray;
	
	import it.sephiroth.expr.ast.IExpression;
	
	public class CompiledExpression
	{
		private var _expression: IExpression;
		private var _symbols: SymbolTable;
		
		public function CompiledExpression( expression: IExpression, symbols: SymbolTable )
		{
			_expression = expression;
			_symbols = symbols;
		}
		
		public function execute( context: Object ): Number
		{
			for( var key: String in context )
			{
				var ident: Ident = _symbols.find( key );
				if( ident )
				{
					ident.value = context[ key ];
				}
			}
			
			return _expression.evaluate();
		}
		
		public function toString(): String
		{
			return _expression.toString();
		}
		
		public function compile(): ByteArray
		{
			var compiler: SWFCompiler = new SWFCompiler( _expression, _symbols );
			
			return compiler.compile();
		}

	}
}