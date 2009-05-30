/* Copyright (c) 2007 Derek Wischusen
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
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

import mx.utils.Base64Decoder;
import mx.utils.ObjectUtil;

import org.as3yaml.nodes.Node;
import org.idmedia.as3commons.util.ArrayList;
import org.idmedia.as3commons.util.Collection;
import org.idmedia.as3commons.util.HashMap;
import org.idmedia.as3commons.util.Map;
import org.as3yaml.util.StringUtils;

public class SafeConstructor extends BaseConstructor {
    private static var yamlConstructors : Dictionary = new Dictionary();
    private static var yamlMultiConstructors : Dictionary = new Dictionary();
    private static var yamlMultiRegexps : Map = new HashMap();
   
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
        var mine : RegExp = yamlMultiRegexps.get(key);
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

    public static function addConstructor(tag : String, ctor : Function) : void {
        yamlConstructors[tag] = ctor;
    }

    public static function addMultiConstructor(tagPrefix : String, ctor : Function) : void {
        yamlMultiConstructors[tagPrefix] = ctor;
        yamlMultiRegexps.put(tagPrefix, new RegExp("^"+tagPrefix));
    }

    public function SafeConstructor(composer : Composer) {
        super(composer);
    }

    private static var BOOL_VALUES : Object = {
										        yes     : true,
										        no      : false,
										        "true"  : true,
										        "false" : false,
										        on      : true,
										        off     : false
    										  };

    public static function constructYamlNull(ctor : Constructor, node : Node) : Object {
        return null;
    }
    
    public static function constructYamlBool(ctor : Constructor, node : Node) : Object {
        var val : String = ctor.constructScalar(node) as String;
        return BOOL_VALUES[val.toLowerCase()];
    }

    public static function constructYamlOmap(ctor : Constructor, node : Node) : Object {
        return ctor.constructOmap(node);
    }

    public static function constructYamlPairs(ctor : Constructor, node : Node) : Object {
        return ctor.constructPairs(node); 
    }

    public static function constructYamlSet(ctor : Constructor, node : Node) : Object {
        return Map(ctor.constructMapping(node)).keySet();
    }

    public static function constructYamlStr(ctor : Constructor, node : Node) : Object {
        var value : String = ctor.constructScalar(node) as String;
        return value.length == 0 ? null : value;
    }

    public static function constructYamlSeq(ctor : Constructor, node : Node) : Object {
        return ctor.constructSequence(node);
    }

    public static function constructYamlMap(ctor : Constructor, node : Node) : Object {
        return ctor.constructMapping(node);
    }

    public static function constructUndefined(ctor : Constructor, node : Node) : Object {
        throw new ConstructorException(null,"could not determine a constructor for the tag " + node.getTag(),null);
    }

    private static var TIMESTAMP_REGEXP : RegExp = new RegExp("^([0-9][0-9][0-9][0-9])-([0-9][0-9]?)-([0-9][0-9]?)(?:(?:[Tt]|[ \t]+)([0-9][0-9]?):([0-9][0-9]):([0-9][0-9])(?:\\.([0-9]*))?(?:[ \t]*(?:Z|([-+][0-9][0-9]?)(?::([0-9][0-9])?)?))?)?$");
    private static var YMD_REGEXP : RegExp = new RegExp("^([0-9][0-9][0-9][0-9])-([0-9][0-9]?)-([0-9][0-9]?)$");
    public static function constructYamlTimestamp(ctor : Constructor, node : Node) : Object {
        var match : Object = YMD_REGEXP.exec(String(node.getValue()));

        var year_s : String;
        var month_s : String;
        var day_s : String;
        var time : Date = null;
       
        if(match) {
            year_s = match[1];
            month_s = match[2];
            day_s = match[3];
            
            if(year_s == null || month_s == null || day_s == null) {
               throw new ConstructorException(null, "bad date value: " + node.getValue(), null);
            }

            return new Date(year_s,int(month_s)-1,day_s);
        }
        match = TIMESTAMP_REGEXP.exec(String(node.getValue()));
        if(!match) {
            return ctor.constructPrivateType(node);
        }
        
        year_s = match[1];
        month_s = match[2];
        day_s = match[3];
        
        var hour_s: String = match[4];
        var min_s: String = match[5];
        var sec_s: String = match[6];
        var fract_s: String = match[7];
        var timezoneh_s: String = match[8];
        var timezonem_s: String = match[9];
        
        var usec : int = 0;
        if(fract_s != null) {
            usec = int(fract_s);
            if(usec != 0) {
                while(10*usec < 1000) {
                    usec *= 10;
                }
            }
        }
        
        time = new Date();
        
        if(month_s != null && day_s != null) {
            time.setMonth(int(month_s)-1, day_s);
        }      
        if(year_s != null) {
            time.setFullYear(year_s);
        }
        if(hour_s != null) {
            time.setHours(hour_s);
        }
        if(min_s != null) {
            time.setMinutes(min_s);
        }
        if(sec_s != null) {
            time.setSeconds(sec_s);
        }
        time.setMilliseconds(usec);
        if(timezoneh_s != null || timezonem_s != null) {
            var zone : int = 0;
            var sign : int = 1;
            if(timezoneh_s != null) {
                if(timezoneh_s.charAt(0) == ("-")) {
                    sign = -1;
                }
                zone += int(timezoneh_s.substring(1))*3600000;
            }
            if(timezonem_s != null) {
                zone += int(timezonem_s)*60000;
            }
        }
        return time;
    }

    public static function constructYamlInt(ctor : Constructor, node : Node) : Object {
        var value : String = String(ctor.constructScalar(node)).replace(/_/g,"");
        var sign : int = +1;
        var first : String = value.charAt(0);
        if(first == '-') {
            sign = -1;
            value = value.substring(1);
        } else if(first == '+') {
            value = value.substring(1);
        }
        var base : int = 10;
        if(value == ("0")) {
            return 0;
        } else if(StringUtils.startsWith(value, "0b")) {
            value = value.substring(2);
            base = 2;
        } else if(StringUtils.startsWith(value, "0x")) {
            value = value.substring(2);
            base = 16;
        } else if(value.charAt(0) == ("0")) {
            value = value.substring(1);
            base = 8;
        } else if(value.indexOf(':') != -1) {
            var digits : Array = value.split(":");
            var bes : int = 1;
            var val : int = 0;
            for(var i:int=0,j:int=digits.length;i<j;i++) {
                val += (Number(digits[(j-i)-1])*bes);
                bes *= 60;
            }
            return new int(sign*val);
        } else {
            return sign * parseInt(value, base);//new Number(sign * int(value));
        }
        return (sign * parseInt(value, base));
    }

    private static var INF_VALUE_POS : Number  = new Number(Number.POSITIVE_INFINITY);
    private static var INF_VALUE_NEG : Number = new Number(Number.NEGATIVE_INFINITY);
    private static var NAN_VALUE : Number = new Number(Number.NaN);

    public static function constructYamlFloat(ctor : Constructor, node : Node) : Object {
        var value : String = String(ctor.constructScalar(node).toString()).replace(/'_'/g,"");
        var sign : int = +1;
        var first : String = value.charAt(0);
        if(first == '-') {
            sign = -1;
            value = value.substring(1);
        } else if(first == '+') {
            value = value.substring(1);
        }
        var valLower : String = value.toLowerCase();
        if(valLower == (".inf")) {
            return sign == -1 ? INF_VALUE_NEG : INF_VALUE_POS;
        } else if(valLower == (".nan")) {
            return NAN_VALUE;
        } else if(value.indexOf(':') != -1) {
            var digits : Array = value.split(":");
            var bes : int = 1;
            var val : Number = 0.0;
            for(var i:int=0,j:int=digits.length;i<j;i++) {
                val += (Number(digits[(j-i)-1])*bes);
                bes *= 60;
            }
            return new Number(sign*val);
        } else {
            return Number(value) * sign;
        }
    }    

    public static function constructYamlBinary(ctor : Constructor, node : Node) : Object {
        var values : Array = ctor.constructScalar(node).toString().split("[\n\u0085]|(?:\r[^\n])");
        var vals : String = new String();
        for(var i:int=0,j:int=values.length;i<j;i++) {
            vals += (values[i]);
        }
        var decoder : Base64Decoder = new Base64Decoder();
        decoder.decode(vals);
        return decoder.flush();
    }

    public static function constructSpecializedSequence(ctor : Constructor, pref : String, node : Node) : Object {
        var outp : ArrayList = null;
        try {
            var seqClass : Object = getDefinitionByName(pref) as Class;
            outp = new seqClass() as ArrayList;
        } catch(e : Error) {
            throw new YAMLException("Can't construct a sequence from class " + pref + ": " + e.toString());
        }
        var coll : Collection = ctor.constructSequence(node) as Collection;
        outp.addAll(coll);
        return outp;
    }

    public static function constructSpecializedMap(ctor : Constructor, pref : String, node : Node) : Object {
        var outp : Map = null;
        try {
            var mapClass : Class = getDefinitionByName(pref) as Class;
            outp = new mapClass();
        } catch(e : Error) {
            throw new YAMLException("Can't construct a mapping from class " + pref + ": " + e.toString());
        }
        var coll : Map = ctor.constructMapping(node) as Map;
        outp.putAll(coll);
        return outp;
    }

    private static function fixValue(inp : Object, outp : Class) : Object {
        if(inp == null) {
            return null;
        }
        var inClass : Class = getDefinitionByName(getQualifiedClassName(inp)) as Class;
        if(outp is inClass) {
            return inp;
        }
        if(inClass == Number && (outp == int)) {
            return new int(inp);
        }

        if(inClass == Number && (outp == String)) {
            return new String(inp);
        }

        return inp;
    }

    public static function constructActionscript(ctor : Constructor, pref : String, node : Node) : Object {
        var outp : Object = null;
        try {
            var cl : Class = getDefinitionByName(pref) as Class;
            outp = new cl();
            var values : Dictionary = Dictionary(ctor.constructMapping(node));
            var props : Array = ObjectUtil.getClassInfo(outp).properties;
            for(var key : Object in values) {
                var value : Object = values[key];
				outp[key] = value;
            } 
        } catch(e : Error) {
            throw new YAMLException("Can't construct actionscript object from class " + pref + ": " + e.toString());
        }
        return outp;
    }

    static: {
        BaseConstructor.addConstructor("tag:yaml.org,2002:null", function call(self : Constructor, node : Node) : Object {
                    return constructYamlNull(self,node);
            });
        addConstructor("tag:yaml.org,2002:bool", function call(self : Constructor, node : Node) : Object {
                    return constructYamlBool(self,node);
            });
        addConstructor("tag:yaml.org,2002:omap", function call(self : Constructor, node : Node) : Object {
                    return constructYamlOmap(self,node);
            });
        addConstructor("tag:yaml.org,2002:pairs", function call(self : Constructor, node : Node) : Object {
                    return constructYamlPairs(self,node);
            });
        addConstructor("tag:yaml.org,2002:set", function call(self : Constructor, node : Node) : Object {
                    return constructYamlSet(self,node);
            });
        addConstructor("tag:yaml.org,2002:int", function call(self : Constructor, node : Node) : Object {
                    return constructYamlInt(self,node);
            });
        addConstructor("tag:yaml.org,2002:float", function call(self : Constructor, node : Node) : Object {
                    return constructYamlFloat(self,node); 
            });
        addConstructor("tag:yaml.org,2002:timestamp", function call(self : Constructor, node : Node) : Object {
                    return constructYamlTimestamp(self,node);
            });
        addConstructor("tag:yaml.org,2002:timestamp#ymd", function call(self : Constructor, node : Node) : Object {
                    return constructYamlTimestamp(self,node);
            });
        addConstructor("tag:yaml.org,2002:str", function call(self : Constructor, node : Node) : Object {
                    return constructYamlStr(self,node);
            });
        addConstructor("tag:yaml.org,2002:binary", function call(self : Constructor, node : Node) : Object {
                    return constructYamlBinary(self,node);
            });
        addConstructor("tag:yaml.org,2002:seq", function call(self : Constructor, node : Node) : Object {
                    return constructYamlSeq(self,node);
            });
        addConstructor("tag:yaml.org,2002:map", function call(self : Constructor, node : Node) : Object {
                    return constructYamlMap(self,node);
            });
        addConstructor(null, function call(self : Constructor, node : Node) : Object {
                    return self.constructPrivateType(node);
            });

        addMultiConstructor("tag:yaml.org,2002:seq:", function call(self : Constructor, pref : String, node : Node) : Object {
                    return constructSpecializedSequence(self,pref,node);
            });
        addMultiConstructor("tag:yaml.org,2002:map:", function call(self : Constructor, pref : String, node : Node) : Object {
                    return constructSpecializedMap(self,pref,node);
            });
        addMultiConstructor("!actionscript/object:", function call(self : Constructor, pref : String, node : Node) : Object {
                    return constructActionscript(self,pref,node);
           });
 
    }

}
}