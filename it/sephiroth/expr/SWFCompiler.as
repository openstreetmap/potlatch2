package it.sephiroth.expr
{
	import flash.utils.ByteArray;
	
	import hxasm.Context;
	import hxasm.Index;
	import hxasm.OpCode;
	import hxasm.Output;
	import hxasm.Writer;
	
	import it.sephiroth.expr.ast.IExpression;
	
	public class SWFCompiler
	{
		private var _max_stack: int;
		private var _tnumber: Index;
		private var _tany: Index;
		private var _context: Context;
		
		private var _symbols: SymbolTable;
		private var _expression: IExpression;
		
		public function SWFCompiler( expression: IExpression, symbols: SymbolTable )
		{
			_max_stack = 0;
			
			_symbols = symbols;
			_expression = expression;
		}
		
		public function compile(): ByteArray
		{
			var name: String;
			
			_context = new Context();
			
			_tnumber = _context.type( "Number" );
			_tany = _context.type( "*" );
			_context.beginClass( "CompiledExpression" );
			
			var m: * = _context.beginMethod( "execute", [], _tnumber );
			
			for each( name in _symbols.symbolNames )
			{
				_context.defineField( name, _tany );
			}
			
			var c: SWFContext = new SWFContext( _context );
			
			for each( name in _symbols.symbolNames )
			{
				c.storeReg( name );
			}
			
			_expression.compile( c );
			
			m.maxStack = c.maxStack;
			 
			_context.op( OpCode.ORet );
			
			_context.finalize();
			
			var output: Output = new Output();
			
			Writer.write( output, _context );
			
			return output.getBytes();
			
		}

	}
}