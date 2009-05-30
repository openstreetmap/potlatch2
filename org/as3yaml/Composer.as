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

import org.as3yaml.events.*;
import org.as3yaml.nodes.*;

public class Composer {
    private var parser : Parser;
    private var resolver : Resolver;
    private var anchors : Dictionary;

    public function Composer(parser : Parser, resolver : Resolver) : void {
        this.parser = parser;
        this.resolver = resolver;
        this.anchors = new Dictionary();
    }

    public function checkNode() : Boolean {
        return !(parser.peekEvent() is StreamEndEvent);
    }
    
    public function getNode() : Node {
        return checkNode() ? composeDocument() : Node(null);
    }

    public function eachNode(composer : Composer) : NodeIterator {
        return new NodeIterator(composer);
    }

    public function iterator() : NodeIterator {
        return eachNode(this);
    }

    public function composeDocument() : Node {
        if(parser.peekEvent() is StreamStartEvent) {
            //Drop STREAM-START event
            parser.getEvent();
        }
        //Drop DOCUMENT-START event
        parser.getEvent();
        var node : Node = composeNode(null,null);
        //Drop DOCUMENT-END event
        parser.getEvent();
        this.anchors = new Dictionary();
        return node;
    }

    private static var FALS : Array = [false];
    private static var TRU : Array = [true];

    public function composeNode(parent : Node, index : Object) : Node {
		var event : Event = parser.peekEvent();
		var anchor : String;
        if(event is AliasEvent) {
            var eve : AliasEvent = parser.getEvent() as AliasEvent;
            anchor = eve.getAnchor();
            if(!anchors[anchor]) {
                
                throw new ComposerException(null,"found undefined alias " + anchor,null);
            }
            return anchors[anchor] as Node;
        }
        anchor = null;
        if(event is NodeEvent) {
            anchor = NodeEvent(event).getAnchor();
        }
        if(null != anchor) {
            if(anchors[anchor]) {
                throw new ComposerException("found duplicate anchor "+anchor+"; first occurence",null,null);
            }
        }
        resolver.descendResolver(parent,index);
        var node : Node = null;
		var tag : String;
        if(event is ScalarEvent) {
            var ev : ScalarEvent = parser.getEvent() as ScalarEvent;
            tag = ev.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(ScalarNode,ev.getValue(),ev.getImplicit());
            }
            node = new ScalarNode(tag,ev.getValue(),ev.getStyle());
            if(null != anchor) {
                anchors[anchor] = node;
            }
        } else if(event is SequenceStartEvent) {
            var start : SequenceStartEvent = parser.getEvent() as SequenceStartEvent;
            tag = start.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(SequenceNode,null,start.getImplicit()  ? TRU : FALS);
            }
            node = new SequenceNode(tag,[],start.getFlowStyle());
            if(null != anchor) {
                anchors[anchor] = node;
            }
            var ix : int = 0;
            var nodeVal: Array = node.getValue() as Array;
            while(!(parser.peekEvent() is SequenceEndEvent)) {
                nodeVal.push(composeNode(node, ix++));
            }
            parser.getEvent();
        } else if(event is MappingStartEvent) {
            var st : MappingStartEvent = parser.getEvent() as MappingStartEvent;
            tag = st.getTag();
            if(tag == null || tag == ("!")) {
                tag = resolver.resolve(MappingNode,null, st.getImplicit() ? TRU : FALS);
            }
            node = new MappingNode(tag, new Dictionary(), st.getFlowStyle());
            if(null != anchor) {
                anchors[anchor] = node;
            }
            var mapNodeVal: Dictionary = node.getValue() as Dictionary;
            while(!(parser.peekEvent() is MappingEndEvent)) {
                var key : Event = parser.peekEvent();
                var itemKey : Node = composeNode(node,null);
                if(mapNodeVal[itemKey]) {
                    composeNode(node,itemKey);
                } else {
                    mapNodeVal[itemKey] = composeNode(node,itemKey);
                }
            }
            parser.getEvent();
        }
        resolver.ascendResolver();
        return node;
    }
    
}
}

import org.as3yaml.Composer;
import org.as3yaml.nodes.Node;
	

internal class NodeIterator {
	private var composer : Composer;
	public function NodeIterator(composer : Composer) : void { this.composer = composer; }
    public function hasNext() : Boolean {return composer.checkNode();}
    public function next() :  Node{return composer.getNode();}
    public function remove() : void {}
}
