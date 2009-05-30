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

import org.as3yaml.events.*;
import org.idmedia.as3commons.util.Iterator;
import org.idmedia.as3commons.util.Map;
import org.idmedia.as3commons.util.HashMap;
import org.rxr.actionscript.io.StringWriter;



public class Emitter {

    internal static const STREAM_START : int = 0;
    internal static const FIRST_DOCUMENT_START : int = 1;
    internal static const DOCUMENT_ROOT : int = 2;
    internal static const NOTHING : int = 3;
    internal static const DOCUMENT_START : int = 4;
    internal static const DOCUMENT_END : int = 5;
    internal static const FIRST_FLOW_SEQUENCE_ITEM : int = 6;
    internal static const FLOW_SEQUENCE_ITEM : int = 7;
    internal static const FIRST_FLOW_MAPPING_KEY : int = 8;
    internal static const FLOW_MAPPING_SIMPLE_VALUE : int = 9;
    internal static const FLOW_MAPPING_VALUE : int = 10;
    internal static const FLOW_MAPPING_KEY : int = 11;
    internal static const BLOCK_SEQUENCE_ITEM : int = 12;
    internal static const FIRST_BLOCK_MAPPING_KEY : int = 13;
    internal static const BLOCK_MAPPING_SIMPLE_VALUE : int = 14;
    internal static const BLOCK_MAPPING_VALUE : int = 15;
    internal static const BLOCK_MAPPING_KEY : int = 16;
    internal static const FIRST_BLOCK_SEQUENCE_ITEM : int = 17;
    
    private static var STATES : Array = new Array();
    
    static: {
        STATES[STREAM_START] = function expect(env : EmitterEnvironment) : void {
                    env.expectStreamStart();
                };

        STATES[FIRST_DOCUMENT_START] = function expect(env : EmitterEnvironment) : void {
                    env.expectDocumentStart(true);
                };
            
        STATES[DOCUMENT_ROOT] = function expect(env : EmitterEnvironment) : void {
                    env.expectDocumentRoot();
                };
            
        STATES[NOTHING] =  function expect(env : EmitterEnvironment) : void {
                    env.expectNothing();
                };
            
        STATES[DOCUMENT_START] = function expect(env : EmitterEnvironment) : void {
                    env.expectDocumentStart(false);
                };
            
        STATES[DOCUMENT_END] = function expect(env : EmitterEnvironment ) : void {
                    env.expectDocumentEnd();
                };
            
        STATES[FIRST_FLOW_SEQUENCE_ITEM] = function expect(env : EmitterEnvironment) : void {
                    env.expectFirstFlowSequenceItem();
                };
            
        STATES[FLOW_SEQUENCE_ITEM] = function expect(env : EmitterEnvironment) : void {
                    env.expectFlowSequenceItem();
                };
            
        STATES[FIRST_FLOW_MAPPING_KEY] = function expect(env : EmitterEnvironment) : void {
                    env.expectFirstFlowMappingKey();
                };
            
        STATES[FLOW_MAPPING_SIMPLE_VALUE] = function expect(env : EmitterEnvironment) : void {
                    env.expectFlowMappingSimpleValue();
                };
            
        STATES[FLOW_MAPPING_VALUE] = function expect(env : EmitterEnvironment) : void {
                    env.expectFlowMappingValue();
                };
            
        STATES[FLOW_MAPPING_KEY] = function expect(env : EmitterEnvironment) : void {
                    env.expectFlowMappingKey();
                };
            
        STATES[BLOCK_SEQUENCE_ITEM] = function expect(env : EmitterEnvironment) : void {
                    env.expectBlockSequenceItem(false);
                };
            
        STATES[FIRST_BLOCK_MAPPING_KEY] = function expect(env : EmitterEnvironment) : void {
                    env.expectFirstBlockMappingKey();
                };
            
        STATES[BLOCK_MAPPING_SIMPLE_VALUE] = function expect(env : EmitterEnvironment) : void {
                    env.expectBlockMappingSimpleValue();
                };
            
        STATES[BLOCK_MAPPING_VALUE] = function expect(env : EmitterEnvironment) : void {
                    env.expectBlockMappingValue();
                };
            
        STATES[BLOCK_MAPPING_KEY] = function expect(env : EmitterEnvironment) : void {
                    env.expectBlockMappingKey(false);
                };
            
        STATES[FIRST_BLOCK_SEQUENCE_ITEM] = function expect(env : EmitterEnvironment) : void  {
                    env.expectBlockSequenceItem(true);
                };
            
    }

    public static var DEFAULT_TAG_PREFIXES_1_0 : Map;
    public static var DEFAULT_TAG_PREFIXES_1_1 : Map;
    static: {
        private static var defInit0 : Map = new HashMap();
        defInit0.put("tag:yaml.org,2002:","!");
        DEFAULT_TAG_PREFIXES_1_0 = defInit0;
        private static var defInit : Map = new HashMap();
        defInit.put("!","!");
        defInit.put("tag:yaml.org,2002:","!!");
        DEFAULT_TAG_PREFIXES_1_1 = defInit;
    }

    private var stream : StringWriter;
    private var options : YAMLConfig;
    private var env : EmitterEnvironment;

    public function Emitter(stream : StringWriter, opts : YAMLConfig) {
        this.stream = stream;
        this.options = opts;
        this.env = new EmitterEnvironment();
        this.env.emitter = this;
        this.env.canonical = this.options.getCanonical();
        var propIndent : int = this.options.getIndent();
        if(propIndent>=2 && propIndent<10) {
            this.env.bestIndent = propIndent;
        }
        var propWidth : int = this.options.getBestWidth();
        if(propWidth != 0 && propWidth > (this.env.bestIndent*2)) {
            this.env.bestWidth = propWidth;
        }
    }

    public function getOptions() : YAMLConfig {
        return options;
    }

    public function emit(event : Event) : void {
        this.env.events.add(event);
        while(!this.env.needMoreEvents()) {
            this.env.event = this.env.events.removeAtAndReturn(0);
            STATES[this.env.state](env);
            this.env.event = null;
        }
    }

    internal function writeStreamStart() : void {
    }

    internal function writeStreamEnd() : void {
        flushStream();
    }
    
    internal function writeIndicator(indicator : String, needWhitespace : Boolean, whitespace : Boolean, indentation : Boolean) : void {
        var data : String = null;
        if(!(env.whitespace || !needWhitespace)) {
             data = " " + indicator;
        } else {
        	data = indicator;
        }
        env.whitespace = whitespace;
        env.indentation = env.indentation && indentation;
        env.column += data.length;
        stream.write(data);
    }

    internal function writeIndent() : void {
        var indent : int = 0;
        if(env.indent != -1) {
            indent = env.indent;
        }

        if(!env.indentation || env.column > indent || (env.column == indent && !env.whitespace)) {
            writeLineBreak(null);
        }

        if(env.column < indent) {
            env.whitespace = true;
            var data : String = new String();
            for(var i:int=0;i<(indent-env.column);i++) {
                data += " ";
            }
            env.column = indent;
            stream.write(data);
        }
    }

    internal function writeVersionDirective(version_text : String) : void {
        stream.write("%YAML " + version_text);
        writeLineBreak(null);
    }
    
    internal function writeTagDirective(handle : String, prefix : String) : void {
        stream.write("%TAG " + handle + " " + prefix);
        writeLineBreak(null);
    }

    internal function writeDoubleQuoted(text : String, split : Boolean) : void {
        writeIndicator("\"",true,false,false);
        var start : int = 0;
        var ending : int = 0;
        var data : String = null;
        var textLen: uint = text.length;
        while(ending <= textLen) {
            var ch : * = 0;
            if(ending < textLen) {
                ch = text.charAt(ending);
            }
            if(ch==0 || "\"\\\u0085".indexOf(ch) != -1 || !('\u0020' <= ch && ch <= '\u007E')) {
                if(start < ending) {
                    data = text.substring(start,ending);
                    env.column+=data.length;
                    stream.write(data);
                    start = ending;
                }
                if(ch != 0) {
                    if(YAML.ESCAPE_REPLACEMENTS[ch]) {
                        data = "\\" + YAML.ESCAPE_REPLACEMENTS[ch];
                    } else if(ch <= '\u00FF') {
                        var str : String = new int(ch).toString(16);
                        if(str.length == 1) {
                            str = "0" + str;
                        }
                        data = "\\x" + str;
                    }
                    env.column += data.length;
                    stream.write(data);
                    start = ending+1;
                }
            }
            if((0 < ending && ending < (textLen-1)) && (ch == ' ' || start >= ending) && (env.column+(ending-start)) > env.bestWidth && split) {
                data = text.substring(start,ending) + "\\";
                if(start < ending) {
                    start = ending;
                }
                env.column += data.length;
                stream.write(data);
                writeIndent();
                env.whitespace = false;
                env.indentation = false;
                if(text.charAt(start) == ' ') {
                    data = "\\";
                    env.column += data.length;
                    stream.write(data);
                }
            }
            ending += 1;
        }

        writeIndicator("\"",false,false,false);
    }

    internal function writeSingleQuoted(text : String, split : Boolean) : void {
        writeIndicator("'",true,false,false);
        var spaces : Boolean = false;
        var breaks : Boolean = false;
        var start : int = 0; 
        var ending : int = 0;
        var ceh : String = null;
        var data : String = null;
        while(ending <= text.length) {
            ceh = null;
            if(ending < text.length) {
                ceh = text.charAt(ending);
            }
            if(spaces) {
                if(ceh == null || int(ceh) != 32) {
                    if(start+1 == ending && env.column > env.bestWidth && split && start != 0 && ending != text.length) {
                        writeIndent();
                    } else {
                        data = text.substring(start,ending);
                        env.column += data.length;
                        stream.write(data);
                    }
                    start = ending;
                }
            } else if(breaks) {
                if(ceh == null || !('\n' == ceh)) {
                    data = text.substring(start,ending);
                    for(var i:int=0,j:int=data.length;i<j;i++) {
                        var cha : String = data.charAt(i);
                        if('\n' == cha) {
                            writeLineBreak(null);
                        } else {
                            writeLineBreak(""+cha);
                        }
                    }
                    writeIndent();
                    start = ending;
                }
            } else {
                if(ceh == null || !('\n' == ceh)) {
                    if(start < ending) {
                        data = text.substring(start,ending);
                        env.column += data.length;
                        stream.write(data);
                        start = ending;
                    }
                    if(ceh == '\'') {
                        data = "''";
                        env.column += 2;
                        stream.write(data);
                        start = ending + 1;
                    }
                }
            }
            if(ceh != null) {
                spaces = (ceh == ' ');
                breaks = (ceh == '\n');
            }
            ending++;
        }
        writeIndicator("'",false,false,false);
    }

    internal function writeFolded(text : String) : void  {
        var chomp : String = determineChomp(text);
        writeIndicator(">" + chomp, true, false, false);
        writeIndent();
        var leadingSpace : Boolean = false;
        var spaces : Boolean = false;
        var breaks : Boolean = false;
        var start:int=0,ending:int=0;
        var data : String = null;
        while(ending <= text.length) {
            var ceh : String = null;
            if(ending < text.length) {
                ceh = text.charAt(ending);
            }
            if(breaks) {
                if(ceh == null || !('\n' == ceh || '\u0085' == ceh)) {
                    if(!leadingSpace && ceh != null && ceh != ' ' && text.charAt(start) == '\n') {
                        writeLineBreak(null);
                    }
                    leadingSpace = ceh == ' ';
                    data = text.substring(start,ending);
                    for(var i:int=0,j:int=data.length;i<j;i++) {
                        var cha : String = data.charAt(i);
                        if('\n' == cha) {
                            writeLineBreak(null);
                        } else {
                            writeLineBreak(""+cha);
                        }
                    }
                    if(ceh != null) {
                        writeIndent();
                    }
                    start = ending;
                }
            } else if(spaces) {
                if(ceh != ' ') {
                    if(start+1 == ending && env.column > env.bestWidth) {
                        writeIndent();
                    } else {
                        data = text.substring(start,ending);
                        env.column += data.length;
                        stream.write(data);
                    }
                    start = ending;
                }
            } else {
                if(ceh == null || ' ' == ceh || '\n' == ceh || '\u0085' == ceh) {
                    data = text.substring(start,ending);
                    stream.write(data);
                    if(ceh == null) {
                        writeLineBreak(null);
                    } 
                    start = ending;
                }
            }
            if(ceh != null) {
                breaks = '\n' == ceh || '\u0085' == ceh;
                spaces = ceh == ' ';
            }
            ending++;
        }
    }

    internal function writeLiteral(text : String):void {
        var chomp:String= determineChomp(text);
        writeIndicator("|" + chomp, true, false, false);
        writeIndent();
        var breaks:Boolean= false;
        var start:int=0,ending:int=0;
        var data:String= null;
        while(ending <= text.length) {
            var ceh : String = null;
            if(ending < text.length) {
                ceh = text.charAt(ending);
            }
            if(breaks) {
                if(ceh == null || !('\n' == ceh || '\u0085' == ceh)) {
                    data = text.substring(start,ending);
                    for(var i:int=0,j:int=data.length;i<j;i++) {
                        var cha : String = data.charAt(i);
                        if('\n' == cha) {
                            writeLineBreak(null);
                        } else {
                            writeLineBreak(""+cha);
                        }
                    }
                    if(ceh != null) {
                        writeIndent();
                    }
                    start = ending;
                }
            } else {
                if(ceh == null || '\n' == ceh || '\u0085' == ceh) {
                    data = text.substring(start,ending);
                    stream.write(data);
                    if(ceh == null) {
                        writeLineBreak(null);
                    }
                    start = ending;
                }
            }
            if(ceh != null) {
                breaks = '\n' == ceh || '\u0085' == ceh;
            }
            ending++;
        }
    }

    internal function writePlain(text : String, split : Boolean):void {
        if(text == null || "" == text) {
            return;
        }
        var data : String = null;
        if(!env.whitespace) {
            data = " ";
            env.column += data.length;
            stream.write(data);
        }
        env.whitespace = false;
        env.indentation = false;
        var spaces:Boolean=false, breaks : Boolean = false;
        var start:int=0,ending : int=0;
        while(ending <= text.length) {
            var ceh : String = null;
            if(ending < text.length) {
                ceh = text.charAt(ending);
            }
            if(spaces) {
                if(ceh != ' ') {
                    if(start+1 == ending && env.column > env.bestWidth && split) {
                        writeIndent();
                        env.whitespace = false;
                        env.indentation = false;
                    } else {
                        data = text.substring(start,ending);
                        env.column += data.length;
                       stream.write(data);
                    }
                    start = ending;
                }
            } else if(breaks) {
                if(ceh != '\n' && ceh != '\u0085') {
                    if(text.charAt(start) == '\n') {
                        writeLineBreak(null);
                    }
                    data = text.substring(start,ending);
                    for(var i:int=0,j:int=data.length;i<j;i++) {
                        var cha : String = data.charAt(i);
                        if('\n' == cha) {
                            writeLineBreak(null);
                        } else {
                            writeLineBreak(""+cha);
                        }
                    }
                    writeIndent();
                    env.whitespace = false;
                    env.indentation = false;
                    start = ending;
                }
            } else {
                if(ceh == null || ' ' == String(ceh) || '\n' == String(ceh) || '\u0085' == String(ceh)) {
                    data = text.substring(start,ending);
                    env.column += data.length;
                    stream.write(data);
                    start = ending;
                }
            }
            if(ceh != null) {
                spaces = String(ceh) == ' ';
                breaks = String(ceh) == '\n' || String(ceh) == '\u0085';
            }
            ending++;
        }
    }

    internal function writeLineBreak(data:String):void {
        var xdata:String= data;
        if(xdata == null) {
            xdata = env.bestLineBreak;
        }
        env.whitespace = true;
        env.indentation = true;
        env.line++;
        env.column = 0;
        stream.write(xdata);
    }

    internal function flushStream() : void {
        stream.flush();
    }

    internal function prepareVersion(version : Array) : String {
        if(version[0] != 1) {
            throw new EmitterException("unsupported YAML version: " + version[0] + "." + version[1]);
        }
        return ""+version[0] + "." + version[1];
    }
    
    private static var HANDLE_FORMAT : RegExp = new RegExp("^![-\\w]*!$");
    
    internal static function prepareTagHandle(handle : String):String{
        if(handle == null || "" == handle) {
            throw new EmitterException("tag handle must not be empty");
        } else if(handle.charAt(0) != '!' || handle.charAt(handle.length-1) != '!') {
            throw new EmitterException("tag handle must start and end with '!': " + handle);
        } else if(!"!" == handle && !HANDLE_FORMAT.exec(handle)) {
            throw new EmitterException("invalid syntax for tag handle: " + handle);
        }
        return handle;
    }

    internal static function prepareTagPrefix(prefix : String) : String {
        if(prefix == null || "" == prefix) {
            throw new EmitterException("tag prefix must not be empty");
        }
        var chunks : String = new String();
        var start:int=0,ending:int=0;
        if(prefix.charAt(0) == '!') {
            ending = 1;
        }
        while(ending < prefix.length) {
            ending++;
        }
        if(start < ending) {
            chunks += prefix.substring(start,ending);
        }
        return chunks;
    }

    private static var ANCHOR_FORMAT : RegExp = new RegExp("^[-\\w]*$");
    internal static function prepareAnchor(anchor : String) : String {
        if(anchor == null || "" == anchor) {
            throw new EmitterException("anchor must not be empty");
        }
        if(!ANCHOR_FORMAT.exec(anchor)) {
            throw new EmitterException("invalid syntax for anchor: " + anchor);
        }
        return anchor;
    }

    internal function prepareTag(tag : String) : String {
        if(tag == null || "" == tag) {
            throw new EmitterException("tag must not be empty");
        }
        if(tag == "!") {
            return tag;
        }
        var handle : String = null;
        var suffix : String = tag;
        for(var iter : Iterator = env.tagPrefixes.keySet().iterator();iter.hasNext();) {
            var prefix : String = iter.next() as String;
            if(new RegExp("^" + prefix + ".+$").exec(tag) && (prefix == "!" || prefix.length < tag.length)) {
                handle = env.tagPrefixes.get(prefix) as String;
                suffix = tag.substring(prefix.length);
            }
        }
        var chunks : String = new String();
        var start:int=0,ending:int=0;
        while(ending < suffix.length) {
            ending++;
        }
        if(start < ending) {
            chunks += suffix.substring(start,ending);
        }
        var suffixText : String = chunks;
        if(handle != null) {
            return handle + suffixText;
        } else {
            return "!<" + suffixText + ">";
        }
    }

    private static var DOC_INDIC : RegExp = new RegExp("^(---|\\.\\.\\.)");
    private static var NULL_BL_T_LINEBR : String = "\x00 \t\r\n\u0085";
    private static var SPECIAL_INDIC : String = "#,[]{}#&*!|>'\"%@`";
    private static var FLOW_INDIC : String = ",?[]{}";
    internal static function analyzeScalar(scalar : String) : ScalarAnalysis {
        if(scalar == null || "" == scalar) {
            return new ScalarAnalysis(scalar,true,false,false,true,true,true,false,false);
        }
		var blockIndicators:Boolean= false;
        var flowIndicators:Boolean= false;
        var lineBreaks:Boolean= false;
        var specialCharacters:Boolean= false;

        // Whitespaces.
        var inlineSpaces: Boolean = false;          // non-space space+ non-space
        var inlineBreaks: Boolean = false;          // non-space break+ non-space
        var leadingSpaces: Boolean = false;         // ^ space+ (non-space | $)
        var leadingBreaks: Boolean = false;         // ^ break+ (non-space | $)
        var trailingSpaces: Boolean = false;        // (^ | non-space) space+ $
        var trailingBreaks: Boolean = false;        // (^ | non-space) break+ $
        var inlineBreaksSpaces: Boolean = false;   // non-space break+ space+ non-space
        var mixedBreaksSpaces: Boolean = false;    // anything else
        
        if(DOC_INDIC.exec(scalar)) {
            blockIndicators = true;
            flowIndicators = true;
        }

		var preceededBySpace:Boolean= true;
        var followedBySpace:Boolean= scalar.length == 1|| NULL_BL_T_LINEBR.indexOf(scalar.charAt(1)) != -1;

        var spaces:Boolean= false;
        var breaks:Boolean= false;
        var mixed:Boolean= false;
        var leading:Boolean= false;
        
        var index:int= 0;

        while(index < scalar.length) {
            var ceh : String = scalar.charAt(index);
            if(index == 0) {
                if(SPECIAL_INDIC.indexOf(ceh) != -1) {
                    flowIndicators = true;
                    blockIndicators = true;
                }
                if(ceh == '?' || ceh == ':') {
                    flowIndicators = true;
                    if(followedBySpace) {
                        blockIndicators = true;
                    }
                }
                if(ceh == '-' && followedBySpace) {
                    flowIndicators = true;
                    blockIndicators = true;
                }
            } else {
                if(FLOW_INDIC.indexOf(ceh) != -1) {
                    flowIndicators = true;
                }
                if(ceh == ':') {
                    flowIndicators = true;
                    if(followedBySpace) {
                        blockIndicators = true;
                    }
                }
                if(ceh == '#' && preceededBySpace) {
                    flowIndicators = true;
                    blockIndicators = true;
                }
            }
            if(ceh == '\n' || '\u0085' == ceh) {
                lineBreaks = true;
            }
            if(!(ceh == '\n' || ('\u0020' <= ceh && ceh <= '\u007E'))) {
                specialCharacters = true;

            }
            if(' ' == ceh || '\n' == ceh || '\u0085' == ceh) {
                if(spaces && breaks) {
                    if(ceh != ' ') {
                        mixed = true;
                    }
                } else if(spaces) {
                    if(ceh != ' ') {
                        breaks = true;
                        mixed = true;
                    }
                } else if(breaks) {
                    if(ceh == ' ') {
                        spaces = true;
                    }
                } else {
                    leading = (index == 0);
                    if(ceh == ' ') {
                        spaces = true;
                    } else {
                        breaks = true;
                    }
                }
            } else if(spaces || breaks) {
                if(leading) {
                    if(spaces && breaks) {
                        mixedBreaksSpaces = true;
                    } else if(spaces) {
                        leadingSpaces = true;
                    } else if(breaks) {
                        leadingBreaks = true;
                    }
                } else {
                    if(mixed) {
                        mixedBreaksSpaces = true;
                    } else if(spaces && breaks) {
                        inlineBreaksSpaces = true;
                    } else if(spaces) {
                        inlineSpaces = true;
                    } else if(breaks) {
                        inlineBreaks = true;
                    }
                }
                spaces = breaks = mixed = leading = false;
            }

            if((spaces || breaks) && (index == scalar.length-1)) {
                if(spaces && breaks) {
                    mixedBreaksSpaces = true;
                } else if(spaces) {
                    trailingSpaces = true;
                    if(leading) {
                        leadingSpaces = true;
                    }
                } else if(breaks) {
                    trailingBreaks = true;
                    if(leading) {
                        leadingBreaks = true;
                    }
                }
                spaces = breaks = mixed = leading = false;
            }
            index++;
            preceededBySpace = NULL_BL_T_LINEBR.indexOf(ceh) != -1;
            followedBySpace = index+1 >= scalar.length || NULL_BL_T_LINEBR.indexOf(scalar.charAt(index+1)) != -1;
        }
		var allowFlowPlain:Boolean= true;
        var allowBlockPlain:Boolean= true;
        var allowSingleQuoted:Boolean= true;
        var allowDoubleQuoted:Boolean= true;
        var allowBlock:Boolean= true;
        
        if(leadingSpaces || leadingBreaks || trailingSpaces) {
            allowFlowPlain = allowBlockPlain = allowBlock = false;
        }

        if(trailingBreaks) {
            allowFlowPlain = allowBlockPlain = false;
        }

        if(inlineBreaksSpaces) {
            allowFlowPlain = allowBlockPlain = allowSingleQuoted = false;
        }

        if(mixedBreaksSpaces || specialCharacters) {
            allowFlowPlain = allowBlockPlain = allowSingleQuoted = allowBlock = false;
        }

        if(inlineBreaks) {
            allowFlowPlain = allowBlockPlain = allowSingleQuoted = false;
        }
        
        if(trailingBreaks) {
            allowSingleQuoted = false;
        }

        if(lineBreaks) {
            allowFlowPlain = allowBlockPlain = false;
        }

        if(flowIndicators) {
            allowFlowPlain = false;
        }
        
        if(blockIndicators) {
            allowBlockPlain = false;
        }

        return new ScalarAnalysis(scalar,false,lineBreaks,allowFlowPlain,allowBlockPlain,allowSingleQuoted,allowDoubleQuoted,allowBlock, specialCharacters);
    }

    internal static function determineChomp(text : String) : String {
        var ceh : String = ' ';
        var ceh2 : String =  ' ';
        
        if(text.length > 0) {
            ceh = text.charAt(text.length-1);
            if(text.length > 1) {
                ceh2 = text.charAt(text.length-2);
            }
        }
                
        return (ceh == '\n' || ceh == '\u0085') ? ((ceh2 == '\n' || ceh2 == '\u0085') ? "+" : "") : "-";
    }

}
}
   
 