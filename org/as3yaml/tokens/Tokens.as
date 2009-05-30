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

package org.as3yaml.tokens
{
	public class Tokens
	{
		public static var DOCUMENT_END: Token = new DocumentEndToken();
		public static var DOCUMENT_START: Token = new DocumentStartToken();
		public static var BLOCK_MAPPING_START: Token = new BlockMappingStartToken();
		public static var BLOCK_SEQUENCE_START: Token = new BlockSequenceStartToken();
		public static var BLOCK_ENTRY: Token = new BlockEntryToken();
		public static var BLOCK_END: Token = new BlockEndToken();
		public static var FLOW_ENTRY: Token = new FlowEntryToken();
		public static var FLOW_MAPPING_END: Token = new FlowMappingEndToken();
		public static var FLOW_MAPPING_START: Token = new FlowMappingStartToken();
		public static var FLOW_SEQUENCE_END: Token = new FlowSequenceEndToken();
		public static var FLOW_SEQUENCE_START: Token = new FlowSequenceStartToken();
		public static var KEY: Token = new KeyToken();
		public static var VALUE: Token = new ValueToken();
		public static var STREAM_END: Token = new StreamEndToken();
		public static var STREAM_START: Token = new StreamStartToken();
	}
}