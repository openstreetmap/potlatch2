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
	import org.as3yaml.tokens.*;
	import org.as3yaml.util.StringUtils;
	import org.idmedia.as3commons.util.Iterator;
	import org.rxr.actionscript.io.StringReader;

	


public class Scanner {
    private const LINEBR : String = "\n\u0085\u2028\u2029";
    private const NULL_BL_LINEBR : String = "\x00 \r\n\u0085";
    private const NULL_BL_T_LINEBR : String = "\x00 \t\r\n\u0085";
    private const NULL_OR_OTHER : String = NULL_BL_T_LINEBR;
    private const NULL_OR_LINEBR : String = "\x00\r\n\u0085";
    private const FULL_LINEBR : String = "\r\n\u0085";
    private const BLANK_OR_LINEBR : String = " \r\n\u0085";
    private const S4 : String = "\0 \t\r\n\u0028[]{}";    
    private const ALPHA : String = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-_";
    private const STRANGE_CHAR : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789][-';/?:@&=+$,.!~*()%";
    private const RN : String = "\r\n";
    private const BLANK_T : String = " \t";
    private const SPACES_AND_STUFF : String = "'\"\\\x00 \t\r\n\u0085";
    private const DOUBLE_ESC : String = "\"\\";
    private const NON_ALPHA_OR_NUM : String = "\x00 \t\r\n\u0085?:,]}%@`";
    private const NON_PRINTABLE : RegExp = new RegExp("[^\x09\x0A\x0D\x20-\x7E\x85\xA0-\uD7FF\uE000-\uFFFD]");
    private const NOT_HEXA : RegExp = new RegExp("[^0-9A-Fa-f]");
    private const NON_ALPHA : RegExp = new RegExp("[^-0-9A-Za-z_]");
    private const R_FLOWZERO : RegExp = new RegExp(/[\x00 \t\r\n\u0085]|(:[\x00 \t\r\n\u0028])/);
    private const R_FLOWNONZERO : RegExp = new RegExp(/[\x00 \t\r\n\u0085\\\[\\\]{},:?]/);
    private const LINE_BR_REG : RegExp = new RegExp("[\n\u0085]|(?:\r[^\n])");
    private const END_OR_START : RegExp = new RegExp("^(---|\\.\\.\\.)[\0 \t\r\n\u0085]$");
    private const ENDING : RegExp = new RegExp("^---[\0 \t\r\n\u0085]$");
    private const START : RegExp = new RegExp("^\\.\\.\\.[\x00 \t\r\n\u0085]$");
    private const BEG : RegExp = new RegExp(/^([^\x00 \t\r\n\u0085\\\-?:,\\[\\\]{}#&*!|>'\"%@]|([\\\-?:][^\x00 \t\r\n\u0085]))/);

    private var ESCAPE_REPLACEMENTS : Object = new Object();
    private var ESCAPE_CODES : Object = new Object();

	private function initEscapes(): void { 
        ESCAPE_REPLACEMENTS['0'] = "\x00";
        ESCAPE_REPLACEMENTS['a'] = "\u0007";
        ESCAPE_REPLACEMENTS['b'] = "\u0008";
        ESCAPE_REPLACEMENTS['t'] = "\u0009";
        ESCAPE_REPLACEMENTS['\t'] = "\u0009";
        ESCAPE_REPLACEMENTS['n'] = "\n";
        ESCAPE_REPLACEMENTS['v'] = "\u000B";
        ESCAPE_REPLACEMENTS['f'] = "\u000C";
        ESCAPE_REPLACEMENTS['r'] = "\r";
        ESCAPE_REPLACEMENTS['e'] = "\u001B";
        ESCAPE_REPLACEMENTS[' '] = "\u0020";
        ESCAPE_REPLACEMENTS['"'] = "\"";
        ESCAPE_REPLACEMENTS['\\'] = "\\";
        ESCAPE_REPLACEMENTS['N'] = "\u0085";
        ESCAPE_REPLACEMENTS['_'] = "\u00A0";
        ESCAPE_REPLACEMENTS['L'] = "\u2028";
        ESCAPE_REPLACEMENTS['P'] = "\u2029";

        ESCAPE_CODES['x'] = 2;
        ESCAPE_CODES['u'] = 4;
        ESCAPE_CODES['U'] = 8;
    }

    private var done : Boolean = false;
    private var flowLevel : int = 0;
    private var tokensTaken : int = 0;
    private var indent : int = -1;
    private var allowSimpleKey : Boolean = true;
    private var eof : Boolean = true;
    private var column : int = 0;
    private var buffer : StringReader;
    private var tokens : Array;
    private var indents : Array;
    private var possibleSimpleKeys : Object;

    private var docStart : Boolean = false;

    public function Scanner(stream : String) {
    	initEscapes();
        this.buffer = new StringReader(stream);
        this.tokens = new Array();
        this.indents = new Array();
        this.possibleSimpleKeys = new Object();
        checkPrintable(stream);
        buffer.writeChar('\x00');
        fetchStreamStart();
    }

    public function checkToken(choices : Array) : Boolean {
//        while(needMoreTokens()) {
//            fetchMoreTokens();
//        }
        if(this.tokens.length > 0) {
            if(choices.length == 0) {
                return true;
            }
           var first : Class = this.tokens.get(0) as Class;
           var len: int = choices.length;
            for (var i : int = 0; i < len; i++) {
                if(choices[i] is first) {
                    return true;
                }
            }
        }
        return false;
    }

    public function peekToken() : Token {
        while(needMoreTokens()) {
            fetchMoreTokens();
        }
        return Token(this.tokens.length == 0 ? null : this.tokens[0]);
    }

    public function getToken() : Token {

        if(this.tokens.length > 0) {
            this.tokensTaken++;
            return this.tokens.shift() as Token;
            
        }
        return null;
    }

    public function eachToken(scanner : Scanner) : Iterator  {
        return new TokenIterator(scanner);
    }

    public function iterator(scanner : Scanner) : Iterator{
        return eachToken(scanner);
    }

    private function peek(offset : int = 0) : String {
        return buffer.peek(offset);
    }

    private function prefix(length : int, offset: int = 0) : String {
        if(length > buffer.charsAvailable) {
            return buffer.peekRemaining()
        } else {
            return buffer.peekFor(length, offset);
        }
    }

    private function prefixForward(length : int) : String {
        var buff : String = null;
        if(length > buffer.charsAvailable) {
            buff = buffer.readRemaining()();
        } else {
            buff = buffer.readFor(length);
        }
        var ch : String;
        var j:int = buff.length;
        for(var i:int=0; i<j; i++) {
            ch = buff.charAt(i);
            if(LINEBR.indexOf(ch) != -1 || (ch == '\r' && buff.charAt(i+1) != '\n')) {
                this.column = 0;
            } else if(ch != '\uFEFF') {
                this.column++;
            }
        }
        return buff;
    }

    private function forward(char: String=null) : void {
        const ch1 : String =  char ? char : buffer.peek();
        buffer.forward();
        if(ch1 == '\n' || ch1 == '\u0085' || (ch1 == '\r' && buffer.peek() != '\n')) {
            this.column = 0;
        } else {
            this.column++;
        }
    }
    
    private function forwardBy(length : int) : void {
        var ch : String;
        for(var i:int=0;i<length;i++) {
            ch = buffer.read();
            if(LINEBR.indexOf(ch) != -1 || (ch == '\r' && buffer.peek() != '\n')) {
                this.possibleSimpleKeys = new Object();
                this.column = 0;
            } else if(ch != '\uFEFF') {
                this.column++;
            }
        }
    }

    private function checkPrintable(data : String) : void {
        var match : Object = NON_PRINTABLE.exec(data);
        if(match) {
            throw new YAMLException("At " + match.index + " we found: " + match + ". Special characters are not allowed");
        }
    }

    private function needMoreTokens() : Boolean {
        
        if(this.tokens.length == 0)
        	return true;
        else if(nextPossibleSimpleKey() == this.tokensTaken)
			return true;
		
		return false;
    }
	
    private function fetchMoreTokens() : Token {
        scanToNextToken();
        unwindIndent(this.column);
        var ch : String =  buffer.peek();
        var colz :Boolean = this.column == 0;
        switch(ch) {
        case ':': if(this.flowLevel != 0 || NULL_OR_OTHER.indexOf(buffer.peek(1)) != -1) { return fetchValue(); } break;	
        case '\'': return fetchSingle();
        case '"': return fetchDouble();
        case '?': if(this.flowLevel != 0 || NULL_OR_OTHER.indexOf(buffer.peek(1)) != -1) { return fetchKey(); } break;
        case '%': if(colz) {return fetchDirective(); } break;
        case '-': 
            if((colz || docStart) && (ENDING.exec(prefix(4)))) {
                return fetchDocumentStart(); 
            } else if(NULL_OR_OTHER.indexOf(buffer.peek(1)) != -1) {
                return fetchBlockEntry(); 
            }
            break;
        case '.': 
            if(colz && START.exec(prefix(4))) {
                return fetchDocumentEnd(); 
            }
            break;
        case '[': return fetchFlowSequenceStart();
        case '{': return fetchFlowMappingStart();
        case ']': return fetchFlowSequenceEnd();
        case '}': return fetchFlowMappingEnd();
        case ',': return fetchFlowEntry();
        case '*': return fetchAlias();
        case '&': return fetchAnchor();
        case '!': return fetchTag();
        case '|': if(this.flowLevel == 0) { return fetchLiteral(); } break;
        case '>': if(this.flowLevel == 0) { return fetchFolded(); } break;
        case '\x00': return fetchStreamEnd();
        }
        if(BEG.exec(prefix(2))) {
            return fetchPlain();
        }
        throw new ScannerException("while scanning for the next token","found character " + ch + "(" + (ch) + " that cannot start any token",null);
    }

    private function nextPossibleSimpleKey() : int {
        for(var keyObj : Object in this.possibleSimpleKeys) {
            var sk : SimpleKey = this.possibleSimpleKeys[keyObj] as SimpleKey;
            var tokNum : int = sk.tokenNumber;         
            if(tokNum > 0) {
                return tokNum;
            }
        }
        return -1;
    }

    private function removePossibleSimpleKey() : void {
        var key : SimpleKey = SimpleKey(this.possibleSimpleKeys[this.flowLevel]);
        if(key != null) {
        	delete this.possibleSimpleKeys[this.flowLevel];
            if(key.isRequired()) {
                throw new ScannerException("while scanning a simple key","could not find expected ':'",null);
            }
        }
    }
    
    private function savePossibleSimpleKey() : void {
        if(this.allowSimpleKey) {
        	this.removePossibleSimpleKey();
            this.possibleSimpleKeys[this.flowLevel] = new SimpleKey(this.tokensTaken+this.tokens.length,(this.flowLevel == 0) && this.indent == this.column,-1,-1,this.column);
        }
    }
    
    private function unwindIndent(col : int) : void {
        if(this.flowLevel != 0) {
            return;
        }

        while(this.indent > col) {
            this.indent = this.indents.shift();
            this.tokens.push(Tokens.BLOCK_END);
        }
    }
    
    private function addIndent(col : int) : Boolean {
        if(this.indent < col) {
            this.indents.unshift(this.indent);
            this.indent = col;
            return true;
        }
        return false;
    }

    private function fetchStreamStart() : Token {
        this.docStart = true;
        this.tokens.push(Tokens.STREAM_START);
        return Tokens.STREAM_START;
    }

    private function fetchStreamEnd() : Token {
        unwindIndent(-1);
        this.allowSimpleKey = false;
        this.possibleSimpleKeys = new Object();
        this.tokens.push(Tokens.STREAM_END);
        this.done = true;
        return Tokens.STREAM_END;
    }

    private function fetchDirective() : Token {
        unwindIndent(-1);
        this.allowSimpleKey = false;
        var tok : Token = scanDirective();
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchDocumentStart() : Token {
        this.docStart = false;
        return fetchDocumentIndicator(Tokens.DOCUMENT_START);
    }

    private function fetchDocumentEnd() : Token {
        return fetchDocumentIndicator(Tokens.DOCUMENT_END);
    }

    private function fetchDocumentIndicator(tok : Token) : Token {
        unwindIndent(-1);
        removePossibleSimpleKey();
        this.allowSimpleKey = false;
        forwardBy(3);
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchFlowSequenceStart() : Token {
        return fetchFlowCollectionStart(Tokens.FLOW_SEQUENCE_START);
    }

    private function fetchFlowMappingStart() : Token {
        return fetchFlowCollectionStart(Tokens.FLOW_MAPPING_START);
    }

    private function fetchFlowCollectionStart(tok : Token) : Token {
        savePossibleSimpleKey();
        this.flowLevel++;
        this.allowSimpleKey = true;
        forwardBy(1);
        this.tokens.push(tok);
        return tok;
    }

    private function fetchFlowSequenceEnd() : Token {
        return fetchFlowCollectionEnd(Tokens.FLOW_SEQUENCE_END);
    }
    
    private function fetchFlowMappingEnd() : Token {
        return fetchFlowCollectionEnd(Tokens.FLOW_MAPPING_END);
    }
    
    private function fetchFlowCollectionEnd(tok : Token) : Token {
        removePossibleSimpleKey();
        this.flowLevel--;
        this.allowSimpleKey = false;
        forwardBy(1);
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchFlowEntry() : Token {
        this.allowSimpleKey = true;
        removePossibleSimpleKey();
        forwardBy(1);
        this.tokens.push(Tokens.FLOW_ENTRY);
        return Tokens.FLOW_ENTRY;
    }

    private function fetchBlockEntry() : Token {

        if(this.flowLevel == 0) {
            if(!this.allowSimpleKey) {
                throw new ScannerException(null,"sequence entries are not allowed here",null);
            }
            if(addIndent(this.column)) {
                this.tokens.push(Tokens.BLOCK_SEQUENCE_START);
            }
        }
        this.allowSimpleKey = true;
        removePossibleSimpleKey();
        forward();
        this.tokens.push(Tokens.BLOCK_ENTRY);

        return Tokens.BLOCK_ENTRY;
    }        

    private function fetchKey() : Token {
        if(this.flowLevel == 0) {
            if(!this.allowSimpleKey) {
                throw new ScannerException(null,"mapping keys are not allowed here",null);
            }
            if(addIndent(this.column)) {
                this.tokens.push(Tokens.BLOCK_MAPPING_START);
            }
        }
        this.allowSimpleKey = this.flowLevel == 0;
        removePossibleSimpleKey();
        forward();
        this.tokens.push(Tokens.KEY);
        return Tokens.KEY;
    }

    private function fetchValue() : Token {
    	this.docStart = false;
        var key : SimpleKey = this.possibleSimpleKeys[this.flowLevel];
        if(null == key) {
            if(this.flowLevel == 0 && !this.allowSimpleKey) {
                throw new ScannerException(null,"mapping values are not allowed here",null);
            }
            this.allowSimpleKey = (this.flowLevel == 0);
            removePossibleSimpleKey();
        } else {
            delete this.possibleSimpleKeys[this.flowLevel];
            var sIndex: int = key.tokenNumber-this.tokensTaken;
		    var s:Array = tokens.slice(0, sIndex);
		    var e:Array = tokens.slice(sIndex);
		    tokens = s.concat(Tokens.KEY).concat(e);
            if(this.flowLevel == 0 && addIndent(key.getColumn())) {
	            var sIndex2: int = key.tokenNumber-this.tokensTaken;
			    var s2:Array = tokens.slice(0, sIndex2);
			    var e2:Array = tokens.slice(sIndex2);
			    tokens = s2.concat(Tokens.BLOCK_MAPPING_START).concat(e2);
            }
            this.allowSimpleKey = false;
        }
        forward();
        this.tokens.push(Tokens.VALUE);
        return Tokens.VALUE;
    }

    private function fetchAlias() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanAnchor(new AliasToken());
        this.tokens.push(tok);
        return tok;
    }

    private function fetchAnchor() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanAnchor(new AnchorToken());
        this.tokens.push(tok);
        return tok;
    }

    private function fetchTag() : Token {
    	this.docStart = false;
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanTag();
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchLiteral() : Token {
        return fetchBlockScalar('|');
    }
    
    private function fetchFolded() : Token {
        return fetchBlockScalar('>');
    }
    
    private function fetchBlockScalar(style : String) : Token {
        this.allowSimpleKey = true;
        this.removePossibleSimpleKey();
        var tok : Token = scanBlockScalar(style);
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchSingle() : Token {
        return fetchFlowScalar('\'');
    }
    
    private function fetchDouble() : Token {
        return fetchFlowScalar('"');
    }
    
    private function fetchFlowScalar(style : String) : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanFlowScalar(style);
        this.tokens.push(tok);
        return tok;
    }
    
    private function fetchPlain() : Token {
        savePossibleSimpleKey();
        this.allowSimpleKey = false;
        var tok : Token = scanPlain();
        this.tokens.push(tok);
        return tok;
    }
    
    private function scanToNextToken() : void {
        while(1) {
        	
			var pk : String = buffer.peek();
            while(pk == ' ') {
                forward(pk);
                pk = buffer.peek();
            }			
            if(pk == '#') {
                while(NULL_OR_LINEBR.indexOf(buffer.peek()) == -1) {
                    forward();
                }
            }
            if(scanLineBreak().length != 0 ) {
                if(this.flowLevel == 0) {
                    this.allowSimpleKey = true;
                }
            } else {
                break;
            }
        }
    }
    
    private function scanDirective() : Token {
        forward();
        var name : String = scanDirectiveName();
        var value : Array = null;
        if(name == ("YAML")) {
            value = scanYamlDirectiveValue();
        } else if(name == ("TAG")) {
            value = scanTagDirectiveValue();
        } else {
            while(NULL_OR_LINEBR.indexOf(buffer.peek()) == -1) {
                forward();
            }
        }
        scanDirectiveIgnoredLine();
        return new DirectiveToken(name,value);
    }
    
    private function scanDirectiveName() : String {
        var length : int = 0;
        var ch : String = buffer.peek(length);
        var zlen : Boolean = true;
        while(ALPHA.indexOf(ch) != -1) {
            zlen = false;
            length++;
            ch = buffer.peek(length);
        }
        if(zlen) {
            throw new ScannerException("while scanning a directive","expected alphabetic or numeric character, but found " + ch + "(" + (ch) + ")",null);
        }
        var value : String = prefixForward(length);
        //        forward(length);
        if(NULL_BL_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected alphabetic or numeric character, but found " + ch + "(" + (ch) + ")",null);
        }
        return value;
    }

    private function scanYamlDirectiveValue() : Array {
        while(buffer.peek() == ' ') {
            forward();
        }
        var major : String = scanYamlDirectiveNumber();
        if(buffer.peek() != '.') {
            throw new ScannerException("while scanning a directive","expected a digit or '.', but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        forward();
        var minor : String = scanYamlDirectiveNumber();
        if(NULL_BL_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected a digit or ' ', but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return [major,minor];
    }

    private function scanYamlDirectiveNumber() : String {
        var ch : String = buffer.peek();
        if(!StringUtils.isDigit(ch)) {
            throw new ScannerException("while scanning a directive","expected a digit, but found " + ch + "(" + (ch) + ")",null);
        }
        var length : int = 0;
        while(StringUtils.isDigit(buffer.peek(length))) {
            length++;
        }
        var value : String = prefixForward(length);
        //        forward(length);
        return value;
    }

    private function scanTagDirectiveValue() : Array  {
        while(buffer.peek() == ' ') {
            forward();
        }
        var handle : String = scanTagDirectiveHandle();
        while(buffer.peek() == ' ') {
            forward();
        }
        var prefix : String = scanTagDirectivePrefix();
        return [handle,prefix];
    }

    private function scanTagDirectiveHandle() : String {
        var value : String = scanTagHandle("directive");
        if(buffer.peek() != ' ') {
            throw new ScannerException("while scanning a directive","expected ' ', but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return value;
    }
    
    private function scanTagDirectivePrefix() : String {
        var value : String = scanTagUri("directive");
        if(NULL_BL_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a directive","expected ' ', but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return value;
    }

    private function scanDirectiveIgnoredLine() : String {
        while(buffer.peek() == ' ') {
            forward();
        }
        if(buffer.peek() == '"') {
            while(NULL_OR_LINEBR.indexOf(buffer.peek()) == -1) {
                forward();
            }
        }
        var ch : String = buffer.peek();
        if(NULL_OR_LINEBR.indexOf(ch) == -1) {
            throw new ScannerException("while scanning a directive","expected a comment or a line break, but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return scanLineBreak();
    }

    private function scanAnchor(tok : Token) : Token {
        var indicator : String = buffer.peek();
        var name : String = indicator == '*' ? "alias" : "anchor";
        forward();
        var length : int = 0;
        var chunk_size : int = 16;
        var match : Object;
        for(;;) {
            var chunk : String = prefix(chunk_size);
            if((match = NON_ALPHA.exec(chunk))) {
                break;
            }
            chunk_size+=16;
        }
        length = match.index;
        if(length == 0) {
            throw new ScannerException("while scanning an " + name,"expected alphabetic or numeric character, but found something else...",null);
        }
        var value : String = prefixForward(length);
        //        forward(length);
        if(NON_ALPHA_OR_NUM.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning an " + name,"expected alphabetic or numeric character, but found "+ buffer.peek() + "(" + (buffer.peek()) + ")",null);

        }
        tok.setValue(value);
        return tok;
    }

    private function scanTag() : Token {
        var ch : String = buffer.peek(1);
        var handle : String = null;
        var suffix : String = null;
        if(ch == '<') {
            forwardBy(2);
            suffix = scanTagUri("tag");
            if(buffer.peek() != '>') {
                throw new ScannerException("while scanning a tag","expected '>', but found "+ buffer.peek() + "(" + (buffer.peek()) + ")",null);
            }
            forward();
        } else if(NULL_BL_T_LINEBR.indexOf(ch) != -1) {
            suffix = "!";
            forward();
        } else {
            var length : int = 1;
            var useHandle : Boolean = false;
            while(NULL_BL_T_LINEBR.indexOf(ch) == -1) {
                if(ch == '!') {
                    useHandle = true;
                    break;
                }
                length++;
                ch = buffer.peek(length);
            }
            handle = "!";
            if(useHandle) {
                handle = scanTagHandle("tag");
            } else {
                handle = "!";
                forward();
            }
            suffix = scanTagUri("tag");
        }
        if(NULL_BL_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a tag","expected ' ', but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return new TagToken([handle,suffix]);
    }

    private function scanBlockScalar(style : String) : ScalarToken {
        var folded : Boolean = style == '>';
        var chunks : String = new String();
        forward();
        var chompi : Array = scanBlockScalarIndicators();
        var chomping : Boolean = Boolean(chompi[0])
        var increment : int = (int(chompi[1]));
        scanBlockScalarIgnoredLine();
        var minIndent : int = this.indent+1;
        if(minIndent < 1) {
            minIndent = 1;
        }
        var breaks : String = null;
        var maxIndent : int = 0;
        var ind : int = 0;
        if(increment == -1) {
            var brme : Array = scanBlockScalarIndentation();
            breaks = String(brme[0]);
            maxIndent = (int(brme[1]))
            if(minIndent > maxIndent) {
                ind = minIndent;
            } else {
                ind = maxIndent;
            }
        } else {
            ind = minIndent + increment - 1;
            breaks = scanBlockScalarBreaks(ind);
        }
		var pk :String = buffer.peek();
        var lineBreak : String = "";
        while(this.column == ind && pk != '\x00') {
            chunks += breaks;
            var leadingNonSpace : Boolean = BLANK_T.indexOf(pk) == -1;
            var length : int = 0;
            while(NULL_OR_LINEBR.indexOf(buffer.peek(length))==-1) {
                length++;
            }
            chunks += prefixForward(length);
            //            forward(length);
            lineBreak = scanLineBreak();
            breaks = scanBlockScalarBreaks(ind);
            pk = buffer.peek();
            if(this.column == ind && pk != '\x00') {
                if(folded && lineBreak == ("\n") && leadingNonSpace && BLANK_T.indexOf(pk) == -1) {
                    if(breaks.length == 0) {
                        chunks += " ";
                    }
                } else {
                    chunks += lineBreak;
                }
            } else {
                break;
            }
        }

        if(chomping) {
            chunks += lineBreak;
            chunks += breaks;
        }

        return new ScalarToken(chunks,false,style);
    }

    private function scanBlockScalarIndicators() : Array {
        var chomping : Boolean = false;
        var increment : int = -1;
        var ch : String = buffer.peek();
        if(ch == '-' || ch == '+') {
            chomping = ch == '+';
            forward(ch);
            ch = buffer.peek();
            if(StringUtils.isDigit(ch)) {
                increment = int(ch);
                if(increment == 0) {
                    throw new ScannerException("while scanning a block scalar","expected indentation indicator in the range 1-9, but found 0",null);
                }
                forward(ch);
            }
        } else if(StringUtils.isDigit(ch)) {
            increment = int(ch);
            if(increment == 0) {
                throw new ScannerException("while scanning a block scalar","expected indentation indicator in the range 1-9, but found 0",null);
            }
            forward();
            ch = buffer.peek();
            if(ch == '-' || ch == '+') {
                chomping = ch == '+';
                forward();
            }
        }
        if(NULL_BL_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a block scalar","expected chomping or indentation indicators, but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return [chomping, increment];
}

    private function scanBlockScalarIgnoredLine() : String {
        while(buffer.peek() == ' ') {
            forward();
        }
        if(buffer.peek() == '#') {
            while(NULL_OR_LINEBR.indexOf(buffer.peek()) == -1) {
                forward();
            }
        }
        if(NULL_OR_LINEBR.indexOf(buffer.peek()) == -1) {
            throw new ScannerException("while scanning a block scalar","expected a comment or a line break, but found " + buffer.peek() + "(" + (buffer.peek()) + ")",null);
        }
        return scanLineBreak();
    }

    private function scanBlockScalarIndentation() : Array {
        var chunks : String = new String();
        var maxIndent : int = 0;
        while(BLANK_OR_LINEBR.indexOf(buffer.peek()) != -1) {
            if(buffer.peek() != ' ') {
                chunks += scanLineBreak();
            } else {
                forward();
                if(this.column > maxIndent) {
                    maxIndent = column;
                }
            }
        }
        return [chunks, maxIndent];
    }

    private function scanBlockScalarBreaks(indent : int) : String {
        var chunks : String = new String();
        while(this.column < indent && buffer.peek() == ' ') {
            forward();
        }
        while(FULL_LINEBR.indexOf(buffer.peek()) != -1) {
            chunks += scanLineBreak();
            while(this.column < indent && buffer.peek() == ' ') {
                forward();
            }
        }
        return chunks;
    }

    private function scanFlowScalar(style : String) : Token {
        var dbl : Boolean = style == '"';
        var chunks : String = new String();
        var quote : String = buffer.peek();
        forward();
        chunks += scanFlowScalarNonSpaces(dbl);
        while(buffer.peek() != quote) {
            chunks += scanFlowScalarSpaces();
            chunks += scanFlowScalarNonSpaces(dbl);
        }
        forward();
               
        return new ScalarToken(chunks,false,style);
    }

    private function scanFlowScalarNonSpaces(dbl : Boolean) : String {
        var chunks : String = new String();
        while(1) {
            var length : int = 0;
            while(SPACES_AND_STUFF.indexOf(buffer.peek(length)) == -1) {
                length++;
            }
            if(length != 0) {
                chunks += (prefixForward(length));
                //                forward(length);
            }
            var ch : String = buffer.peek();
            if(!dbl && ch == '\'' && buffer.peek(1) == '\'') {
                chunks += ("'");
                forwardBy(2);
            } else if((dbl && ch == '\'') || (!dbl && DOUBLE_ESC.indexOf(ch) != -1)) {
                chunks += ch;
                forward();
            } else if(dbl && ch == '\\') {
                forward();
                ch = buffer.peek();
                if(ESCAPE_REPLACEMENTS[ch]) {
                    chunks += ESCAPE_REPLACEMENTS[ch];
                    forward(); 
                } else if(ESCAPE_CODES[ch]) {
                    length = (ESCAPE_CODES[ch]);
                    forward();
                    var val : String = prefix(length);
                    if(NOT_HEXA.exec(val)) {
                        throw new ScannerException("while scanning a double-quoted scalar","expected escape sequence of " + length + " hexadecimal numbers, but found something else: " + val,null);
                    }
                    var charCode : int = parseInt(val, 16);
                    var char : String = String.fromCharCode(charCode);
                    chunks += char;
                    forwardBy(length);
                } else if(FULL_LINEBR.indexOf(ch) != -1) {
                    scanLineBreak();
                    chunks += scanFlowScalarBreaks();
                } else {
                    throw new ScannerException("while scanning a double-quoted scalar","found unknown escape character " + ch + "(" + (ch) + ")",null);
                }
            } else {
                return chunks;
            }
        }
        return "";
    }

    private function scanFlowScalarSpaces() : String {
        var chunks : String = new String();
        var length : int = 1;
        while(BLANK_T.indexOf(buffer.peek(length)) != -1) {
            length++;
        }
        var whitespaces : String = prefixForward(length);
        //        forward(length);
        var ch : String = buffer.peek();
        if(ch == '\x00') {
            throw new ScannerException("while scanning a quoted scalar","found unexpected end of stream",null);
        } else if(FULL_LINEBR.indexOf(ch) != -1) {
            var lineBreak : String = scanLineBreak();
            var breaks : String = scanFlowScalarBreaks();
            if(!lineBreak == ("\n")) {
                chunks += lineBreak;
            } else if(breaks.length == 0) {
                chunks += " ";
            }
            chunks += breaks;
        } else {
            chunks += whitespaces;
        }
        return chunks;
    }

    private function scanFlowScalarBreaks() : String {
        var chunks : String = "";
        var pre : String = null;
        while(1) {
            pre = prefix(3);
            if((pre == ("---") || pre == ("...")) && NULL_BL_T_LINEBR.indexOf(buffer.peek(3)) != -1) {
                throw new ScannerException("while scanning a quoted scalar","found unexpected document separator",null);
            }
            while(BLANK_T.indexOf(buffer.peek()) != -1) {
                forward();
            }
            if(FULL_LINEBR.indexOf(buffer.peek()) != -1) {
                chunks += scanLineBreak();
            } else {
                return chunks;
            }            
        }
        return "";
    }


    private function scanPlain() : Token {
        /*
       See the specification for details.
       We add an additional restriction for the flow context:
         plain scalars in the flow context cannot contain ',', ':' and '?'.
       We also keep track of the `allow_simple_key` flag here.
       Indentation rules are loosed for the flow context.
         */
        
        
        var chunks : String = new String();
        var ind : int = this.indent+1;
        var spaces : String = "";
        var f_nzero : Boolean = true;
        var r_check : RegExp = R_FLOWNONZERO;
        if(this.flowLevel == 0) {
            f_nzero = false;
            r_check = R_FLOWZERO;
        }
        while(buffer.peek() != '#') {
        	
            var chunkSize : int = 256;
            var startAt: int = 0;
            var match: Object;
 
            while(!(match = r_check.exec(prefix(chunkSize, startAt)))) {
                startAt += chunkSize;
            }
            
            const length: int = startAt + int(match.index);
            var ch : String = buffer.peek(length);
            if(f_nzero && ch == ':' && S4.indexOf(buffer.peek(length+1)) == -1) {
                forwardBy(length);
                throw new ScannerException("while scanning a plain scalar","found unexpected ':'","Please check http://pyyaml.org/wiki/YAMLColonInFlowContext for details.");
            }
	        	
            if(length == 0) {
                break;
            }
            this.allowSimpleKey = false;
            chunks += spaces;
            chunks += prefixForward(length);

            spaces = scanPlainSpaces(ind);
            if(spaces == null || (this.flowLevel == 0 && this.column < ind)) {
                break;
            }
        }
        	       
        return new ScalarToken(chunks,true);
    }

    private function scanPlainSpaces(indent : int) : String {
        var chunks : String = new String();
        var length : int = 0;
        while(buffer.peek(length) == ' ') {
            length++;
        }
        var whitespaces : String = prefixForward(length);
        //        forward(length);
        var ch : String  = buffer.peek();
        if(FULL_LINEBR.indexOf(ch) != -1) {
            var lineBreak : String = scanLineBreak();
            this.allowSimpleKey = true;
            if(END_OR_START.exec(prefix(4))) {
                return "";
            }
            var breaks : String = new String();
            while(BLANK_OR_LINEBR.indexOf(buffer.peek()) != -1) {
                if(' ' == buffer.peek()) {
                    forward();
                } else {
                    breaks += scanLineBreak();
                    if(END_OR_START.exec(prefix(4))) {
                        return "";
                    }
                }
            }            
            if(!lineBreak == ("\n")) {
                chunks += lineBreak;
            } else if(breaks == null || breaks.toString() == ("")) {
                chunks += " ";
            }
            chunks += breaks;
        } else {
            chunks += whitespaces;
        }
        return chunks;
    }

    private function scanTagHandle(name : String) : String {
        var ch : String =  buffer.peek();
        if(ch != '!') {
            throw new ScannerException("while scanning a " + name,"expected '!', but found " + ch + "(" + (ch) + ")",null);
        }
        var length : int = 1;
        ch = buffer.peek(length);
        if(ch != ' ') {
            while(ALPHA.indexOf(ch) != -1) {
                length++;
                ch = buffer.peek(length);
            }
            if('!' != ch) {
                forwardBy(length);
                throw new ScannerException("while scanning a " + name,"expected '!', but found " + ch + "(" + (ch) + ")",null);
            }
            length++;
        }
        var value :String = prefixForward(length);

        return value;
    }

    private function scanTagUri(name : String) : String {
        var chunks : String = new String();
        var length : int = 0;
        var ch : String = buffer.peek(length);
        while(STRANGE_CHAR.indexOf(ch) != -1) {
            if('%' == ch) {
                chunks += prefixForward(length);
                length = 0;
                chunks += scanUriEscapes(name);
            } else {
                length++;
            }
            ch = buffer.peek(length);
        }
        if(length != 0) {
            chunks += (prefixForward(length));
        }

        if(chunks.length == 0) {
            throw new ScannerException("while scanning a " + name,"expected URI, but found " + ch + "(" + (ch) + ")",null);
        }
        return chunks;
    }

    private function scanUriEscapes(name : String) : String {
        var bytes : String = new String();
        while(buffer.peek() == '%') {
            forward();
            try {
                bytes += int(prefix(2)).toString(16);
            } catch(nfe : Error) {
                throw new ScannerException("while scanning a " + name,"expected URI escape sequence of 2 hexadecimal numbers, but found " + buffer.peek(1) + "(" + (buffer.peek(1)) + ") and "+ buffer.peek(2) + "(" + (buffer.peek(2)) + ")",null);
            }
            forwardBy(2);
        }
        return bytes
    }

    private function scanLineBreak() : String {
        // Transforms:
        //   '\r\n'      :   '\n'
        //   '\r'        :   '\n'
        //   '\n'        :   '\n'
        //   '\x85'      :   '\n'
        //   default     :   ''
        var val : String = buffer.peek();
        if(FULL_LINEBR.indexOf(val) != -1) {
            if(RN == (prefix(2))) {
                forwardBy(2);
            } else {
                forward(val);
            }
            return "\n";
        } else {
            return "";
        }
    }

}
}

import org.idmedia.as3commons.util.Iterator;
import org.as3yaml.Scanner;
	
internal class TokenIterator implements Iterator {
	
	private var scanner : Scanner;
	
	public function TokenIterator(scanner : Scanner) : void
	{
		this.scanner = scanner;
	}
	
    public function hasNext() : Boolean {
        return null != scanner.peekToken();
    }

    public function next() : * {
        return scanner.getToken();
    }

    public function remove() : void {
    }
}