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
	import flash.utils.Dictionary;
	
	import mx.utils.StringUtil;
	
	import org.as3yaml.events.*;
	import org.as3yaml.nodes.*;
	import org.idmedia.as3commons.util.*;
	

public class Serializer {
    private var emitter : Emitter;
    private var resolver : Resolver;
    private var options : YAMLConfig;
    private var useExplicitStart : Boolean;
    private var useExplicitEnd : Boolean;
    private var useVersion : Array;
    private var useTags : Boolean;
    private var anchorTemplate : String;
    private var serializedNodes : Set;
    private var anchors : Map;
    private var lastAnchorId : int;
    private var closed : Boolean;
    private var opened : Boolean;

    public function Serializer(emitter : Emitter, resolver : Resolver, opts : YAMLConfig) {
        this.emitter = emitter;
        this.resolver = resolver;
        this.options = opts;
        this.useExplicitStart = opts.getExplicitStart();
        this.useExplicitEnd = opts.getExplicitEnd();
        var version : Array = new Array();
        if(opts.getUseVersion()) {
            var v1 : String = opts.getVersion();
            var index : int = v1.indexOf('.');
            version[0] = int(v1.substring(0,index));
            version[1] = int(v1.substring(index+1));
        } else {
            version = null;
        }
        this.useVersion = version;
        this.useTags = opts.getUseHeader();
        this.anchorTemplate = opts.getAnchorFormat() == null ? "id{0}" : opts.getAnchorFormat();
        this.serializedNodes = new HashSet();
        this.anchors = new HashMap();
        this.lastAnchorId = 0;
        this.closed = false;
        this.opened = false;
    }

    public function open() : void {
        if(!closed && !opened) {
            this.emitter.emit(new StreamStartEvent());
            this.opened = true;
        } else if(closed) {
            throw new SerializerException("serializer is closed");
        } else {
            throw new SerializerException("serializer is already opened");
        }
    }

    public function close() : void  {
        if(!opened) {
            throw new SerializerException("serializer is not opened");
        } else if(!closed) {
            this.emitter.emit(new StreamEndEvent());
            this.closed = true;
            this.opened = false;
        }
    }

    public function serialize(node : Node) : void  {
        if(!this.closed && !this.opened) {
            throw new SerializerException("serializer is not opened");
        } else if(this.closed) {
            throw new SerializerException("serializer is closed");
        }
        this.emitter.emit(new DocumentStartEvent(this.useExplicitStart,this.useVersion,null));
        anchorNode(node);
        serializeNode(node,null,null);
        this.emitter.emit(new DocumentEndEvent(this.useExplicitEnd));
        this.serializedNodes = new HashSet();
        this.anchors = new HashMap();
        this.lastAnchorId = 0;
    }

    private function anchorNode(node : Node) : void {
        if(this.anchors.containsKey(node)) {
            var anchor : String = this.anchors.get(node) as String;
            if(null == anchor) {
                anchor = generateAnchor(node);
                this.anchors.put(node,anchor);
            }
        } else {
            this.anchors.put(node,null);
            if(node is SequenceNode) {
            	var seqNodeVal: Array =  node.getValue() as Array;
                for each (var item: Node in seqNodeVal) {
                    anchorNode(item);
                }
            } else if(node is MappingNode) {
                var value : Map = MappingNode(node).getValue() as Map;
                for(var iter : Iterator = value.keySet().iterator();iter.hasNext();) {
                    var key : Node = iter.next() as Node;
                    anchorNode(key);
                    anchorNode(value.get(key));
                }
            }
        }
    }

    private function generateAnchor(node : Node) : String {
        this.lastAnchorId++;
        return StringUtil.substitute(this.anchorTemplate, [new int(this.lastAnchorId)]);
    }

    private function serializeNode(node : Node, parent : Node, index : Object) : void  {
        var tAlias : String = this.anchors.get(node) as String;
        if(this.serializedNodes.contains(node)) {
            this.emitter.emit(new AliasEvent(tAlias));
        } else {
            this.serializedNodes.add(node);
            this.resolver.descendResolver(parent,index);
            if(node is ScalarNode) {
                var detectedTag : String = this.resolver.resolve(ScalarNode,String(node.getValue()),[true,false]);
                var defaultTag : String = this.resolver.resolve(ScalarNode,String(node.getValue()),[false,true]);
                var implicit : Array = [false,false];
                if(!options.getExplicitTypes()) {
                    implicit[0] = node.getTag() == detectedTag;
                    implicit[1] = node.getTag() == defaultTag;
                }
                this.emitter.emit(new ScalarEvent(tAlias,node.getTag(),implicit,String(node.getValue()), ScalarNode(node).getStyle()));
            } else if(node is SequenceNode) {
                var imp : Boolean = !options.getExplicitTypes() && (node.getTag() == (this.resolver.resolve(SequenceNode,null,[true,true])));
                this.emitter.emit(new SequenceStartEvent(tAlias,node.getTag(),imp,CollectionNode(node).getFlowStyle()));
                var ix : int = 0;
            	var seqNodeVal: Array =  node.getValue() as Array;
                for each (var item: Node in seqNodeVal) {
                    serializeNode(item,node, ix++);
                }                
                this.emitter.emit(new SequenceEndEvent());
            } else if(node is MappingNode) {
                var impl : Boolean = !options.getExplicitTypes() && (node.getTag() == (this.resolver.resolve(MappingNode,null,[true,true])));
                this.emitter.emit(new MappingStartEvent(tAlias,node.getTag(),impl,CollectionNode(node).getFlowStyle()));
                var value : Map = node.getValue() as Map;
                for(var iter : Iterator = value.keySet().iterator();iter.hasNext();) {
                    var key : Node = iter.next() as Node;
                    serializeNode(key,node,null);
                    serializeNode(value.get(key),node,key);
                }
                this.emitter.emit(new MappingEndEvent());
            }
        }
    }
}
}