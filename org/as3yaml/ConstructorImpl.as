/*
 * Copyright (c) 2007 Derek Wischusen
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of 
 * this software and associated documentation files (the "Software"), to deal in 
 * the Software without restriction, including without limitation the rights to 
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
 * SOFTWARE.
 */

package org.as3yaml {

    import flash.utils.Dictionary;
    
    import org.idmedia.as3commons.util.HashMap;
    import org.idmedia.as3commons.util.Map;;
	
	public class ConstructorImpl extends SafeConstructor 
	{
	    private static var yamlConstructors : Dictionary = new Dictionary();
	    private static var yamlMultiConstructors : Dictionary = new Dictionary();
	    private static var yamlMultiRegexps : HashMap = new HashMap();
	    
	    override public function getYamlConstructor(key:Object) : Function {
	  	
	        var ctor : Function = yamlConstructors[key];
	        
	        if(ctor == null) {
	          ctor = super.getYamlConstructor(key);
	        }   
	        return ctor;
	    }
	
	    override public function getYamlMultiConstructor(key : Object) : Function {
	        
	        var ctor : Function = yamlMultiConstructors[key];
	        
	        if(ctor == null) {
	         ctor = super.getYamlMultiConstructor(key);
	        } 
	           
	        return ctor;
	    }
	
	    override public function getYamlMultiRegexp(key : Object) : RegExp {
	        var mine : RegExp =  yamlMultiRegexps.get(key);
	        if(mine == null) {
	            mine = super.getYamlMultiRegexp(key);
	        }
	        return mine;
	    }
	
	    override public function getYamlMultiRegexps() : Map {
	        var all : Map = new HashMap();
	        all.putAll(super.getYamlMultiRegexps());
	        all.putAll(yamlMultiRegexps);
	        return all;
	    }
	
	    public static function addConstructor(tag : String, ctor : YamlConstructor) : void {
	        yamlConstructors.put(tag,ctor);
	    }
	
	    public static function addMultiConstructor(tagPrefix : String, ctor : YamlMultiConstructor) : void {
	        yamlMultiConstructors.put(tagPrefix,ctor);
	        yamlMultiRegexps.put(tagPrefix,new RegExp("^"+tagPrefix));
	    }
	
	    public function ConstructorImpl( composer : Composer) {
	        super(composer);
	    }
	
	}
}