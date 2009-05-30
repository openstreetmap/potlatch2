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
﻿package org.idmedia.as3commons.util {
  import org.idmedia.as3commons.lang.UnsupportedOperationException;
  
  /**
   * This class provides a skeletal implementation of the <tt>Collection</tt>
   * interface, to minimize the effort required to implement this interface. <p>
   *
   * To implement an unmodifiable collection, the programmer needs only to
   * extend this class and provide implementations for the <tt>iterator</tt> and
   * <tt>size</tt> methods.  (The iterator returned by the <tt>iterator</tt>
   * method must implement <tt>hasNext</tt> and <tt>next</tt>.)<p>
   *
   * To implement a modifiable collection, the programmer must additionally
   * override this class's <tt>add</tt> method (which otherwise throws an
   * <tt>UnsupportedOperationException</tt>), and the iterator returned by the
   * <tt>iterator</tt> method must additionally implement its <tt>remove</tt>
   * method.<p>
   *
   * The documentation for each non-abstract methods in this class describes its
   * implementation in detail.  Each of these methods may be overridden if
   * the collection being implemented admits a more efficient implementation.<p>
   *
   * @author sleistner
   * @see Collection
   */
  public class AbstractCollection implements Collection {
    
    /**
     * Ensures that this collection contains the specified element (optional
     * operation).  Returns <tt>true</tt> if the collection changed as a
     * result of the call.  (Returns <tt>false</tt> if this collection does
     * not permit duplicates and already contains the specified element.)
     * Collections that support this operation may place limitations on what
     * elements may be added to the collection.  In particular, some
     * collections will refuse to add <tt>null</tt> elements, and others will
     * impose restrictions on the type of elements that may be added.
     * Collection classes should clearly specify in their documentation any
     * restrictions on what elements may be added.<p>
     *
     * This implementation always throws an
     * <tt>UnsupportedOperationException</tt>.
     *
     * @param o element whose presence in this collection is to be ensured.
     * @return <tt>true</tt> if the collection changed as a result of the call.
     * 
     * @throws UnsupportedOperationException if the <tt>add</tt> method is not
     *		  supported by this collection.
     * 
     * @throws NullPointerException if this collection does not permit
     * 		  <tt>null</tt> elements, and the specified element is
     * 		  <tt>null</tt>.
     * 
     * @throws IllegalArgumentException if some aspect of this element
     *            prevents it from being added to this collection.
     */
    public function add(value:*):Boolean {
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
     * @see #add(*)
     */
    public function addAll(c:Collection):Boolean {
      var modified:Boolean = false;
      var e:Iterator = c.iterator();
      while(e.hasNext()) {
        if(add(e.next())) {
          modified = true;
        }
      }
      return modified;	
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
    public function clear():void {
      var iter:Iterator = iterator();
      while(iter.hasNext()) {
        iter.next();
        iter.remove();
      }
    }
    
    /**
     * Returns <tt>true</tt> if this list contains the specified element.
     *
     * @param elem element whose presence in this List is to be tested.
     * @return  <code>true</code> if the specified element is present;
     *		<code>false</code> otherwise.
     */
    public function contains(value:*):Boolean {
      return toArray().indexOf(value) > -1;
    }
    
    /**
     * Returns <tt>true</tt> if this collection contains all of the elements
     * in the specified collection. <p>
     *
     * This implementation iterates over the specified collection, checking
     * each element returned by the iterator in turn to see if it's
     * contained in this collection.  If all elements are so contained
     * <tt>true</tt> is returned, otherwise <tt>false</tt>.
     *
     * @param c collection to be checked for containment in this collection.
     * @return <tt>true</tt> if this collection contains all of the elements
     * 	       in the specified collection.
     * @throws NullPointerException if the specified collection is null.
     * 
     * @see #contains(*)
     */
    public function containsAll(c:Collection):Boolean {
      var e:Iterator = c.iterator();
      while(e.hasNext()) {
        if(!contains(e.next())) {
          return false;
        }
      }
      return true;
    }
    
    /**
     * Returns <tt>true</tt> if this collection contains no elements.<p>
     *
     * This implementation returns <tt>size() == 0</tt>.
     *
     * @return <tt>true</tt> if this collection contains no elements.
     */
    public function isEmpty():Boolean {
      return size() == 0;
    }
    
    /**
     * Returns an iterator over the elements contained in this collection.
     *
     * @return an iterator over the elements contained in this collection.
     */
    public function iterator():Iterator {
      return null;
    }
    
    /**
     * Removes a single instance of the specified element from this
     * collection, if it is present (optional operation). 
     * Returns <tt>true</tt> if the collection contained the
     * specified element (or equivalently, if the collection changed as a
     * result of the call).<p>
     *
     * This implementation iterates over the collection looking for the
     * specified element.  If it finds the element, it removes the element
     * from the collection using the iterator's remove method.<p>
     *
     * Note that this implementation throws an
     * <tt>UnsupportedOperationException</tt> if the iterator returned by this
     * collection's iterator method does not implement the <tt>remove</tt>
     * method and this collection contains the specified object.
     *
     * @param value element to be removed from this collection, if present.
     * @return <tt>true</tt> if the collection contained the specified
     *         element.
     * @throws UnsupportedOperationException if the <tt>remove</tt> method is
     * 		  not supported by this collection.
     */
    public function remove(value:* = null):Boolean {
      var iter:Iterator = iterator();
      while(iter.hasNext()) {
        if(iter.next() == value) {
          iter.remove();
          return true;
        }
      }		
      return false;
    }
    
    /**
     * Returns the number of elements in this collection.  If the collection
     * contains more than <tt>int.MAX_VALUE</tt> elements, returns
     * <tt>int.MAX_VALUE</tt>.
     *
     * @return the number of elements in this collection.
     */
    public function size():int {
      return 0;	
    }
    
    /**
     * Returns an array containing all of the elements in this collection.  If
     * the collection makes any guarantees as to what order its elements are
     * returned by its iterator, this method must return the elements in the
     * same order.  The returned array will be "safe" in that no references to
     * it are maintained by the collection.  (In other words, this method must
     * allocate a new array even if the collection is backed by an Array).
     * The caller is thus free to modify the returned array.<p>
     *
     * This implementation allocates the array to be returned, and iterates
     * over the elements in the collection, storing each object reference in
     * the next consecutive element of the array, starting with element 0.
     *
     * @return an array containing all of the elements in this collection.
     */
    public function toArray():Array {
      var result:Array = new Array();
      var iter:Iterator = iterator();
      while(iter.hasNext()) {
        result.push(iter.next());
      }
      return result;
    }
    
    public function equals(object:*):Boolean {
      return object === this;
    }
  }
}