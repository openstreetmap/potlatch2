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

public class DefaultYAMLConfig implements YAMLConfig {
    private var _indent:int= 2;
    private var _useHeader:Boolean= false;
    private var _useVersion:Boolean= false;
    private var _version:String= "1.1";
    private var _expStart:Boolean= true;
    private var _expEnd:Boolean= false;
    private var _format:String= "id{0}";
    private var _expTypes:Boolean= false;
    private var _canonical:Boolean= false;
    private var _bestWidth:int= 80;
    private var _useBlock:Boolean= false;
    private var _useFlow:Boolean= false;
    private var _usePlain:Boolean= false;
    private var _useSingle:Boolean= false;
    private var _useDouble:Boolean= false;
    private var _processorFunction: Function = null;
    
    public function indent(indent:int):YAMLConfig{ _indent = indent; return this; }
    public function getIndent():int{ return _indent; }
    public function useHeader(useHead:Boolean):YAMLConfig{ _useHeader = useHead; return this; }
    public function getUseHeader():Boolean{ return _useHeader; }
    public function useVersion(useVersion:Boolean):YAMLConfig{ _useVersion = useVersion; return this; }
    public function getUseVersion():Boolean{ return _useVersion; }
    public function version(version:String):YAMLConfig{ _version = version; return this; }
    public function getVersion():String{ return _version; }
    public function explicitStart(expStart:Boolean):YAMLConfig{ _expStart = expStart; return this; }
    public function explicitEnd(expEnd:Boolean):YAMLConfig{ _expEnd = expEnd; return this; }
    public function getExplicitEnd() : Boolean { return _expEnd };
    public function getExplicitStart() : Boolean { return _expStart };
    public function anchorFormat(format:String):YAMLConfig{ _format = format; return this; }
    public function getAnchorFormat():String{return _format; }
    public function explicitTypes(expTypes:Boolean = false):YAMLConfig{ _expTypes = expTypes; return this; }
    public function getExplicitTypes():Boolean{ return _expTypes; }

    public function canonical(canonical:Boolean):YAMLConfig{ _canonical = canonical; return this; }
    public function getCanonical():Boolean{ return _canonical; }

    public function bestWidth(bestWidth:int):YAMLConfig{ _bestWidth = bestWidth; return this; }
    public function getBestWidth():int{ return _bestWidth; }

    public function useBlock(useBlock:Boolean):YAMLConfig{ _useBlock = useBlock; return this; }

    public function useFlow(useFlow:Boolean):YAMLConfig{ _useFlow = useFlow; return this; }

    public function usePlain(usePlain:Boolean):YAMLConfig{ _usePlain = usePlain; return this; }

    public function useSingle(useSingle:Boolean):YAMLConfig{ _useSingle = useSingle; return this; }

    public function useDouble(useDouble:Boolean):YAMLConfig{ _useDouble = useDouble; return this; }

    public function getUseSingle():Boolean{ return _useSingle; }

    public function getUseDouble():Boolean{ return _useDouble; }
    
}
}
