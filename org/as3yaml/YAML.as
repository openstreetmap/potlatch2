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


import org.idmedia.as3commons.util.ArrayList;
import org.idmedia.as3commons.util.Iterator;
import org.idmedia.as3commons.util.List;
import org.rxr.actionscript.io.*;

/**
 * 
 * This all static class provides methods for encoding and decoding YAML.  The primary methods are YAML.encode()
 * and YAML.decode().  YAML.load() and YAML.Dump() are for advanced users.
 * 
 * @author wischusen
 * 
 */
public class YAML {
    public static const DEFAULT_SCALAR_TAG : String = "tag:yaml.org,2002:str";
    public static const DEFAULT_SEQUENCE_TAG : String = "tag:yaml.org,2002:seq";
    public static const DEFAULT_MAPPING_TAG : String = "tag:yaml.org,2002:map";

    /**
     * @private
     */    
    public static var ESCAPE_REPLACEMENTS : Object = new Object();
    
    static: {
    ESCAPE_REPLACEMENTS['\x00'] = "0";
    ESCAPE_REPLACEMENTS['\u0007'] = "a";
    ESCAPE_REPLACEMENTS['\u0008'] = "b";
    ESCAPE_REPLACEMENTS['\u0009'] = "t";
    ESCAPE_REPLACEMENTS['\n'] = "n";
    ESCAPE_REPLACEMENTS['\u000B'] = "v";
    ESCAPE_REPLACEMENTS['\u000C'] = "f";
    ESCAPE_REPLACEMENTS['\r'] = "r";
    ESCAPE_REPLACEMENTS['\u001B'] = "e";
    ESCAPE_REPLACEMENTS['"'] = "\"";
    ESCAPE_REPLACEMENTS['\\'] = "\\";
    ESCAPE_REPLACEMENTS['\u0085'] = "N";
    ESCAPE_REPLACEMENTS['\u00A0'] = "_";
    }
	
	/**
	 * Takes an object and converts it to a YAML encoded string.
	 * 
	 * @example 
	 * 
	 * 
	 * <listing version="3.0"> 
	 * 
	 * var map : Map = new HashMap();
	 * map.put("a","1");
	 * map.put("b","2");
	 * map.put("c","3");
	 * trace(YAML.encode(map));
	 * -->
	 *   ---
	 *   a: 1
	 *   b: 2
	 *   c: 3
	 * 
	 * 
	 * var list : Array = new Array("a","b","c");
	 * trace(YAML.encode(ex));
	 * -->
	 *    --- 
	 *    - a
	 *    - b
	 *    - c
	 *
	 * 
	 * var customers : Map = new HashMap();
	 * var customer : Map = new HashMap();
	 * customers.put("customer", customer);
	 * customer.put("firstname", "Derek");
	 * customer.put("lastname", "Wischusen");
	 * customer.put("items", ["skis", "boots", "jacket"]);
	 * trace(YAML.encode(customers));
	 * --> 
	 *   --- 
	 *   customer: 
	 *     firstname: Derek
	 *     lastname: Wischusen
	 *     items: 
	 *       - skis
	 *       - boots
	 *       - jacket
	 * 
	 * // The following is an example of encoding a custom ActionScript class.
	 * 
	 * package org.as3yaml.test
	 * {
	 *		[Bindable]
	 *		public class TestActionScriptObject
	 *		{
	 *			public var firstname : String;
	 *			public var lastname : String;
	 *			public var birthday : Date;
	 *			
	 *		}
	 *	}
	 * 
	 * var testObj : TestActionScriptObject =  new TestActionScriptObject();
	 * testObj.firstname = "Derek";
	 * testObj.lastname = "Wischusen";
	 * testObj.birthday = new Date(1979, 11, 25);
	 * 
	 * trace(YAML.encode(testObj));
	 * -->
	 *   --- !actionscript/object:org.as3yaml.test.TestActionScriptObject
	 *   birthday: 1979-12-25 24:00:00 -05:00
	 *   firstname: Derek
	 *   lastname: Wischusen
	 * 
	 * </listing>
	 * 
	 * 
	 * 
	 * @param obj the object to be encoded as a YAML string.
	 * @return a YAML encoded String.
	 * 
	 */	
	
	public static function encode(obj : Object) : String
	{
		var lst : List = new ArrayList();
		lst.add(obj);
		var yamlStr : StringWriter = new StringWriter();
		YAML.dump(lst, yamlStr,	new DefaultYAMLFactory(), new DefaultYAMLConfig());
		return yamlStr.toString();
	}

    /**
     * 
     * Takes a YAML string an converts it to an ActionScript Object.
	 * 
	 * @example 
	 * 
	 * With the following YAML is stored in a file called myYaml.yaml
	 * 
	 * <listing version="3.0">
	 * 
	 * ---
	 *	Date: 2001-11-23 15:03:17 -5
	 *	User: ed
	 *	Fatal:
	 *	  Unknown variable "bar"
	 *	Stack:
	 *	  - file: TopClass.py
	 *	    line: 23
	 *	    code: |
	 *	      x = MoreObject("345\n")
	 *	  - file: MoreClass.py
	 *	    line: 58
	 *	    code: |-
	 *	      foo = bar 
     *
	 * 
	 * </listing>
	 * 
	 * You can load then load the YAML and decode it as follows.
	 * 
	 * <listing version="3.0">
	 * 	public function loadYaml() : void
	 *  {
	 *		var loader : URLLoader =  new URLLoader();
	 *		loader.load(new URLRequest('myYaml.yaml'));
	 *		loader.addEventListener(Event.COMPLETE, onYamlLoad);
	 *  }
	 *		
	 *	public function onYamlLoad(event : Event) : void
	 *	{
	 *		var yamlMap : Dictionary = YAML.decode(event.target.data) as Dictionary; // returns a Dictionary		
	 *		
	 *      trace(yamlMap.Date);  // returns a Date object and prints: Fri Nov 23 15:03:17 GMT-0500 2001
	 *      trace(yamlMap.User);  // returns a String and prints: ed
	 *      trace(yamlMap.Fatal); // returns a String and prints: Unknown variable "bar"
	 *      trace(yamlMap.Stack); // returns an Array and prints: [object Dictionary],[object Dictionary]
	 *      trace(yamlMap.Stack[0].line);  // returns an Int and prints: 23
	 *      trace(yamlMap.Stack[0].code);  // returns a String and prints: x = MoreObject("345\n")      
	 *	}
	 *  </listing>
	 *  
	 * AS3YAML defines one custom tag: !actionscript/object:path.to.Class. This tag can be used to create custom
	 * actionscript classes from YAML. For example, if you have the following class:
	 * 
	 * <listing version="3.0">
	 * package org.as3yaml.test
	 * {
	 *		[Bindable]
	 *		public class TestActionScriptObject
	 *		{
	 *			public var firstname : String;
	 *			public var lastname : String;
	 *			public var birthday : Date;
	 *			
	 *		}
	 *	}
	 * </listing>
	 * 
	 * You can instruct AS3YAML to create an instance of this class as follows:
	 * 
	 * <listing version="3.0">
	 * var yamlObj : TestActionScriptObject = YAML.decode("--- !actionscript/object:org.as3yaml.test.TestActionScriptObject\nfirstname: Derek\nlastname: Wischusen\nbirthday: 1979-12-25\n") as TestActionScriptObject;
	 * 
	 * trace(yamlObj.firstname); // prints: Derek
	 * trace(yamlObj.lastname);  // prints: Wischusen
	 * trace(yamlObj.birthday);  // prints: Tue Dec 25 00:00:00 GMT-0500 1979
	 * </listing>
	 * 
     * @param yaml a YAML string.
     * @return an actionscript object. The object type will depend on the YAML. 
     *            The most common return types are Dictionary or Array.
     * 
     */    
    public static function decode (yaml : String) : Object
    {
    	
    	var cfg: DefaultYAMLConfig = new DefaultYAMLConfig();
		var obj : Object = YAML.load(yaml, 
									 new DefaultYAMLFactory(),
									 cfg);
		return obj;
    }

    public static function dump (data : List, output : StringWriter, fact : YAMLFactory, cfg : YAMLConfig) : void 
    {
        var serializer : Serializer = fact.createSerializer(fact.createEmitter(output,cfg),fact.createResolver(),cfg);
        try {
            serializer.open();
            var r : Representer = fact.createRepresenter(serializer,cfg);
            for(var iter : Iterator = data.iterator(); iter.hasNext();) {
                r.represent(iter.next());
            }
        } catch(e : Error) {
            throw new YAMLException(e.getStackTrace());
        } finally {
            try { 
            	serializer.close(); 
            } catch(e : Error) {/*Nothing to do in this situation*/}
        }
    }

    public static function load(io : String, fact : YAMLFactory, cfg : YAMLConfig) : Object 
    {
        var ctor : Constructor = fact.createConstructor(fact.createComposer(fact.createParser(fact.createScanner(io),cfg),fact.createResolver()));
        if(ctor.checkData()) {
            return ctor.getData();
        } else {
            return null;
        }
    }
    
}
}
