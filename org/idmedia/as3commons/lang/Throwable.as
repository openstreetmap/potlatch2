/*
 * Copyright the original author or authors.
 * 
 * Licensed under the MOZILLA PUBLIC LICENSE, Version 1.1 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.mozilla.org/MPL/MPL-1.1.html
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.idmedia.as3commons.lang {
  import flash.utils.getQualifiedClassName;
  
  /**
   * The <code>Throwable</code> class is the superclass of all errors and
   * exceptions in the ActionScript language. Only objects that are instances of this
   * class (or one of its subclasses) are thrown by the Flash Virtual Machine or
   * can be thrown by the ActionScript <code>throw</code> statement. Similarly, only
   * this class or one of its subclasses can be the argument type in a
   * <code>catch</code> clause.
   * 
   * <p>Instances of one subclass <code>Exception</code>, are conventionally 
   * used to indicate that exceptional situations have occurred. 
   * Typically, these instances are freshly created in the context of 
   * the exceptional situation so as to include relevant 
   * information (such as stack trace data).
   * 
   * @author sleistner
   */
  public class Throwable extends Error {
    
    function Throwable(message:String) {
      super(message);
    }
    
    public function getMessage():String {
      return message;	
    }
    
    public function getName():String {
      return getQualifiedClassName(this);	
    }
  }
}