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

package org.as3yaml
{
   internal class ScalarAnalysis {
        public var scalar : String;
        public var empty : Boolean;
        public var multiline : Boolean;
        public var allowFlowPlain : Boolean;
        public var allowBlockPlain : Boolean;
        public var allowSingleQuoted : Boolean;
        public var allowDoubleQuoted : Boolean;
        public var allowBlock : Boolean;
        public var specialCharacters : Boolean;
        public function ScalarAnalysis(scalar : String, empty : Boolean, multiline : Boolean, allowFlowPlain : Boolean, allowBlockPlain : Boolean, allowSingleQuoted : Boolean, allowDoubleQuoted : Boolean, allowBlock : Boolean, specialCharacters : Boolean) {
            this.scalar = scalar;
            this.empty = empty;
            this.multiline = multiline;
            this.allowFlowPlain = allowFlowPlain;
            this.allowBlockPlain = allowBlockPlain;
            this.allowSingleQuoted = allowSingleQuoted;
            this.allowDoubleQuoted = allowDoubleQuoted;
            this.allowBlock = allowBlock;
            this.specialCharacters = specialCharacters;
        }
    }

}