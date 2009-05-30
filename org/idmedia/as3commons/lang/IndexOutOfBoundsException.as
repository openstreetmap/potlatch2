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
   * Thrown to indicate that an index of some sort (such as to an array, to a
   * string, or to a vector) is out of range. 
   * <p>
   * Applications can subclass this class to indicate similar exceptions. 
   * 
   * @author sleistner
   */
  public class IndexOutOfBoundsException extends Exception {
    
    /**
     * Constructs a <code>NullPointerException</code> with the specified 
     * detail message. 
     *
     * @param message   the detail message.
     */
    function IndexOutOfBoundsException(message:String = '') {
      super(message);
    }
  }
}
