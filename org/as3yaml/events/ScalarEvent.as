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
package org.as3yaml.events {
	import flash.utils.getQualifiedClassName;
	

public class ScalarEvent extends NodeEvent {
    private var tag : String;
    private var style : String;
    private var value : String;
    private var implicit : Array;

    public function ScalarEvent(anchor : String, tag : String, implicit : Array, value : String, style : String) {
        super(anchor);
        this.tag = tag;
        this.implicit = implicit;
        this.value = value;
        this.style = style;
    }

    public function getTag() : String {
        return this.tag;
    }

    public function getStyle() : String {
        return this.style;
    }

    public function getValue() : String {
        return this.value;
    }

    public function getImplicit() : Array {
        return this.implicit;
    }

    override public function toString() : String {
        return "#<" + getQualifiedClassName(this) + " value=\"" + value + "\">";
    }
}// ScalarEvent

}
