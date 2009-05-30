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
   * This class consists exclusively of static methods that operate on or return
   * collections.  It contains polymorphic algorithms that operate on
   * collections, "wrappers", which return a new collection backed by a
   * specified collection, and a few other odds and ends.
   *
   * <p>The methods of this class all throw a <tt>NullPointerException</tt>
   * if the collections or class objects provided to them are null.
   *
   * @author sleistner
   */
  public class Collections {
    
    function Collections() {
    }
    
    /**
     * Sorts the specified list according to the order induced by the
     * specified comparator.  All elements in the list must be <i>mutually
     * comparable</i> using the specified comparator (that is,
     * <tt>c.compare(e1, e2)</tt> must not throw a <tt>ClassCastException</tt>
     * for any elements <tt>e1</tt> and <tt>e2</tt> in the list).<p>
     *
     * This sort is guaranteed to be <i>stable</i>:  equal elements will
     * not be reordered as a result of the sort.<p>
     *
     * The sorting algorithm is a modified mergesort (in which the merge is
     * omitted if the highest element in the low sublist is less than the
     * lowest element in the high sublist).  This algorithm offers guaranteed
     * n log(n) performance. 
     *
     * The specified list must be modifiable, but need not be resizable.
     * This implementation dumps the specified list into an array, sorts
     * the array, and iterates over the list resetting each element
     * from the corresponding position in the array.  This avoids the
     * n<sup>2</sup> log(n) performance that would result from attempting
     * to sort a linked list in place.
     *
     * @param  list the list to be sorted.
     * @param  c the comparator to determine the order of the list.  A
     *        <tt>null</tt> value indicates that the elements' <i>natural
     *        ordering</i> should be used.
     * @throws UnsupportedOperationException if the specified list's
     *	       list-iterator does not support the <tt>set</tt> operation.
     * @see org.idmedia.as3commons.util.Comparator
     */
    public static function sort(list:List, c:Comparator):void {
      var a:Array = list.toArray();
      Arrays.sort(a, c);
      var i:ListIterator = list.listIterator();
      for(var j:uint = 0;j < a.length; j++) {
        i.next();
        i.setValue(a[j]);
      }
    }
  }
}