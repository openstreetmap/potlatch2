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
  
  /**
   * The class <code>Exception</code> and its subclasses are a form of 
   * <code>Throwable</code> that indicates conditions that a reasonable 
   * application might want to catch.
   * 
   * @author sleistner
   */
  public class Exception extends Throwable {
    
    /**
     * Constructs a new exception with the specified detail message.
     *
     * @param   message   the detail message. The detail message is saved for 
     *          later retrieval by the #getMessage() method.
     */
    function Exception(message:String) {
      super(message);
    }
  }
}