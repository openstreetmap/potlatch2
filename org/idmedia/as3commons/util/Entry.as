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
  
  public interface Entry {
    
    /**
     * Returns the key corresponding to this entry.
     *
     * @return the key corresponding to this entry.
     * @throws IllegalStateException implementations may, but are not
     *         required to, throw this exception if the entry has been
     *         removed from the backing map
     */
    function getKey():*;
    
    /**
     * Returns the value corresponding to this entry.  If the mapping
     * has been removed from the backing map (by the iterator's
     * <tt>remove</tt> operation), the results of this call are undefined.
     *
     * @return the value corresponding to this entry.
     * @throws IllegalStateException implementations may, but are not
     *         required to, throw this exception if the entry has been
     *         removed from the backing map
     */
    function getValue():*;
    
    /**
     * Replaces the value corresponding to this entry with the specified
     * value (optional operation).  (Writes through to the map.)  The
     * behavior of this call is undefined if the mapping has already been
     * removed from the map (by the iterator's <tt>remove</tt> operation).
     *
     * @param value new value to be stored in this entry.
     * @return old value corresponding to the entry.
     * 
     * @throws UnsupportedOperationException if the <tt>put</tt> operation
     *	      is not supported by the backing map.
     * @throws IllegalArgumentException if some aspect of this value
     *	      prevents it from being stored in the backing map.
     * @throws NullPointerException if the backing map does not permit
     *	      <tt>null</tt> values, and the specified value is
     *	      <tt>null</tt>.
     * @throws IllegalStateException implementations may, but are not
     *         required to, throw this exception if the entry has been
     *         removed from the backing map
     */
    function setValue(value:*):*;
    
    /**
     * Compares the specified object with this entry for equality.
     * Returns <tt>true</tt> if the given object is also a map entry and
     * the two entries represent the same mapping.  More formally, two
     * entries <tt>e1</tt> and <tt>e2</tt> represent the same mapping
     * if<pre>
     *     (e1.getKey()==null ?
     *      e2.getKey()==null : e1.getKey().equals(e2.getKey()))  &&
     *     (e1.getValue()==null ?
     *      e2.getValue()==null : e1.getValue().equals(e2.getValue()))
     * </pre>
     * This ensures that the <tt>equals</tt> method works properly across
     * different implementations of the <tt>Map.Entry</tt> interface.
     *
     * @param o object to be compared for equality with this map entry.
     * @return <tt>true</tt> if the specified object is equal to this map
     *         entry.
     */
    function equals(o:*):Boolean;
  }
}