/*
 * Copyright the original author or authors.
 * 
 * Licensed under the MOZILLA PUBLIC LICENSE, Version 1.1 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.mozilla.org/MPL/MPL-1.1.html
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.idmedia.as3commons.util {
  import org.idmedia.as3commons.lang.UnsupportedOperationException;
  import org.idmedia.as3commons.lang.IndexOutOfBoundsException;
  
  /**
   * This class provides a skeletal implementation of the <tt>List</tt>
   * interface to minimize the effort required to implement this interface
   * backed by a "random access" data store (such as an array).  For sequential
   * access data (such as a linked list), <tt>AbstractSequentialList</tt> should
   * be used in preference to this class.<p>
   *
   * To implement an unmodifiable list, the programmer needs only to extend this
   * class and provide implementations for the <tt>get(int index)</tt> and
   * <tt>size()</tt> methods.<p>
   *
   * To implement a modifiable list, the programmer must additionally override
   * the <tt>set(int index, Object element)</tt> method (which otherwise throws
   * an <tt>UnsupportedOperationException</tt>.  If the list is variable-size
   * the programmer must additionally override the <tt>add(int index, Object
   * element)</tt> and <tt>remove(int index)</tt> methods.<p>
   *
   * Unlike the other abstract collection implementations, the programmer does
   * <i>not</i> have to provide an iterator implementation; the iterator and
   * list iterator are implemented by this class, on top the "random access"
   * methods: <tt>get(index:int)</tt>, <tt>setAt(index:int, value:*)</tt>,
   * <tt>set(int index, Object element)</tt>, <tt>add(int index, Object
   * element)</tt> and <tt>remove(int index)</tt>.<p>
   *
   * The documentation for each non-abstract methods in this class describes its
   * implementation in detail.  Each of these methods may be overridden if the
   * collection being implemented admits a more efficient implementation.<p>
   *
   * @author  sleistner
   * @see Collection
   * @see List
   * @see AbstractCollection
   */
  public class AbstractList extends AbstractCollection implements List {
    
    private var modCount:int = 0;
    
    /**
     * Sole constructor.  (For invocation by subclass constructors, typically
     * implicit.)
     */
    function AbstractList() {
    }
    
    /**
     * Appends the specified element to the end of this List (optional
     * operation). <p>
     *
     * This implementation calls <tt>addAt(size(), value)</tt>.<p>
     *
     * Note that this implementation throws an
     * <tt>UnsupportedOperationException</tt> unless <tt>add(int, Object)</tt>
     * is overridden.
     *
     * @param value element to be appended to this list.
     * 
     * @return <tt>true</tt> (as per the general contract of
     * <tt>Collection.add</tt>).
     * 
     * @throws UnsupportedOperationException if the <tt>add</tt> method is not
     * 		  supported by this Set.
     * 
     * @throws IllegalArgumentException some aspect of this element prevents
     *            it from being added to this collection.
     */
    override public function add(value:*):Boolean {
      return addAt(size(), value);
    }
    
    /**
     * Returns the element at the specified position in this list.
     *
     * @param index index of element to return.
     * 
     * @return the element at the specified position in this list.
     * @throws IndexOutOfBoundsException if the given index is out of range
     * 		  (<tt>index &lt; 0 || index &gt;= size()</tt>).
     */
    public function get(index:int):* {
      return null;	
    }
    
    /**
     * Inserts the specified element at the specified position in this list
     * (optional operation).  Shifts the element currently at that position
     * (if any) and any subsequent elements to the right (adds one to their
     * indices).<p>
     *
     * This implementation always throws an UnsupportedOperationException.
     *
     * @param index index at which the specified element is to be inserted.
     * @param value element to be inserted.
     * 
     * @throws UnsupportedOperationException if the <tt>add</tt> method is not
     *		  supported by this list.
     * @throws IllegalArgumentException if some aspect of the specified
     *		  element prevents it from being added to this list.
     * @throws IndexOutOfBoundsException index is out of range (<tt>index &lt;
     *		  0 || index &gt; size()</tt>).
     */
    public function addAt(index:int, value:*):Boolean {
      throw new UnsupportedOperationException();
    }
    
    /**
     * Replaces the element at the specified position in this list with the
     * specified element (optional operation). <p>
     *
     * This implementation always throws an
     * <tt>UnsupportedOperationException</tt>.
     *
     * @param index index of element to replace.
     * @param value element to be stored at the specified position.
     * @return the element previously at the specified position.
     * 
     * @throws UnsupportedOperationException if the <tt>set</tt> method is not
     *		  supported by this List.
     * @throws IllegalArgumentException if some aspect of the specified
     *		  element prevents it from being added to this list.
     * 
     * @throws IndexOutOfBoundsException if the specified index is out of
     *            range (<tt>index &lt; 0 || index &gt;= size()</tt>).
     */
    public function setAt(index:int, value:*):Boolean {
      throw new UnsupportedOperationException();
    }
    
    /**
     * Adds all of the elements in the specified collection to this collection
     * (optional operation).  The behavior of this operation is undefined if
     * the specified collection is modified while the operation is in
     * progress.  (This implies that the behavior of this call is undefined if
     * the specified collection is this collection, and this collection is
     * nonempty.) <p>
     *
     * This implementation iterates over the specified collection, and adds
     * each object returned by the iterator to this collection, in turn.<p>
     *
     * Note that this implementation will throw an
     * <tt>UnsupportedOperationException</tt> unless <tt>add</tt> is
     * overridden (assuming the specified collection is non-empty).
     *
     * @param c collection whose elements are to be added to this collection.
     * @return <tt>true</tt> if this collection changed as a result of the
     *         call.
     * @throws UnsupportedOperationException if this collection does not
     *         support the <tt>addAll</tt> method.
     * @throws NullPointerException if the specified collection is null.
     * 
     * @see #add(Object)
     */
    override public function addAll(collection:Collection):Boolean {
      throw new UnsupportedOperationException();
    }
    
    /**
     * Removes all of the elements from this collection (optional operation).
     * The collection will be empty after this call returns (unless it throws
     * an exception).<p>
     *
     * This implementation iterates over this collection, removing each
     * element using the <tt>Iterator.remove</tt> operation.  Most
     * implementations will probably choose to override this method for
     * efficiency.<p>
     *
     * Note that this implementation will throw an
     * <tt>UnsupportedOperationException</tt> if the iterator returned by this
     * collection's <tt>iterator</tt> method does not implement the
     * <tt>remove</tt> method and this collection is non-empty.
     *
     * @throws UnsupportedOperationException if the <tt>clear</tt> method is
     * 		  not supported by this collection.
     */
    override public function clear():void {
      removeRange(0, size());
    }
    
    /**
     * Returns an iterator over the elements in this list in proper
     * sequence. <p>
     *
     * This implementation returns a straightforward implementation of the
     * iterator interface, relying on the backing list's <tt>size()</tt>,
     * <tt>get(int)</tt>, and <tt>remove(int)</tt> methods.<p>
     *
     * Note that the iterator returned by this method will throw an
     * <tt>UnsupportedOperationException</tt> in response to its
     * <tt>remove</tt> method unless the list's <tt>remove(int)</tt> method is
     * overridden.<p>
     *
     * @return an iterator over the elements in this list in proper sequence.
     */
    override public function iterator():Iterator {
      return new ListIteratorImpl(this);
    }
    
    /**
     * Returns an iterator of the elements in this list (in proper sequence).
     * This implementation returns <tt>listIterator(0)</tt>.
     * 
     * @return an iterator of the elements in this list (in proper sequence).
     * 
     * @see #indexedListIterator(int)
     */
    public function listIterator():ListIterator {
      return new ListIteratorImpl(this);
    }
    
    /**
     * Returns a list iterator of the elements in this list (in proper
     * sequence), starting at the specified position in the list.  The
     * specified index indicates the first element that would be returned by
     * an initial call to the <tt>next</tt> method.  An initial call to
     * the <tt>previous</tt> method would return the element with the
     * specified index minus one.<p>
     *
     * This implementation returns a straightforward implementation of the
     * <tt>ListIterator</tt> interface that extends the implementation of the
     * <tt>Iterator</tt> interface returned by the <tt>iterator()</tt> method.
     * The <tt>ListIterator</tt> implementation relies on the backing list's
     * <tt>getAt(int)</tt>, <tt>setAt(int, *)</tt>, <tt>addAt(int, *)</tt>
     * and <tt>remove(int)</tt> methods.<p>
     *
     * Note that the list iterator returned by this implementation will throw
     * an <tt>UnsupportedOperationException</tt> in response to its
     * <tt>remove</tt>, <tt>set</tt> and <tt>add</tt> methods unless the
     * list's <tt>removeAt(int)</tt>, <tt>setAt(int, *)</tt>, and
     * <tt>addAt(int, *)</tt> methods are overridden.<p>
     *
     * This implementation can be made to throw runtime exceptions in the
     * face of concurrent modification, as described in the specification for
     * the (protected) <tt>modCount</tt> field.
     *
     * @param index index of the first element to be returned from the list
     *		    iterator (by a call to the <tt>next</tt> method).
     * 
     * @return a list iterator of the elements in this list (in proper
     * 	       sequence), starting at the specified position in the list.
     * 
     * @throws IndexOutOfBoundsException if the specified index is out of
     *		  range (<tt>index &lt; 0 || index &gt; size()</tt>).
     * 
     */
    public function indexedListIterator(index:uint):ListIterator {
      if(index < 0 || index > size()) {
        throw new IndexOutOfBoundsException('Index: ' + index);
      }
      var iter:ListIterator = listIterator();
      iter.setIndex(index);
      return iter;
    }
    
    /**
     * Removes the element at the specified position in this list (optional
     * operation).  Shifts any subsequent elements to the left (subtracts one
     * from their indices).  Returns the element that was removed from the
     * list.<p>
     *
     * This implementation always throws an
     * <tt>UnsupportedOperationException</tt>.
     *
     * @param index the index of the element to remove.
     * @return the element previously at the specified position.
     * 
     * @throws UnsupportedOperationException if the <tt>remove</tt> method is
     *		  not supported by this list.
     * @throws IndexOutOfBoundsException if the specified index is out of
     * 		  range (<tt>index &lt; 0 || index &gt;= size()</tt>).
     */
    public function removeAt(index:int):Boolean {
      throw new UnsupportedOperationException();
    }
    
    public function removeAtAndReturn(index:int):* {
      throw new UnsupportedOperationException();
    }
    
    public function removeAtTo(index:int, toPos:int):Boolean {
      throw new UnsupportedOperationException();
    }
    
    private function removeRange(fromIndex:int, toIndex:int):void {
      var listIter:ListIterator = indexedListIterator(fromIndex);
      for(var i:int = 0, n:int = toIndex - fromIndex;i < n; i++) {
        listIter.next();
        listIter.remove();
      }
    }
    
    /**
     * Returns the index in this list of the first occurence of the specified
     * element, or -1 if the list does not contain this element.  More
     * formally, returns the lowest index <tt>i</tt> such that <tt>(o==null ?
     * get(i)==null : o.equals(get(i)))</tt>, or -1 if there is no such
     * index.<p>
     *
     * This implementation first gets a list iterator (with
     * <tt>listIterator()</tt>).  Then, it iterates over the list until the
     * specified element is found or the end of the list is reached.
     *
     * @param value element to search for.
     * 
     * @return the index in this List of the first occurence of the specified
     * 	       element, or -1 if the List does not contain this element.
     */
    public function indexOf(elem:* = null):int {
      return toArray().indexOf(elem);
    }
  }
}

import org.idmedia.as3commons.util.List;
import org.idmedia.as3commons.util.ListIterator;
import org.idmedia.as3commons.util.Iterator;
import org.idmedia.as3commons.lang.IndexOutOfBoundsException;
import org.idmedia.as3commons.lang.IllegalStateException;
import org.idmedia.as3commons.lang.NoSuchElementException;
import org.idmedia.as3commons.lang.ConcurrentModificationException;

internal class IteratorImpl implements Iterator {
  
  protected var cursor:int = 0;
  protected var lastRet:int = -1;
  protected var list:List;
  
  function IteratorImpl(list:List) {
    this.list = list;
  }
  
  public function hasNext():Boolean {
    return cursor < list.size();
  }
  
  public function next():* {
    try {
      var nextValue:* = list.get(cursor);
      lastRet = cursor;
      cursor++;
      return nextValue;
    } catch(e:IndexOutOfBoundsException) {
      throw new NoSuchElementException();
    }
  }
  
  public function remove():void {
    if (lastRet == -1) {
      throw new IllegalStateException();
    }
						
    try {
      list.removeAt(lastRet);
      if (lastRet < cursor) {
        cursor--;
      }
      lastRet = -1;
    } catch(e:IndexOutOfBoundsException) {
      throw new ConcurrentModificationException(e.getMessage());
    }
  }
}	

internal class ListIteratorImpl extends IteratorImpl implements ListIterator {
  
  function ListIteratorImpl(list:List) {
    super(list);
  }
  
  public function hasPrevious():Boolean {
    return cursor != 0;
  }
  
  public function previous():* {
    try {
      var i:int = cursor - 1;
      var previousValue:* = list.get(i);
      lastRet = cursor = i;
      return previousValue;
    } catch(e:IndexOutOfBoundsException) {
      throw new NoSuchElementException();
    }
  }
  
  public function nextIndex():int {
    return cursor;
  }
  
  public function previousIndex():int {
    return cursor - 1;
  }
  
  public function setValue(object:*):void {
    if(lastRet == -1) {
      throw new IllegalStateException();
    }
		
    try {
      list.setAt(lastRet, object);
    } catch(e:IndexOutOfBoundsException) {
      throw new ConcurrentModificationException();
    }
  }
  
  public function add(object:*):void {
    try {
      list.addAt(cursor++, object);
      lastRet = -1;
    } catch(e:IndexOutOfBoundsException) {
      throw new ConcurrentModificationException();
    }
  }
  
  public function setIndex(index:int):void {
    if(index < 0 || index >= list.size()) {
      throw new IndexOutOfBoundsException('Index: ' + index);
    }
    cursor = index;
  }
}
