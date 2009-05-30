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
package org.idmedia.as3commons.util {
  import org.idmedia.as3commons.lang.NullPointerException;
  import org.idmedia.as3commons.lang.IndexOutOfBoundsException;
  
  /**
   * Resizable-array implementation of the <tt>List</tt> interface.  Implements
   * all optional list operations, and permits all elements, including
   * <tt>null</tt>.  In addition to implementing the <tt>List</tt> interface,
   * this class provides methods to manipulate the size of the array that is
   * used internally to store the list.<p>
   *
   * An application can increase the capacity of an <tt>ArrayList</tt> instance
   * before adding a large number of elements using the <tt>ensureCapacity</tt>
   * operation.  This may reduce the amount of incremental reallocation.<p>
   *
   * The iterators returned by this class's <tt>iterator</tt> and
   * <tt>listIterator</tt> methods are <i>fail-fast</i>: if list is structurally
   * modified at any time after the iterator is created, in any way except
   * through the iterator's own remove or add methods, the iterator will throw a
   * ConcurrentModificationException.  Thus, in the face of concurrent
   * modification, the iterator fails quickly and cleanly, rather than risking
   * arbitrary, non-deterministic behavior at an undetermined time in the
   * future.<p>
   *
   * Note that the fail-fast behavior of an iterator cannot be guaranteed
   * as it is, generally speaking, impossible to make any hard guarantees in the
   * presence of unsynchronized concurrent modification.  Fail-fast iterators
   * throw <tt>ConcurrentModificationException</tt> on a best-effort basis. 
   * Therefore, it would be wrong to write a program that depended on this
   * exception for its correctness: <i>the fail-fast behavior of iterators
   * should be used only to detect bugs.</i><p>
   * 
   * @author sleistner
   */
  public class ArrayList extends AbstractList implements List {
    
    private var elementData:Array;
    private var elementSize:int;
    
    /**
     * @param  value Collection
     */
    public function ArrayList(value:Collection = null) {
      elementData = new Array();
      elementSize = 0;
      if(value != null) {
        elementData = elementData.concat(value.toArray());
        elementSize = elementData.length;
      }
    }
    
    /**
     * Appends the specified element to the end of this list.
     *
     * @param elem element to be appended to this list.
     * @return <tt>true</tt> (as per the general contract of Collection.add).
     */
    override public function add(elem:*):Boolean {
      elementData[elementSize++] = elem;
      return true;	
    }
    
    override public function setAt(index:int, value:*):Boolean {
      rangeCheck(index);
      elementData[index] = value;
      return true;
    }
    
    override public function addAt(index:int, value:*):Boolean {
      rangeCheck(index);
      var s:Array = elementData.slice(0, index);
      var e:Array = elementData.slice(index);
      elementData = s.concat(value).concat(e);
      elementSize = elementData.length;
      return true;
    }
    
    /**
     * Appends all of the elements in the specified Collection to the end of
     * this list, in the order that they are returned by the
     * specified Collection's Iterator.  The behavior of this operation is
     * undefined if the specified Collection is modified while the operation
     * is in progress.  (This implies that the behavior of this call is
     * undefined if the specified Collection is this list, and this
     * list is nonempty.)
     *
     * @param c the elements to be inserted into this list.
     * @return <tt>true</tt> if this list changed as a result of the call.
     * @throws    NullPointerException if the specified collection is null.
     */
    override public function addAll(c:Collection):Boolean {
      if(c == null) {
        throw new NullPointerException();	
      }
      var a:Array = c.toArray();
      var newNum:int = elementSize + a.length;
      elementData = elementData.concat(a);
      elementSize = elementData.length;
      return elementSize === newNum;
    }
    
    /**
     * Returns the element at the specified position in this list.
     *
     * @param  index index of element to return.
     * @return the element at the specified position in this list.
     * @throws    IndexOutOfBoundsException if index is out of range <tt>(index
     * 		  &lt; 0 || index &gt;= size())</tt>.
     */
    override public function get(index:int):* {
      rangeCheck(index);
      return elementData[index];
    }
    
    /**
     * Removes the element at the specified position in this list.
     * Shifts any subsequent elements to the left (subtracts one from their
     * indices).
     *
     * @param index the index of the element to removed.
     * @return boolean
     * @throws    IndexOutOfBoundsException if index out of range <tt>(index
     * 		  &lt; 0 || index &gt;= size())</tt>.
     */
    override public function removeAt(index:int):Boolean {
      return removeAtTo(index, 1);
    }
    
    /**
     * Removes the element at the specified position in this list.
     * Shifts any subsequent elements to the left (subtracts one from their
     * indices).
     *
     * @param index the index of the element to removed.
     * @return the element that was removed from the list.
     * @throws    IndexOutOfBoundsException if index out of range <tt>(index
     * 		  &lt; 0 || index &gt;= size())</tt>.
     */
    override public function removeAtAndReturn(index:int):* {
      return removeAtToAndReturn(index, 1);
    }
    
    /**
     * Removes the elements at the specified start position to end position 
     * in this list.
     * Shifts any subsequent elements to the left (subtracts one from their
     * indices).
     *
     * @param index the index of the element to removed.
     * @param to the last element to remove
     * @return boolean
     * @throws    IndexOutOfBoundsException if index out of range <tt>(index
     * 		  &lt; 0 || index &gt;= size())</tt>.
     */
    override public function removeAtTo(index:int, toPos:int):Boolean {
      rangeCheck(index);
      elementData.splice(index, toPos);
      elementSize = elementData.length;
      return true;
    }
    
    /**
     * Removes the elements at the specified start position to end position 
     * in this list.
     * Shifts any subsequent elements to the left (subtracts one from their
     * indices).
     *
     * @param index the index of the element to removed.
     * @param to the last element to remove
     * @return the element that was removed from the list.
     * @throws    IndexOutOfBoundsException if index out of range <tt>(index
     * 		  &lt; 0 || index &gt;= size())</tt>.
     */
    public function removeAtToAndReturn(index:int, to:int):* {
      rangeCheck(index);
      var old:* = get(index);
      removeAtTo(index, to);
      return old;
    }
    
    /**
     * Removes all of the elements from this list.  The list will
     * be empty after this call returns.
     */
    override public function clear():void {
      elementData = new Array();
      elementSize = 0;
    }
    
    /**
     * Returns the number of elements in this list.
     *
     * @return  the number of elements in this list.
     */
    override public function size():int {
      return elementSize || 0;
    }
    
    /**
     * Tests if this list has no elements.
     *
     * @return  <tt>true</tt> if this list has no elements;
     *          <tt>false</tt> otherwise.
     */
    override public function isEmpty():Boolean {
      return elementSize == 0;
    }
    
    /**
     * Returns an array containing all of the elements in this list
     * in the correct order.
     *
     * @return an array containing all of the elements in this list
     * 	       in the correct order.
     */
    override public function toArray():Array {
      return [].concat(elementData);
    }
    
    /**
     * Check if the given index is in range.
     */
    private function rangeCheck(index:int):void {
      if (index > elementSize || index < 0) {
        throw new IndexOutOfBoundsException("Index: " + index + ", " + "Size: " + elementSize);
      }
    }
  }
}
