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
   * Thrown when an application attempts to use <code>null</code> in a 
   * case where an object is required. These include: 
   * <ul>
   * <li>Calling the instance method of a <code>null</code> object. 
   * <li>Accessing or modifying the field of a <code>null</code> object. 
   * <li>Taking the length of <code>null</code> as if it were an array. 
   * <li>Accessing or modifying the slots of <code>null</code> as if it 
   *     were an array. 
   * <li>Throwing <code>null</code> as if it were a <code>Throwable</code> 
   *     value. 
   * </ul>
   * <p>
   * Applications should throw instances of this class to indicate 
   * other illegal uses of the <code>null</code> object. 
   * 
   * @author sleistner
   */
  public class NullPointerException extends Exception {
    
    /**
     * Constructs a <code>NullPointerException</code> with the specified 
     * detail message. 
     *
     * @param message   the detail message.
     */
    function NullPointerException(message:String = '') {
      super(message);
    }
  }
}