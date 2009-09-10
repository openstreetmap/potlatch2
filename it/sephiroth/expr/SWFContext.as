package it.sephiroth.expr
{
	import hxasm.Context;
	import hxasm.OpCode;
	
	public class SWFContext
	{
		private var _stack: int;
		private var _max_stack: int;
		private var _context: Context;
		private var _regs: Object;
		
		public function SWFContext( context: Context )
		{
			_stack = 0;
			_max_stack = 0;
			_regs = new Object();
			_context = context;
		}
		
		public function get ctx(): Context
		{
			return _context;
		}
		
		public function get maxStack(): int
		{
			return _max_stack;
		}
		
		public function addStack( i: int ): void
		{
			_stack += i;
			_max_stack = Math.max( _stack, _max_stack );
		}
		
		public function subStack( i: int ): void
		{
			_stack -= i;
			_max_stack = Math.max( _stack, _max_stack );
		}
		
		public function storeReg( name: String ): void
		{
			var reg: int = _context.allocRegister();
			
			_context.op( OpCode.OThis );
			_context.op( OpCode.OGetProp( _context.property( name ) ) );
			_context.op( OpCode.OSetReg( reg ) );
			
			_regs[ name ] = reg;
			
			addStack( 1 );
		}
		
		public function getReg( name: String ): int
		{
			return _regs[ name ];
		}

	}
}