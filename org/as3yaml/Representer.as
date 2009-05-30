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
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import org.as3yaml.events.*;
	import org.as3yaml.nodes.*;
	import org.idmedia.as3commons.util.*;

public class Representer {
    private var serializer : Serializer;
    private var defaultStyle : String;
    private var representedObjects : Map;

    public function Representer(serializer : Serializer, opts : YAMLConfig) : void {
        this.serializer = serializer;
        this.defaultStyle = opts.getUseDouble() ? '"' : (opts.getUseSingle() ? '\'' : '0');
        this.representedObjects = new HashMap();
    }

    private function representData(data : Object) : Node {
        var aliasKey : String = null;
        var node : Node = null;

        if(null != aliasKey) {
            if(this.representedObjects.containsKey(aliasKey)) {
                node = this.representedObjects.get(aliasKey) as Node;
                if(null == node) {
                    throw new RepresenterException("recursive objects are not allowed: " + data);
                }
                return node;
            }
            this.representedObjects.put(aliasKey,null);
        }

        node = getNodeCreatorFor(data).toYamlNode(this);

        if(aliasKey != null) {
            this.representedObjects.put(aliasKey,node);
        }

        return node;
    }

    public function scalar(tag : String, value : String, style : String): Node {
        return representScalar(tag,value,style);
    }

    public function representScalar(tag : String, value : String, style : String): Node {
        var realStyle : String = style == '0' ? this.defaultStyle : style;
        return new ScalarNode(tag,value,style);
    }

    public function seq(tag : String, sequence : List, flowStyle : Boolean): Node {
        return representSequence(tag,sequence,flowStyle);
    }

    public function representSequence(tag : String, sequence : List, flowStyle : Boolean): Node {
        var value : Array = new Array();
        for(var iter : Iterator = sequence.iterator();iter.hasNext();) {
            value.push(representData(iter.next()));
        }
        return new SequenceNode(tag,value,flowStyle);
    }

    public function map(tag : String, mapping : Object, flowStyle : Boolean) : Node {
        return representMapping(tag,mapping,flowStyle);
    }

    public function representMapping(tag : String, mapping : Object, flowStyle : Boolean): Node {
        var value : HashMap = new HashMap();
        for(var iter : Iterator = mapping.keySet().iterator();iter.hasNext();) {
            var itemKey : Object = iter.next();
            var itemValue : Object = mapping.get(itemKey);
            value.put(representData(itemKey), representData(itemValue));
        }
        return new MappingNode(tag,value,flowStyle);
    }

    public function represent(data : Object) : void {
        var node : Node = representData(data);
        this.serializer.serialize(node);
        this.representedObjects.clear();
    }

    protected function ignoreAliases(data : Object) : Boolean {
        return false;
    }

    protected function getNodeCreatorFor(data : Object) : YAMLNodeCreator {
        if(data is YAMLNodeCreator) {
            return data as YAMLNodeCreator;
        } else if(data is Map) {
            return new MappingYAMLNodeCreator(data);
        } else if(data is Array) {
            return new ArrayYAMLNodeCreator(data as Array);
        } else if(data is Date) {
            return new DateYAMLNodeCreator(data as Date);
        } else if(data is String) {
            return new StringYAMLNodeCreator(data);
        } else if(data is Number) {
            return new NumberYAMLNodeCreator(data);
        } else if(data is Boolean) {
            return new ScalarYAMLNodeCreator("tag:yaml.org,2002:bool",data);
        } else if(data == null) {
            return new ScalarYAMLNodeCreator("tag:yaml.org,2002:null","");
        } else if(data is ByteArray) {
            return new BinaryYAMLNodeCreator(data);
        } else { // if none of the above, serialize as an actionscript object
            return new ActionScriptObjectNodeCreator(data);
        }
    }


    }
}


import org.as3yaml.YAMLNodeCreator;
import mx.formatters.DateFormatter;
import org.idmedia.as3commons.util.Set;
import org.idmedia.as3commons.util.Map;
import org.idmedia.as3commons.util.Iterator;
import org.idmedia.as3commons.util.ArrayList;
import flash.utils.getQualifiedClassName;
import org.idmedia.as3commons.util.List;
import org.as3yaml.nodes.Node;
import org.as3yaml.Representer;
import org.idmedia.as3commons.util.HashMap;
import mx.utils.ObjectUtil;
import flash.utils.ByteArray;
import mx.utils.Base64Encoder;
import flash.utils.Dictionary;

internal class DateYAMLNodeCreator implements YAMLNodeCreator {
    private var data : Date;
    public function DateYAMLNodeCreator(data : Date) {
        this.data = data as Date;
    }

    public function taguri() : String {
        return "tag:yaml.org,2002:timestamp";
    }

    private static var dateOutput : DateFormatter  = new DateFormatter();
    dateOutput.formatString = "YYYY-MM-DD HH:NN:SS";
    private static var dateOutputUsec : DateFormatter = new DateFormatter();
    dateOutputUsec.formatString = "YYYY-MM-DD HH:NN:SS.SSS";
    public function toYamlNode(representer : Representer) : Node {
        var date : Date = new Date();
        
        var out : String = null;
        if(data.milliseconds != 0) {
            out = dateOutputUsec.format(data);
        } else {
            out = dateOutput.format(data);
        }
        var ts : String = date.toTimeString();
        var timeZoneOffset : String = ts.substring(ts.indexOf("GMT") + 3);
        timeZoneOffset = timeZoneOffset.substring(0, timeZoneOffset.length-2) + ":" + timeZoneOffset.substring(timeZoneOffset.length-2);  

        out += " " + timeZoneOffset;
        return representer.scalar(taguri(), out, "0");
    }
}


internal class ArrayYAMLNodeCreator implements YAMLNodeCreator {
    private var data : Array;
    public function ArrayYAMLNodeCreator(data : Array) {
        this.data = data;
    }

    public function taguri() : String {
        return "tag:yaml.org,2002:seq";
    }

    public function toYamlNode(representer : Representer) : Node {
        var l : int = data.length;
        var lst : ArrayList = new ArrayList();
        for(var i:int=0;i<l;i++) {
            lst.add(data[i]);
        }
        return representer.seq(taguri(), lst, false);
    }
}

internal class NumberYAMLNodeCreator implements YAMLNodeCreator {
    private var data : Number;
    public function NumberYAMLNodeCreator(data : Object) {
        this.data = data as Number;
    }

    public function taguri() : String {
        if(data is Number) {
            return "tag:yaml.org,2002:float";
        } else {
            return "tag:yaml.org,2002:int";
        }
    }

     public function toYamlNode(representer : Representer) : Node {
        var str : String = String(data);
        if(str == ("Infinity")) {
            str = ".inf";
        } else if(str == ("-Infinity")) {
            str = "-.inf";
        } else if(str == ("NaN")) {
            str = ".nan";
        }
        return representer.scalar(taguri(), str, '0');
    }
}

internal class ScalarYAMLNodeCreator implements YAMLNodeCreator {
    private var tag : String;
    private var data : Object;
    public function ScalarYAMLNodeCreator(tag : String, data : Object) {
        this.tag = tag;
        this.data = data;
    }

    public function taguri() : String {
        return this.tag;
    }

     public function toYamlNode(representer : Representer) : Node {
        return representer.scalar(taguri(), data.toString(), '0');
    }
}

internal class StringYAMLNodeCreator implements YAMLNodeCreator {
    private var data : Object;
    public function StringYAMLNodeCreator(data : Object) {
        this.data = data;
    }

    public function taguri() : String {
        if(data is String) {
            return "tag:yaml.org,2002:str";
        } else {
            return "tag:yaml.org,2002:str:" + getQualifiedClassName(data);
        }
    }

     public function toYamlNode(representer : Representer) : Node {
        return representer.scalar(taguri(), data.toString(), '0');
    }
}

internal class SequenceYAMLNodeCreator implements YAMLNodeCreator {
    private var data : List;
    public function SequenceYAMLNodeCreator(data : Object) {
        this.data = data as List;
    }

    public function taguri() : String {
        if(data is ArrayList) {
            return "tag:yaml.org,2002:seq";
        } else {
            return "tag:yaml.org,2002:seq:" + getQualifiedClassName(data);
        }
    }

     public function toYamlNode(representer : Representer) : Node {
        return representer.seq(taguri(), data, false);
    }
}

internal class MappingYAMLNodeCreator implements YAMLNodeCreator {
    private var data : Object;
    public function MappingYAMLNodeCreator(data : Object) {
        this.data = data as Map;
    }

    public function taguri() : String {
        if(data is HashMap) {
            return "tag:yaml.org,2002:map";
        } else {
            return "tag:yaml.org,2002:map:"+getQualifiedClassName(data);
        }
    }

     public function toYamlNode(representer : Representer) : Node {
        return representer.map(taguri(), data, false);
    }
}

internal class BinaryYAMLNodeCreator implements YAMLNodeCreator {
    private var data : ByteArray;
    public function BinaryYAMLNodeCreator(data : Object) {
        this.data = data as ByteArray;
    }

    public function taguri() : String {
       return "tag:yaml.org,2002:binary";
    }

     public function toYamlNode(representer : Representer) : Node {
     	var encoder : Base64Encoder = new Base64Encoder();
     	encoder.encodeBytes(data);
     	var base64Data : String = encoder.flush() + '\n';
        return representer.scalar(taguri(), base64Data, '|');
    }
}

internal class ActionScriptObjectNodeCreator implements YAMLNodeCreator {
    private var data : Object;
    public function ActionScriptObjectNodeCreator(data : Object) : void {
        this.data = data;
    }

    public function taguri() : String {
        var className : String = getQualifiedClassName(data);
        className = className.replace("::", ".");
        return "!actionscript/object:" + className;
    }

     public function toYamlNode(representer : Representer) : Node {
        var values : Map = new HashMap();
        var props : Array = ObjectUtil.getClassInfo(data).properties;
        for each(var prop : String in props) {

            try {
                values.put(prop, data[prop]);
            } catch(exe : Error) {
                values.put(prop, null);
            }

            
        }
        return representer.map(taguri(),values,false);
    }
}
