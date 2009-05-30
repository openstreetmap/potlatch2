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
   * This exception may be thrown by methods that have detected concurrent
   * modification of an object when such modification is not permissible.
   * <p>
   * For example, it is not generally permissible for one thread to modify a Collection
   * while another thread is iterating over it.  In general, the results of the
   * iteration are undefined under these circumstances.  Some Iterator
   * implementations may choose to throw this exception if this behavior is
   * detected.  Iterators that do this are known as <i>fail-fast</i> iterators,
   * as they fail quickly and cleanly, rather that risking arbitrary,
   * non-deterministic behavior at an undetermined time in the future.
   * <p>
   * Note that this exception does not always indicate that an object has
   * been concurrently modified by a <i>different</i> thread.  If a single
   * thread issues a sequence of method invocations that violates the
   * contract of an object, the object may throw this exception.  For
   * example, if a thread modifies a collection directly while it is
   * iterating over the collection with a fail-fast iterator, the iterator
   * will throw this exception.
   *
   * <p>Note that fail-fast behavior cannot be guaranteed as it is, generally
   * speaking, impossible to make any hard guarantees in the presence of
   * unsynchronized concurrent modification.  Fail-fast operations
   * throw <tt>ConcurrentModificationException</tt> on a best-effort basis. 
   * Therefore, it would be wrong to write a program that depended on this
   * exception for its correctness: <i><tt>ConcurrentModificationException</tt>
   * should be used only to detect bugs.</i>
   * 
   * @author sleistner
   */
  public class ConcurrentModificationException extends Exception {
    
    /**
     * Constructs a <tt>ConcurrentModificationException</tt> with the
     * specified detail message.
     *
     * @param message the detail message pertaining to this exception.
     */
    function ConcurrentModificationException(message:String = '') {
      super(message);
    }
  }
}