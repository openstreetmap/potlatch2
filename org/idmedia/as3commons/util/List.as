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
  
  /**
   * An ordered collection (also known as a <i>sequence</i>).  The user of this
   * interface has precise control over where in the list each element is
   * inserted.  The user can access elements by their integer index (position in
   * the list), and search for elements in the list.<p>
   *
   * Unlike sets, lists typically allow duplicate elements.  More formally,
   * lists typically allow pairs of elements <tt>e1</tt> and <tt>e2</tt>
   * such that <tt>e1.equals(e2)</tt>, and they typically allow multiple
   * null elements if they allow null elements at all.  It is not inconceivable
   * that someone might wish to implement a list that prohibits duplicates, by
   * throwing runtime exceptions when the user attempts to insert them, but we
   * expect this usage to be rare.<p>
   *
   * The <tt>List</tt> interface places additional stipulations, beyond those
   * specified in the <tt>Collection</tt> interface, on the contracts of the
   * <tt>iterator</tt>, <tt>add</tt>, <tt>remove</tt>, <tt>equals</tt>
   * methods.  Declarations for other inherited methods are
   * also included here for convenience.<p>
   *
   * The <tt>List</tt> interface provides four methods for positional (indexed)
   * access to list elements.  Lists (like arrays) are zero based.  Note
   * that these operations may execute in time proportional to the index value
   * for some implementations (the <tt>LinkedList</tt> class, for
   * example). Thus, iterating over the elements in a list is typically
   * preferable to indexing through it if the caller does not know the
   * implementation.<p>
   *
   * The <tt>List</tt> interface provides a special iterator, called a
   * <tt>ListIterator</tt>, that allows element insertion and replacement, and
   * bidirectional access in addition to the normal operations that the
   * <tt>Iterator</tt> interface provides.  A method is provided to obtain a
   * list iterator that starts at a specified position in the list.<p>
   *
   * The <tt>List</tt> interface provides two methods to search for a specified
   * object. From a performance standpoint, these methods should be used with
   * caution. In many implementations they will perform costly linear
   * searches.<p>
   *
   * The <tt>List</tt> interface provides two methods to efficiently insert and
   * remove multiple elements at an arbitrary point in the list.<p>
   *
   * <p>Some list implementations have restrictions on the elements that
   * they may contain.  For example, some implementations prohibit null elements,
   * and some have restrictions on the types of their elements.  Attempting to
   * add an ineligible element throws an unchecked exception, typically
   * <tt>NullPointerException</tt>.  Attempting
   * to query the presence of an ineligible element may throw an exception,
   * or it may simply return false; some implementations will exhibit the former
   * behavior and some will exhibit the latter.  More generally, attempting an
   * operation on an ineligible element whose completion would not result in
   * the insertion of an ineligible element into the list may throw an
   * exception or it may succeed, at the option of the implementation.
   * Such exceptions are marked as "optional" in the specification for this
   * interface.
   * 
   * @author sleistner
   */
  public interface List extends Collection {
    
    /**
     * Inserts the specified element at the specified position in this list
     *(optional operation).  Shifts the element currently at that position
     *(if any) and any subsequent elements to the right (adds one to their
     * indices).
     *
     * @param index index at which the specified element is to be inserted.
     * @param value element to be inserted.
     * 
     * @throws UnsupportedOperationException if the <tt>add</tt> method is not
     *		  supported by this list.
     * @throws    NullPointerException if the specified element is null and
     *            this list does not support null elements.
     * @throws    IllegalArgumentException if some aspect of the specified
     *		  element prevents it from being added to this list.
     * @throws    IndexOutOfBoundsException if the index is out of range
     *(index &lt; 0 || index &gt; size()).
     */
    function addAt(index:int, value:*):Boolean;
    
    /**
     * Replaces the element at the specified position in this list with the
     * specified element(optional operation).
     *
     * @param index index of element to replace.
     * @param value element to be stored at the specified position.
     * @return the element previously at the specified position.
     * 
     * @throws UnsupportedOperationException if the <tt>set</tt> method is not
     *		  supported by this list.
     * @throws    NullPointerException if the specified element is null and
     *            this list does not support null elements.
     * @throws    IllegalArgumentException if some aspect of the specified
     *		  element prevents it from being added to this list.
     * @throws    IndexOutOfBoundsException if the index is out of range
     *(index &lt; 0 || index &gt;= size()).
     */
    function setAt(index:int, value:*):Boolean;
    
    /**
     * Returns the element at the specified position in this list.
     *
     * @param index index of element to return.
     * @return the element at the specified position in this list.
     * 
     * @throws IndexOutOfBoundsException if the index is out of range (index
     * 		  &lt; 0 || index &gt;= size()).
     */
    function get(index:int):*;
    
    /**
     * Returns a list iterator of the elements in this list (in proper
     * sequence).
     *
     * @return a list iterator of the elements in this list (in proper
     * 	       sequence).
     */
    function listIterator():ListIterator;
    
    /**
     * Returns a list iterator of the elements in this list (in proper
     * sequence), starting at the specified position in this list.  The
     * specified index indicates the first element that would be returned by
     * an initial call to the <tt>next</tt> method.  An initial call to
     * the <tt>previous</tt> method would return the element with the
     * specified index minus one.
     *
     * @param index index of first element to be returned from the
     *		    list iterator (by a call to the <tt>next</tt> method).
     * @return a list iterator of the elements in this list (in proper
     * 	       sequence), starting at the specified position in this list.
     * @throws IndexOutOfBoundsException if the index is out of range (index
     *         &lt; 0 || index &gt; size()).
     */
    function indexedListIterator(index:uint):ListIterator;
    
    /**
     * Removes the element at the specified position in this list (optional
     * operation).  Shifts any subsequent elements to the left (subtracts one
     * from their indices).  Returns the element that was removed from the
     * list.
     *
     * @param index the index of the element to removed.
     * @return the element previously at the specified position.
     * 
     * @throws UnsupportedOperationException if the <tt>remove</tt> method is
     *		  not supported by this list.
     * @throws IndexOutOfBoundsException if the index is out of range (index
     *            &lt; 0 || index &gt;= size()).
     */
    function removeAt(index:int):Boolean;
    
    function removeAtAndReturn(index:int):*;
    
    function removeAtTo(index:int, to:int):Boolean;
    
    /**
     * Returns the index in this list of the first occurrence of the specified
     * element, or -1 if this list does not contain this element.
     * More formally, returns the lowest index <tt>i</tt> such that
     * <tt>(elem==null ? get(i)==null : elem.equals(get(i)))</tt>,
     * or -1 if there is no such index.
     *
     * @param elem element to search for.
     * @return the index in this list of the first occurrence of the specified
     * 	       element, or -1 if this list does not contain this element.
     * @throws NullPointerException if the specified element is null and this
     *         list does not support null elements(optional).
     */
    function indexOf(elem:* = null):int;
  }
}