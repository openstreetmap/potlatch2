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
	import org.idmedia.as3commons.util.ArrayList;
	import org.idmedia.as3commons.util.HashMap;
	import org.idmedia.as3commons.util.HashSet;
	import org.idmedia.as3commons.util.Iterator;
	import org.idmedia.as3commons.util.Map;
	import org.idmedia.as3commons.util.Set;
	

    public class EmitterEnvironment {
        public var states : ArrayList = new ArrayList();
        public var state : int = Emitter.STREAM_START;
        public var events : ArrayList = new ArrayList();
        public var event : Event;
        public var flowLevel : int = 0;
        public var indents : ArrayList = new ArrayList();
        public var indent : int = -1;
        public var rootContext : Boolean = false;
        public var sequenceContext : Boolean = false;
        public var mappingContext : Boolean = false;
        public var simpleKeyContext : Boolean = false;

        public var line:int= 0;
        public var column:int= 0;
        public var whitespace:Boolean= true;
        public var indentation:Boolean= true;
        
        public var canonical:Boolean= false;
        public var bestIndent:int= 2;
        public var bestWidth:int= 80;

        public var bestLinebreak:String= "\n";

        public var tagPrefixes:Map;

        public var preparedAnchor:String;
        public var preparedTag:String;
        
        public var analysis:ScalarAnalysis;
        public var style:*= 0;

        public var emitter:Emitter;

        public var bestLineBreak:String= "\n";

        public function needMoreEvents() : Boolean {
            if(events.isEmpty()) {
                return true;
            }
            event = events.get(0) as Event;
            if(event is DocumentStartEvent) {
                return needEvents(1);
            } else if(event is SequenceStartEvent) {
                return needEvents(2);
            } else if(event is MappingStartEvent) {
                return needEvents(3);
            } else {
                return false;
            }
        }

        private function needEvents(count : int) : Boolean {
            var level : int = 0;
            var iter : Iterator = events.iterator();
            iter.next();
            for(;iter.hasNext();) {
                var curr : Object = iter.next();
                if(curr is DocumentStartEvent || curr is CollectionStartEvent) {
                    level++;
                } else if(curr is DocumentEndEvent || curr is CollectionEndEvent) {
                    level--;
                } else if(curr is StreamEndEvent) {
                    level = -1;
                }
                if(level<0) {
                    return false;
                }
            }
            return events.size() < count+1;
        }

        private function increaseIndent(flow : Boolean, indentless : Boolean) : void {
            indents.addAt(0,  new int(indent));
            if(indent == -1) {
                if(flow) {
                    indent = bestIndent;
                } else {
                    indent = 0;
                }
            } else if(!indentless) {
                indent += bestIndent;
            }
        }

        public function expectStreamStart() : void {
            if(this.event is StreamStartEvent) {
                emitter.writeStreamStart();
                this.state = Emitter.FIRST_DOCUMENT_START;
            } else {
                throw new EmitterException("expected StreamStartEvent, but got " + this.event);
            }
        }
        
        public function expectNothing() : void {
            throw new EmitterException("expecting nothing, but got " + this.event);
        }

        public function expectDocumentStart(first : Boolean) : void {
            if(event is DocumentStartEvent) {
                var ev : DocumentStartEvent = DocumentStartEvent(event);
                if(first) {
                    if(null != ev.getVersion()) {
                        emitter.writeVersionDirective(emitter.prepareVersion(ev.getVersion()));
                    }

                    if((null != ev.getVersion() && ev.getVersion()[1] == 0) || emitter.getOptions().getVersion() == "1.0") {
                        tagPrefixes = new HashMap();
                        tagPrefixes.putAll(Emitter.DEFAULT_TAG_PREFIXES_1_0);
                    } else {
                        tagPrefixes = new HashMap();
                        tagPrefixes.putAll(Emitter.DEFAULT_TAG_PREFIXES_1_1);
                    }

                    if(null != ev.getTags()) {
                        var handles : Set = new HashSet();
                        handles.addAll(ev.getTags().keySet());
                        for(var iter : Iterator = handles.iterator();iter.hasNext();) {
                            var handle : String = iter.next() as String;
                            var prefix : String = ev.getTags().get(handle) as String;
                            tagPrefixes.put(prefix,handle);
                            var handleText : String = Emitter.prepareTagHandle(handle);
                            var prefixText : String = Emitter.prepareTagPrefix(prefix);
                            emitter.writeTagDirective(handleText,prefixText);
                        }
                    }
                }

                var implicit : Boolean = first && !ev.getExplicit() && !canonical && ev.getVersion() == null && ev.getTags() == null && !checkEmptyDocument();
                if(!implicit) {
                    emitter.writeIndent();
                    emitter.writeIndicator("--- ",true,true,false);
                    if(canonical) {
                        emitter.writeIndent();
                    }
                }
                state = Emitter.DOCUMENT_ROOT;
            } else if(event is StreamEndEvent) {
                emitter.writeStreamEnd();
                state = Emitter.NOTHING;
            } else {
                throw new EmitterException("expected DocumentStartEvent, but got " + event);
            }
        }

        public function expectDocumentRoot() : void {
            states.addAt(0,new int(Emitter.DOCUMENT_END));
            expectNode(true,false,false,false);
        }

        public function expectDocumentEnd() : void {
            if(event is DocumentEndEvent) {
                emitter.writeIndent();
                if((DocumentEndEvent(event)).getExplicit()) {
                    emitter.writeIndicator("...",true,false,false);
                    emitter.writeIndent();
                }
                emitter.flushStream();
                state = Emitter.DOCUMENT_START;
            } else {
                throw new EmitterException("expected DocumentEndEvent, but got " + event);
            }
        }

        public function expectFirstFlowSequenceItem() : void {
            if(event is SequenceEndEvent) {
                indent = int(indents.removeAtAndReturn(0));
                flowLevel--;
                emitter.writeIndicator("]",false,false,false);
                state = int(states.removeAtAndReturn(0));
            } else {
                if(canonical || column > bestWidth) {
                    emitter.writeIndent();
                }
                states.addAt(0,new int(Emitter.FLOW_SEQUENCE_ITEM));
                expectNode(false,true,false,false);
            }
        }

        public function expectFlowSequenceItem() : void {
            if(event is SequenceEndEvent) {
                indent = int(indents.removeAtAndReturn(0));
                flowLevel--;
                if(canonical) {
                    emitter.writeIndicator(",",false,false,false);
                    emitter.writeIndent();
                }
                emitter.writeIndicator("]",false,false,false);
                state = int(states.removeAtAndReturn(0));
            } else {
                emitter.writeIndicator(",",false,false,false);
                if(canonical || column > bestWidth) {
                    emitter.writeIndent();
                }
                states.addAt(0,new int(Emitter.FLOW_SEQUENCE_ITEM));
                expectNode(false,true,false,false);
            }
        }

        public function expectFirstFlowMappingKey() : void {
            if(event is MappingEndEvent) {
                indent = int(indents.removeAtAndReturn(0));
                flowLevel--;
                emitter.writeIndicator("}",false,false,false);
                state = int(states.removeAtAndReturn(0));
            } else {
                if(canonical || column > bestWidth) {
                    emitter.writeIndent();
                }
                if(!canonical && checkSimpleKey()) {
                    states.addAt(0,new int(Emitter.FLOW_MAPPING_SIMPLE_VALUE));
                    expectNode(false,false,true,true);
                } else {
                    emitter.writeIndicator("?",true,false,false);
                    states.addAt(0,new int(Emitter.FLOW_MAPPING_VALUE));
                    expectNode(false,false,true,false);
                }
            }
        }

        public function expectFlowMappingSimpleValue() : void {
            emitter.writeIndicator(": ",false,true,false);
            states.addAt(0,new int(Emitter.FLOW_MAPPING_KEY));
            expectNode(false,false,true,false);
        }

        public function expectFlowMappingValue() : void {
            if(canonical || column > bestWidth) {
                emitter.writeIndent();
            }
            emitter.writeIndicator(": ",false,true,false);
            states.addAt(0,new int(Emitter.FLOW_MAPPING_KEY));
            expectNode(false,false,true,false);
        }

        public function expectFlowMappingKey() : void {
            if(event is MappingEndEvent) {
                indent = (int(indents.removeAtAndReturn(0)));
                flowLevel--;
                if(canonical) {
                    emitter.writeIndicator(",",false,false,false);
                    emitter.writeIndent();
                }
                emitter.writeIndicator("}",false,false,false);
                state = int(states.removeAtAndReturn(0));
            } else {
                emitter.writeIndicator(",",false,false,false);
                if(canonical || column > bestWidth) {
                    emitter.writeIndent();
                }
                if(!canonical && checkSimpleKey()) {
                    states.addAt(0,new int(Emitter.FLOW_MAPPING_SIMPLE_VALUE));
                    expectNode(false,false,true,true);
                } else {
                    emitter.writeIndicator("?",true,false,false);
                    states.addAt(0,new int(Emitter.FLOW_MAPPING_VALUE));
                    expectNode(false,false,true,false);
                }
            }
        }

        public function expectBlockSequenceItem(first : Boolean) : void  {
            if(!first && event is SequenceEndEvent) {
                indent = int(indents.removeAtAndReturn(0));
                state = int(states.removeAtAndReturn(0));
            } else {
                emitter.writeIndent();
                emitter.writeIndicator("-",true,false,true);
                states.addAt(0,new int(Emitter.BLOCK_SEQUENCE_ITEM));
                expectNode(false,true,false,false);
            }
        }

        public function expectFirstBlockMappingKey() : void {
            expectBlockMappingKey(true);
        }

        public function expectBlockMappingSimpleValue() : void {
            emitter.writeIndicator(": ",false,true,false);
            states.addAt(0,new int(Emitter.BLOCK_MAPPING_KEY));
            expectNode(false,false,true,false);
        }

        public function expectBlockMappingValue() : void {
            emitter.writeIndent();
            emitter.writeIndicator(": ",true,true,true);
            states.addAt(0,new int(Emitter.BLOCK_MAPPING_KEY));
            expectNode(false,false,true,false);
        }

        public function expectBlockMappingKey(first : Boolean) : void {
            if(!first && event is MappingEndEvent) {
                indent = int(indents.removeAtAndReturn(0));
                state = int(states.removeAtAndReturn(0));
            } else {
                emitter.writeIndent();
                if(checkSimpleKey()) {
                    states.addAt(0,new int(Emitter.BLOCK_MAPPING_SIMPLE_VALUE));
                    expectNode(false,false,true,true);
                } else {
                    emitter.writeIndicator("?",true,false,true);
                    states.addAt(0,new int(Emitter.BLOCK_MAPPING_VALUE));
                    expectNode(false,false,true,false);
                }
            }
        }

        private function expectNode(root : Boolean, sequence : Boolean, mapping : Boolean, simpleKey : Boolean) : void {
            rootContext = root;
            sequenceContext = sequence;
            mappingContext = mapping;
            simpleKeyContext = simpleKey;
            if(event is AliasEvent) {
                expectAlias();
            } else if(event is ScalarEvent || event is CollectionStartEvent) {
                processAnchor("&");
                processTag();
                if(event is ScalarEvent) {
                    expectScalar();
                } else if(event is SequenceStartEvent) {
                    if(flowLevel != 0 || canonical || ((SequenceStartEvent(event))).getFlowStyle() || checkEmptySequence()) {
                        expectFlowSequence();
                    } else {
                        expectBlockSequence();
                    }
                } else if(event is MappingStartEvent) {
                    if(flowLevel != 0 || canonical || ((MappingStartEvent(event))).getFlowStyle() || checkEmptyMapping()) {
                        expectFlowMapping();
                    } else {
                        expectBlockMapping();
                    }
                }
            } else {
                throw new EmitterException("expected NodeEvent, but got " + event);
            }
        }
        
        private function expectAlias() : void {
            if((NodeEvent(event)).getAnchor() == null) {
                throw new EmitterException("anchor is not specified for alias");
            }
            processAnchor("*");
            state = int(states.removeAtAndReturn(0));
        }

        private function expectScalar() : void {
            increaseIndent(true,false);
            processScalar();
            indent = int(indents.removeAtAndReturn(0));
            state = int(states.removeAtAndReturn(0));
        }

        private function expectFlowSequence() : void {
            emitter.writeIndicator("[",true,true,false);
            flowLevel++;
            increaseIndent(true,false);
            state = Emitter.FIRST_FLOW_SEQUENCE_ITEM;
        }

        private function expectBlockSequence() : void {
            increaseIndent(false, !mappingContext && !indentation);
            state = Emitter.FIRST_BLOCK_SEQUENCE_ITEM;
        }

        private function expectFlowMapping(): void {
            emitter.writeIndicator("{",true,true,false);
            flowLevel++;
            increaseIndent(true,false);
            state = Emitter.FIRST_FLOW_MAPPING_KEY;
        }

        private function expectBlockMapping() : void { 
            increaseIndent(false,false);
            state = Emitter.FIRST_BLOCK_MAPPING_KEY;
        }

        private function checkEmptySequence() : Boolean {
            return event is SequenceStartEvent && !events.isEmpty() && events.get(0) is SequenceEndEvent;
        }

        private function checkEmptyMapping() : Boolean {
            return event is MappingStartEvent && !events.isEmpty() && events.get(0) is MappingEndEvent;
        }

        private function checkEmptyDocument() : Boolean {
            if(!(event is DocumentStartEvent) || events.isEmpty()) {
                return false;
            }
            var ev : Event = Event(events.get(0));
            return ev is ScalarEvent && (ScalarEvent(ev)).getAnchor() == null && (ScalarEvent(ev)).getTag() == null && (ScalarEvent(ev)).getImplicit() != null && (ScalarEvent(ev)).getValue() == "";
        }

        private function checkSimpleKey() : Boolean {
            var length : int = 0;
            if(event is NodeEvent && null != (NodeEvent(event)).getAnchor()) {
                if(null == preparedAnchor) {
                    preparedAnchor = Emitter.prepareAnchor((NodeEvent(event)).getAnchor());
                }
                length += preparedAnchor.length;
            }
            var tag : String = null;
            if(event is ScalarEvent) {
                tag = (ScalarEvent(event)).getTag();
            } else if(event is CollectionStartEvent) {
                tag = (CollectionStartEvent(event)).getTag();
            }
            if(tag != null) {
                if(null == preparedTag) {
                    preparedTag = emitter.prepareTag(tag);
                }
                length += preparedTag.length;
            }
            if(event is ScalarEvent) {
                if(null == analysis) {
                    analysis = Emitter.analyzeScalar((ScalarEvent(event)).getValue());
                    length += analysis.scalar.length;
                }
            }

            return (length < 128 && (event is AliasEvent || (event is ScalarEvent && !analysis.empty && !analysis.multiline) || checkEmptySequence() || checkEmptyMapping()));
        }
        
        private function processAnchor(indicator : String) : void {
            var ev : NodeEvent = event as NodeEvent;
            if(null == ev.getAnchor()) {
                preparedAnchor = null;
                return;
            }
            if(null == preparedAnchor) {
                preparedAnchor = Emitter.prepareAnchor(ev.getAnchor());
            }
            if(preparedAnchor != null && "" != preparedAnchor) {
                emitter.writeIndicator(indicator+preparedAnchor,true,false,false);
            }
            preparedAnchor = null;
        }
        
        private function processTag() : void {
            var tag : String = null;
            if(event is ScalarEvent) {
                var ev : ScalarEvent = ScalarEvent(event);
                tag = ev.getTag();
                if(style == 0) {
                    style = chooseScalarStyle();
                }
                if(((!canonical || tag == null) && (('0' == style && ev.getImplicit()[0]) || ('0' != style && ev.getImplicit()[1])))) {
                    preparedTag = null;
                    return;
                }
                if(ev.getImplicit()[0] && null == tag) {
                    tag = "!";
                    preparedTag = null;
                }
            } else {
                var eve : CollectionStartEvent = event as CollectionStartEvent;
                tag = eve.getTag();
                if((!canonical || tag == null) && eve.getImplicit()) {
                    preparedTag = null;
                    return;
                }
            }
            if(tag == null) {
                throw new EmitterException("tag is not specified");
            }
            if(null == preparedTag) {
                preparedTag = emitter.prepareTag(tag);
            }
            if(preparedTag != null && "" != preparedTag) {
                emitter.writeIndicator(preparedTag,true,false,false);
            }
            preparedTag = null;
        }

        private function chooseScalarStyle() : String {
             var ev : ScalarEvent = ScalarEvent(event);

            if(null == analysis) {
                analysis = Emitter.analyzeScalar(ev.getValue());
            }

            if(ev.getStyle() == '"' || this.canonical) {
                return '"';
            }
            
            if(ev.getStyle() == '0') {
                if(!(simpleKeyContext && (analysis.empty || analysis.multiline)) && ((flowLevel != 0 && analysis.allowFlowPlain) || (flowLevel == 0 && analysis.allowBlockPlain))) {
                    return '0';
                }
            }
            if(ev.getStyle() == '0' && ev.getImplicit()[0] && (!(simpleKeyContext && (analysis.empty || analysis.multiline)) && (flowLevel!=0 && analysis.allowFlowPlain || (flowLevel == 0 && analysis.allowBlockPlain)))) {
                return '0';
            }
            if((ev.getStyle() == '|') && flowLevel == 0 && analysis.allowBlock) {
                return '|';
            }            
            if((ev.getStyle() == '>') && flowLevel == 0 && analysis.allowBlock) {
                return '\'';
            }
            if((ev.getStyle() == '0' || ev.getStyle() == '\'') && (analysis.allowSingleQuoted && !(simpleKeyContext && analysis.multiline))) {
                return '\'';
            }

			var FIRST_SPACE : RegExp = new RegExp("(^|\n) ");
            if(analysis.multiline && !FIRST_SPACE.exec(ev.getValue()).find() && !analysis.specialCharacters) {
                return '|';
            }
            return '"';
            
        }

        private function processScalar() : void{
            var ev : ScalarEvent = ScalarEvent(event);

            if(null == analysis) {
                analysis = Emitter.analyzeScalar(ev.getValue());
            }
            if(0 == style) {
                style = chooseScalarStyle();
            }
            var split : Boolean = !simpleKeyContext;
            if(style == '"') {
                emitter.writeDoubleQuoted(analysis.scalar,split);
            } else if(style == '\'') {
                emitter.writeSingleQuoted(analysis.scalar,split);
            } else if(style == '>') {
                emitter.writeFolded(analysis.scalar);
            } else if(style == '|') {
                emitter.writeLiteral(analysis.scalar);
            } else {
                emitter.writePlain(analysis.scalar,split);
            }
            analysis = null;
            style = 0;
        }
    }
 }