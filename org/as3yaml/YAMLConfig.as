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


public interface YAMLConfig {
    function useSingle(useSingle:Boolean):YAMLConfig;
    function useDouble(useDouble:Boolean):YAMLConfig;
    function getUseSingle():Boolean;
    function getUseDouble():Boolean;
	function version(version:String):YAMLConfig;
    function explicitStart(expStart:Boolean):YAMLConfig;
    function explicitEnd(expEnd:Boolean):YAMLConfig;
    function anchorFormat(format:String):YAMLConfig;
    function getAnchorFormat():String;
    function getExplicitStart() : Boolean;
	function useVersion(useVersion:Boolean):YAMLConfig;
	function indent(indent:int):YAMLConfig;
    function getExplicitEnd() : Boolean;
    function getUseVersion() : Boolean;
    function getVersion() : String;
    function getUseHeader():Boolean
    function explicitTypes(expTypes:Boolean = false):YAMLConfig;
    function getExplicitTypes():Boolean;
    function canonical(canonical:Boolean):YAMLConfig;
    function getCanonical():Boolean;
    function bestWidth(bestWidth:int):YAMLConfig;
    function getBestWidth():int;
    function useBlock(useBlock:Boolean):YAMLConfig;
    function useFlow(useFlow:Boolean):YAMLConfig;
    function usePlain(usePlain:Boolean):YAMLConfig;
    function useHeader(useHeader:Boolean):YAMLConfig;	
	function getIndent():int
 
   


}

}
