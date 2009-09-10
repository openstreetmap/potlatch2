package it.sephiroth.expr
{
	import it.sephiroth.expr.ast.AddExpression;
	import it.sephiroth.expr.ast.CallExpression;
	import it.sephiroth.expr.ast.DivExpression;
	import it.sephiroth.expr.ast.IExpression;
	import it.sephiroth.expr.ast.IdentExpression;
	import it.sephiroth.expr.ast.MulExpression;
	import it.sephiroth.expr.ast.NumberExpression;
	import it.sephiroth.expr.ast.SubExpression;
	import it.sephiroth.expr.ast.UnaryMinusExpression;
	import it.sephiroth.expr.ast.UnaryPlusExpression;
	import it.sephiroth.expr.errors.ExpressionError;
	
	public class Parser
	{
		private var _token: Token;
		private var _scanner: Scanner;
		private var _symbols: SymbolTable;
		
		public function Parser( scanner: Scanner )
		{
			_scanner = scanner;
			_symbols = new SymbolTable();
		}
		
		public function parse(): CompiledExpression
		{
			_token = _scanner.nextToken();
			var expr: IExpression = parseExpression();
			
			if( _token.type == TokenType.EOF )
			{
				return new CompiledExpression( expr, _symbols );
			}else
			{
				throw new ExpressionError( "Unexpected token: " + _token );
			}
		}
		
		private function parseExpression(): IExpression
		{
			var operator: int;
			var left: IExpression;
			var right: IExpression;
			
			left = parseTerm();
			
			while( ( _token.type == TokenType.ADD ) || ( ( _token.type == TokenType.SUB ) ) )
			{
				operator = _token.type;
				_token = _scanner.nextToken();
				right = parseTerm();
				
				if( operator == TokenType.ADD )
				{
					left = new AddExpression( left, right );
				}else
				{
					left = new SubExpression( left, right );
				}
			}
			
			return left;
		}
		
		private function parseTerm(): IExpression
		{
			var operator: int;
			var left: IExpression;
			var right: IExpression;
			
			left = parseFactor();
			
			while( ( _token.type == TokenType.MUL ) || ( ( _token.type == TokenType.DIV ) ) )
			{
				operator = _token.type;
				_token = _scanner.nextToken();
				right = parseFactor();
				
				if( operator == TokenType.MUL )
				{
					left = new MulExpression( left, right );
				}else
				{
					left = new DivExpression( left, right );
				}
			}
			
			return left;
		}
		
		private function parseFactor(): IExpression
		{
			var tree: IExpression;
			var unary: Array = new Array();
			
			while( ( _token.type == TokenType.ADD ) || ( ( _token.type == TokenType.SUB ) ) )
			{
				unary.push( _token );
				_token = _scanner.nextToken();
			}
			
			switch( _token.type )
			{
				case TokenType.NUM:
					tree = new NumberExpression( _token.value );
					_token = _scanner.nextToken();
					break;
				
				case TokenType.IDENT:
					var ident_name: String = _token.value;
					var ident: Ident = _symbols.findAndAdd( ident_name );
					tree = new IdentExpression( ident );
					_token = _scanner.nextToken();
					
					if( _token.type == TokenType.LEFT_PAR )
					{
						var arguments: Array = new Array();
						_token = _scanner.nextToken();
						
						if( _token.type != TokenType.RIGHT_PAR )
						{
							do
							{
								arguments.push( parseExpression() );
							} while( _token.type == TokenType.COMMA );
							
							if( _token.type != TokenType.RIGHT_PAR )
							{
								throw new ExpressionError( "Unexpected token " + _token + ", expecting )" );
							}else
							{
								_token = _scanner.nextToken();
							}
						}
						
						tree = new CallExpression( ident, arguments );
					}
					
					break;
				
				case TokenType.LEFT_PAR:
					_token = _scanner.nextToken();
					tree = parseExpression();
					if( _token.type == TokenType.RIGHT_PAR )
					{
						_token = _scanner.nextToken();
					}else
					{
						throw new ExpressionError( "Unexpected token " + _token + ", expecting )" );
					}
					break;
				
				default:
					throw new ExpressionError( "Unexpected token " + _token );
					break;
					
			}
			
			while( unary.length > 0 )
			{
				if( unary.pop().type == TokenType.ADD )
				{
					tree = new UnaryPlusExpression( tree );
				}else
				{
					tree = new UnaryMinusExpression( tree );
				}
			}
			
			return tree;
		}

	}
}