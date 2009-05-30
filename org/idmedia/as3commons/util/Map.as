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
   * An object that maps keys to values.  A map cannot contain duplicate keys;
   * each key can map to at most one value.
   *
   * <p>The <tt>Map</tt> interface provides three <i>collection views</i>, which
   * allow a map's contents to be viewed as a set of keys, collection of values,
   * or set of key-value mappings.  The <i>order</i> of a map is defined as
   * the order in which the iterators on the map's collection views return their
   * elements.  Some map implementations, like the <tt>TreeMap</tt> class, make
   * specific guarantees as to their order; others, like the <tt>HashMap</tt>
   * class, do not.
   *
   * <p>Note: great care must be exercised if mutable objects are used as map
   * keys.  The behavior of a map is not specified if the value of an object is
   * changed in a manner that affects equals comparisons while the object is a
   * key in the map.  A special case of this prohibition is that it is not
   * permissible for a map to contain itself as a key.  While it is permissible
   * for a map to contain itself as a value, extreme caution is advised: the
   * equals and hashCode methods are no longer well defined on a such a map.
   *
   * <p>The "destructive" methods contained in this interface, that is, the
   * methods that modify the map on which they operate, are specified to throw
   * <tt>UnsupportedOperationException</tt> if this map does not support the
   * operation.  If this is the case, these methods may, but are not required
   * to, throw an <tt>UnsupportedOperationException</tt> if the invocation would
   * have no effect on the map.  For example, invoking the #putAll(Map)
   * method on an unmodifiable map may, but is not required to, throw the
   * exception if the map whose mappings are to be "superimposed" is empty.
   *
   * <p>Some map implementations have restrictions on the keys and values they
   * may contain.  For example, some implementations prohibit null keys and
   * values, and some have restrictions on the types of their keys.  Attempting
   * to insert an ineligible key or value throws an unchecked exception,
   * typically <tt>NullPointerException</tt> or <tt>ClassCastException</tt>.
   * Attempting to query the presence of an ineligible key or value may throw an
   * exception, or it may simply return false; some implementations will exhibit
   * the former behavior and some will exhibit the latter.  More generally,
   * attempting an operation on an ineligible key or value whose completion
   * would not result in the insertion of an ineligible element into the map may
   * throw an exception or it may succeed, at the option of the implementation.
   * Such exceptions are marked as "optional" in the specification for this
   * interface.
   *
   * @author sleistner
   * @see HashMap
   * @see Collection
   * @see Set
   */
  public interface Map {
    
    /**
     * Associates the specified value with the specified key in this map
     * (optional operation).  If the map previously contained a mapping for
     * this key, the old value is replaced by the specified value.  (A map
     * <tt>m</tt> is said to contain a mapping for a key <tt>k</tt> if and only
     * if #containsKey(Object) m.containsKey(k) would return
     * <tt>true</tt>.)) 
     *
     * @param key key with which the specified value is to be associated.
     * @param value value to be associated with the specified key.
     * @return previous value associated with specified key, or <tt>null</tt>
     *	       if there was no mapping for key.  A <tt>null</tt> return can
     *	       also indicate that the map previously associated <tt>null</tt>
     *	       with the specified key, if the implementation supports
     *	       <tt>null</tt> values.
     * 
     * @throws UnsupportedOperationException if the <tt>put</tt> operation is
     *	          not supported by this map.
     *	          
     * @throws IllegalArgumentException if some aspect of this key or value
     *	          prevents it from being stored in this map.
     * @throws NullPointerException if this map does not permit <tt>null</tt>
     *            keys or values, and the specified key or value is
     *            <tt>null</tt>.
     */
    function put(key:*, value:*):*;
    
    /**
     * Returns the value to which this map maps the specified key.  Returns
     * <tt>null</tt> if the map contains no mapping for this key.  A return
     * value of <tt>null</tt> does not <i>necessarily</i> indicate that the
     * map contains no mapping for the key; it's also possible that the map
     * explicitly maps the key to <tt>null</tt>.  The <tt>containsKey</tt>
     * operation may be used to distinguish these two cases.
     *
     * @param key key whose associated value is to be returned.
     * @return the value to which this map maps the specified key, or
     *	       <tt>null</tt> if the map contains no mapping for this key.
     * 
     * @throws NullPointerException if the key is <tt>null</tt> and this map
     *		  does not permit <tt>null</tt> keys (optional).
     * 
     * @see #containsKey()
     */
    function get(key:*):*;
    
    /**
     * Returns <tt>true</tt> if this map contains a mapping for the specified
     * key.  More formally, returns <tt>true</tt> if and only if
     * this map contains a mapping for a key <tt>k</tt> such that
     * <tt>(key==null ? k==null : key.equals(k))</tt>.  (There can be
     * at most one such mapping.)
     *
     * @param key key whose presence in this map is to be tested.
     * @return <tt>true</tt> if this map contains a mapping for the specified
     *         key.
     * 
     * @throws NullPointerException if the key is <tt>null</tt> and this map
     *            does not permit <tt>null</tt> keys (optional).
     */
    function containsKey(key:*):Boolean;
    
    /**
     * Returns <tt>true</tt> if this map maps one or more keys to the
     * specified value.  More formally, returns <tt>true</tt> if and only if
     * this map contains at least one mapping to a value <tt>v</tt> such that
     * <tt>(value==null ? v==null : value.equals(v))</tt>.  This operation
     * will probably require time linear in the map size for most
     * implementations of the <tt>Map</tt> interface.
     *
     * @param value value whose presence in this map is to be tested.
     * @return <tt>true</tt> if this map maps one or more keys to the
     *         specified value.
     *         
     * @throws NullPointerException if the value is <tt>null</tt> and this map
     *            does not permit <tt>null</tt> values (optional).
     */
    function containsValue(value:*):Boolean;
    
    /**
     * Removes the mapping for this key from this map if it is present
     * (optional operation).   More formally, if this map contains a mapping
     * from key <tt>k</tt> to value <tt>v</tt> such that
     * <code>(key==null ?  k==null : key.equals(k))</code>, that mapping
     * is removed.  (The map can contain at most one such mapping.)
     *
     * <p>Returns the value to which the map previously associated the key, or
     * <tt>null</tt> if the map contained no mapping for this key.  (A
     * <tt>null</tt> return can also indicate that the map previously
     * associated <tt>null</tt> with the specified key if the implementation
     * supports <tt>null</tt> values.)  The map will not contain a mapping for
     * the specified  key once the call returns.
     *
     * @param key key whose mapping is to be removed from the map.
     * @return previous value associated with specified key, or <tt>null</tt>
     *	       if there was no mapping for key.
     *
     * @throws NullPointerException if the key is <tt>null</tt> and this map
     *            does not permit <tt>null</tt> keys (optional).
     * @throws UnsupportedOperationException if the <tt>remove</tt> method is
     *         not supported by this map.
     */
    function remove(key:*):*;
    
    /**
     * Removes all mappings from this map (optional operation).
     *
     * @throws UnsupportedOperationException clear is not supported by this
     * 		  map.
     */	
    function clear():void;
    
    /**
     * Returns the number of key-value mappings in this map.  If the
     * map contains more than <tt>Number.MAX_VALUE</tt> elements, returns
     * <tt>Number.MAX_VALUE</tt>.
     *
     * @return the number of key-value mappings in this map.
     */
    function size():int;
    
    /**
     * Returns a collection view of the values contained in this map.  The
     * collection is backed by the map, so changes to the map are reflected in
     * the collection, and vice-versa.  If the map is modified while an
     * iteration over the collection is in progress (except through the
     * iterator's own <tt>remove</tt> operation), the results of the
     * iteration are undefined.  The collection supports element removal,
     * which removes the corresponding mapping from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Collection.remove</tt>,
     * <tt>removeAll</tt>, <tt>retainAll</tt> and <tt>clear</tt> operations.
     * It does not support the add or <tt>addAll</tt> operations.
     *
     * @return a collection view of the values contained in this map.
     */
    function values():Collection;
    
    /**
     * Returns a set view of the keys contained in this map.  The set is
     * backed by the map, so changes to the map are reflected in the set, and
     * vice-versa.  If the map is modified while an iteration over the set is
     * in progress (except through the iterator's own <tt>remove</tt>
     * operation), the results of the iteration are undefined.  The set
     * supports element removal, which removes the corresponding mapping from
     * the map, via the <tt>Iterator.remove</tt>, <tt>Set.remove</tt>,
     * <tt>removeAll</tt> <tt>retainAll</tt>, and <tt>clear</tt> operations.
     * It does not support the add or <tt>addAll</tt> operations.
     *
     * @return a set view of the keys contained in this map.
     */
    function keySet():Set;
    
    /**
     * Returns a set view of the mappings contained in this map.  Each element
     * in the returned set is a {@link Map.Entry}.  The set is backed by the
     * map, so changes to the map are reflected in the set, and vice-versa.
     * If the map is modified while an iteration over the set is in progress
     * (except through the iterator's own <tt>remove</tt> operation, or through
     * the <tt>setValue</tt> operation on a map entry returned by the iterator)
     * the results of the iteration are undefined.  The set supports element
     * removal, which removes the corresponding mapping from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Set.remove</tt>, <tt>removeAll</tt>,
     * <tt>retainAll</tt> and <tt>clear</tt> operations.  It does not support
     * the <tt>add</tt> or <tt>addAll</tt> operations.
     *
     * @return a set view of the mappings contained in this map.
     */
    function entrySet():Set;
    
    /**
     * Returns <tt>true</tt> if this map contains no key-value mappings.
     *
     * @return <tt>true</tt> if this map contains no key-value mappings.
     */
    function isEmpty():Boolean;
    
    // bulk operations

    /**
     * Copies all of the mappings from the specified map to this map
     * (optional operation).  The effect of this call is equivalent to that
     * of calling {@link #put(Object,Object) put(k, v)} on this map once
     * for each mapping from key <tt>k</tt> to value <tt>v</tt> in the 
     * specified map.  The behavior of this operation is unspecified if the
     * specified map is modified while the operation is in progress.
     *
     * @param map Mappings to be stored in this map.
     * 
     * @throws UnsupportedOperationException if the <tt>putAll</tt> method is
     * 		  not supported by this map.
     * 
     * @throws IllegalArgumentException some aspect of a key or value in the
     *	          specified map prevents it from being stored in this map.
     * @throws NullPointerException if the specified map is <tt>null</tt>, or if
     *         this map does not permit <tt>null</tt> keys or values, and the
     *         specified map contains <tt>null</tt> keys or values.
     */
    function putAll(map:Map):void;
  }
}