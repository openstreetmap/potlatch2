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
  
  /**
   * 
   * An iterator for lists that allows the programmer 
   * to traverse the list in either direction, modify 
   * the list during iteration, and obtain the iterator's 
   * current position in the list. A <TT>ListIterator</TT> 
   * has no current element; its <I>cursor position</I> always 
   * lies between the element that would be returned by a call 
   * to <TT>previous()</TT> and the element that would be 
   * returned by a call to <TT>next()</TT>. In a list of 
   * length <TT>n</TT>, there are <TT>n+1</TT> valid 
   * index values, from <TT>0</TT> to <TT>n</TT>, inclusive. 
   * <PRE>
   *
   *          Element(0)   Element(1)   Element(2)   ... Element(n)   
   *        ^            ^            ^            ^               ^
   * Index: 0            1            2            3               n+1
   *
   * </PRE>
   * <P>
   * Note that the #remove and #setValue(Object) methods are
   * <i>not</i> defined in terms of the cursor position;  they are defined to
   * operate on the last element returned by a call to #next or @link
   * #previous().
   * <P>
   * 
   * @author sleistner
   */
  public interface ListIterator extends Iterator {
    
    function setIndex(index:int):void;
    
    /**
     * Returns <tt>true</tt> if this list iterator has more elements when
     * traversing the list in the reverse direction.  (In other words, returns
     * <tt>true</tt> if <tt>previous</tt> would return an element rather than
     * throwing an exception.)
     *
     * @return <tt>true</tt> if the list iterator has more elements when
     *	       traversing the list in the reverse direction.
     */
    function hasPrevious():Boolean;
    
    /**
     * Returns the previous element in the list.  This method may be called
     * repeatedly to iterate through the list backwards, or intermixed with
     * calls to <tt>next</tt> to go back and forth.  (Note that alternating
     * calls to <tt>next</tt> and <tt>previous</tt> will return the same
     * element repeatedly.)
     *
     * @return the previous element in the list.
     * 
     * @throws common.lang.NoSuchElementException if the iteration has no 
     * 			previous element.
     */
    function previous():*;
    
    /**
     * Returns the index of the element that would be returned by a subsequent
     * call to <tt>next</tt>. (Returns list size if the list iterator is at the
     * end of the list.)
     *
     * @return the index of the element that would be returned by a subsequent
     * 	       call to <tt>next</tt>, or list size if list iterator is at end
     *	       of list. 
     */
    function nextIndex():int;
    
    /**
     * Returns the index of the element that would be returned by a subsequent
     * call to <tt>previous</tt>. (Returns -1 if the list iterator is at the
     * beginning of the list.)
     *
     * @return the index of the element that would be returned by a subsequent
     * 	       call to <tt>previous</tt>, or -1 if list iterator is at
     *	       beginning of list.
     */ 
    function previousIndex():int;
    
    /**
     * Replaces the last element returned by <tt>next</tt> or
     * <tt>previous</tt> with the specified element(optional operation).
     * This call can be made only if neither <tt>ListIterator.remove</tt> nor
     * <tt>ListIterator.add</tt> have been called after the last call to
     * <tt>next</tt> or <tt>previous</tt>.
     *
     * @param object the element with which to replace the last element returned by
     *          <tt>next</tt> or <tt>previous</tt>.
     * @exception common.lang.UnsupportedOperationException if the <tt>setAt</tt> operation
     * 		  is not supported by this list iterator.
     * @exception common.lang.IllegalArgumentException if some aspect of the specified
     *		  element prevents it from being added to this list.
     * @exception common.lang.IllegalStateException if neither <tt>next</tt> nor
     *	          <tt>previous</tt> have been called, or <tt>remove</tt> or
     *		  <tt>add</tt> have been called after the last call to
     * 		  <tt>next</tt> or <tt>previous</tt>.
     */
    function setValue(object:*):void;
    
    /**
     * Inserts the specified element into the list(optional operation).  The
     * element is inserted immediately before the next element that would be
     * returned by <tt>next</tt>, if any, and after the next element that
     * would be returned by <tt>previous</tt>, if any.  (If the list contains
     * no elements, the new element becomes the sole element on the list.)
     * The new element is inserted before the implicit cursor: a subsequent
     * call to <tt>next</tt> would be unaffected, and a subsequent call to
     * <tt>previous</tt> would return the new element.  (This call increases
     * by one the value that would be returned by a call to <tt>nextIndex</tt>
     * or <tt>previousIndex</tt>.)
     *
     * @param object the element to insert.
     * @exception common.lang.UnsupportedOperationException if the <tt>add</tt> method is
     * 		  not supported by this list iterator.
     * 
     * @exception common.lang.IllegalArgumentException if some aspect of this element
     *            prevents it from being added to this list.
     */
    function add(object:*):void;
  }
}