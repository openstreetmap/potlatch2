package org.as3yaml.util
{
	public class StringUtils
	{
	    public static function startsWith(str:String, start:String):Boolean {
	      return new RegExp('^' + start, '').test(str);
	    }
	    public static function isDigit(str:String):Boolean{
	    	return /\d+/.test(str);
	    }	    
	}
}