package org.rxr.actionscript.io
{

	/**
	 * 
	 * Simple class for manipulating a string.
	 * 
	 * @author wischusen
	 * 
	 */	
	public class StringWriter
	{
	
		private var value : String = "";
		private var buffer : String = "";
			
		public function write (str : String) : void
		{
			buffer += str;
		}
		
		public function flush () : void
		{
			value += buffer;
			buffer = "";
		}
		
		
		public function clear () : void
		{
			value = buffer = "";
		}
		
		public function toString() : String
		{
			return value;
		}
	
	}
	
}