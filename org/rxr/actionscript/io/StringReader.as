package org.rxr.actionscript.io
{
	
	public class StringReader
	{
		private var source: String;
		private var sourceLength: uint;
		private var peekCache: String;
		protected var position: uint = 0;
			
		public function get charsAvailable(): uint
		{
			return sourceLength - position;
		}
				
		public function StringReader(string:String="")
		{
			source = string;
			peekCache = source.charAt(0);
			sourceLength = source.length;
		}
		
		public function peek(offset: int = 0): String
		{
			if (offset == 0)
				return peekCache;
	
			return source.charAt(position + offset);
		}
		
		public function peekFor(length: uint, offset:int = 0): String
		{
			return source.substr(position + offset, length);
		}

		public function peekRemaining(): String
		{
			return peekFor(charsAvailable);
		}

		public function read(): String
		{
			var val: String = peekCache;
			forward();
			return val;
		}
		
		public function readFor(length:uint):String
		{
			var pos: uint = position;
			forwardBy(length);
			return source.substr(pos, length);
		}
		
		public function readRemaining(): String
		{
			return readFor(charsAvailable);
		}
				
		public function writeChar(char:String):void
		{
			source += char;
			sourceLength = source.length;
		}		

		public function forward(): void
		{
			position++;
			peekCache = source.charAt(position);
		}
		
		public function forwardBy(num: uint): void
		{
			position+=num;
			peekCache = source.charAt(position);
		}			
	}
}