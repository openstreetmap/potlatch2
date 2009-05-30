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

package org.as3yaml.nodes {
	import flash.utils.getQualifiedClassName;
	

public class Node {
    private var tag:String;
    private var value:Object;
    private var hash:int= -1;

  public function Node(tag:String, value:Object) {
        this.tag = tag;
        this.value = value;
    }

    public function getTag():String{
        return this.tag;
    }

    public function getValue():Object{
        return this.value;
    }

/*    public function hashCode():int{
        if(hash == -1) {
            hash = 3;
            hash += (null == tag) ? 0: 3*tag.hashCode();
            hash += (null == value) ? 0: 3*value.hashCode();
        }
        return hash;
    }
*/
    public function equals(oth:Object):Boolean{
        if(oth is Node) {
            var nod:Node= Node(oth);
            return ((this.tag != null) ? this.tag == (nod.tag) : nod.tag == null) && 
                ((this.value != null) ? this.value == (nod.value) : nod.value == null);
        }
        return false;
    }

    public function toString():String{
        return "#<" + getQualifiedClassName(this) + " (tag=" + getTag() + ", value=" + getValue()+")>";
    }
}
}
