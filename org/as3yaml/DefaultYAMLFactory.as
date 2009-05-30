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

import org.rxr.actionscript.io.*;

public class DefaultYAMLFactory implements YAMLFactory {
    public function createScanner(io : String) : Scanner {
        return new Scanner(io);
    }
    public function createParser(scanner : Scanner, cfg : YAMLConfig) : Parser {
        return new Parser(scanner,cfg);
    }
    public function createResolver() : Resolver {
        return new Resolver();
    }
    public function createComposer(parser : Parser,  resolver : Resolver) : Composer {
        return new Composer(parser,resolver);
    }
    public function createConstructor(composer : Composer) : Constructor {
        return new ConstructorImpl(composer);
    }
    public function createEmitter(output : StringWriter, cfg : YAMLConfig) : Emitter {
        return new Emitter(output,cfg);
    }
    public function createSerializer(emitter : Emitter, resolver : Resolver, cfg : YAMLConfig) : Serializer {
        return new Serializer(emitter,resolver,cfg);
    }
    public function createRepresenter(serializer : Serializer, cfg : YAMLConfig) : Representer {
        return new Representer(serializer,cfg);
    }
}
}