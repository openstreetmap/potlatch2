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
  import org.idmedia.as3commons.lang.UnsupportedOperationException;
  
  /**
   * This class provides a skeletal implementation of the <tt>Map</tt>
   * interface, to minimize the effort required to implement this interface. <p>
   *
   * To implement an unmodifiable map, the programmer needs only to extend this
   * class and provide an implementation for the <tt>entrySet</tt> method, which
   * returns a set-view of the map's mappings.  Typically, the returned set
   * will, in turn, be implemented atop <tt>AbstractSet</tt>.  This set should
   * not support the <tt>add</tt> or <tt>remove</tt> methods, and its iterator
   * should not support the <tt>remove</tt> method.<p>
   *
   * To implement a modifiable map, the programmer must additionally override
   * this class's <tt>put</tt> method (which otherwise throws an
   * <tt>UnsupportedOperationException</tt>), and the iterator returned by
   * <tt>entrySet().iterator()</tt> must additionally implement its
   * <tt>remove</tt> method.<p>
   *
   * The programmer should generally provide a void (no argument) and map
   * constructor, as per the recommendation in the <tt>Map</tt> interface
   * specification.<p>
   *
   * The documentation for each non-abstract methods in this class describes its
   * implementation in detail.  Each of these methods may be overridden if the
   * map being implemented admits a more efficient implementation.<p>
   * 
   * @author sleistner
   */
  public class AbstractMap implements Map {
    
    /**
     * Associates the specified value with the specified key in this map
     * (optional operation).  If the map previously contained a mapping for
     * this key, the old value is replaced.<p>
     *
     * This implementation always throws an
     * <tt>UnsupportedOperationException</tt>.
     *
     * @param key key with which the specified value is to be associated.
     * @param value value to be associated with the specified key.
     * 
     * @return previous value associated with specified key, or <tt>null</tt>
     *	       if there was no mapping for key.  (A <tt>null</tt> return can
     *	       also indicate that the map previously associated <tt>null</tt>
     *	       with the specified key, if the implementation supports
     *	       <tt>null</tt> values.)
     * 
     * @throws UnsupportedOperationException if the <tt>put</tt> operation is
     *	          not supported by this map.
     * 
     * @throws IllegalArgumentException if some aspect of this key or value *
     *            prevents it from being stored in this map.
     * 
     * @throws NullPointerException if this map does not permit <tt>null</tt>
     *            keys or values, and the specified key or value is
     *            <tt>null</tt>.
     */
    public function put(key:*, value:*):* {
      throw new UnsupportedOperationException();
    }
    
    /**
     * Returns the value to which this map maps the specified key.  Returns
     * <tt>null</tt> if the map contains no mapping for this key.  A return
     * value of <tt>null</tt> does not <i>necessarily</i> indicate that the
     * map contains no mapping for the key; it's also possible that the map
     * explicitly maps the key to <tt>null</tt>.  The containsKey operation
     * may be used to distinguish these two cases. <p>
     *
     * This implementation iterates over <tt>entrySet()</tt> searching for an
     * entry with the specified key.  If such an entry is found, the entry's
     * value is returned.  If the iteration terminates without finding such an
     * entry, <tt>null</tt> is returned.  Note that this implementation
     * requires linear time in the size of the map; many implementations will
     * override this method.
     *
     * @param key key whose associated value is to be returned.
     * @return the value to which this map maps the specified key.
     * 
     * @throws NullPointerException if the key is <tt>null</tt> and this map
     *		  does not permit <tt>null</tt> keys.
     * 
     * @see #containsKey(*)
     */
    public function get(key:*):* {
      
      if(key === undefined)
      	return null;
      
      var k:* = key; //|| null;
      var i:Iterator = entrySet().iterator();
      while(i.hasNext()) {
        var e:Entry = i.next() as Entry;
        if(k === e.getKey()) {
          return e.getValue();
        }
      }
      return null;
    }
    
    /**
     * Returns <tt>true</tt> if this map contains a mapping for the specified
     * key. <p>
     *
     * This implementation iterates over <tt>entrySet()</tt> searching for an
     * entry with the specified key.  If such an entry is found, <tt>true</tt>
     * is returned.  If the iteration terminates without finding such an
     * entry, <tt>false</tt> is returned.  Note that this implementation
     * requires linear time in the size of the map; many implementations will
     * override this method.
     *
     * @param key key whose presence in this map is to be tested.
     * @return <tt>true</tt> if this map contains a mapping for the specified
     *            key.
     * 
     * @throws NullPointerException if the key is <tt>null</tt> and this map
     *            does not permit <tt>null</tt> keys.
     */
    public function containsKey(key:*):Boolean {
      var k:* = key || null;
      var i:Iterator = entrySet().iterator();
      while(i.hasNext()) {
        var e:Entry = i.next() as Entry;
        if(k === e.getKey()) {
          return true;
        }
      }
      return false;
    }
    
    /**
     * Returns <tt>true</tt> if this map maps one or more keys to this value.
     * More formally, returns <tt>true</tt> if and only if this map contains
     * at least one mapping to a value <tt>v</tt> such that <tt>(value==null ?
     * v==null : value.equals(v))</tt>.  This operation will probably require
     * time linear in the map size for most implementations of map.<p>
     *
     * This implementation iterates over entrySet() searching for an entry
     * with the specified value.  If such an entry is found, <tt>true</tt> is
     * returned.  If the iteration terminates without finding such an entry,
     * <tt>false</tt> is returned.  Note that this implementation requires
     * linear time in the size of the map.
     *
     * @param value value whose presence in this map is to be tested.
     * 
     * @return <tt>true</tt> if this map maps one or more keys to this value.
     */
    public function containsValue(value:*):Boolean {
      var v:* = value || null;
      var i:Iterator = entrySet().iterator();
      while(i.hasNext()) {
        var e:Entry = i.next() as Entry;
        if(v === e.getValue()) {
          return true;
        }
      }
      return false;
    }
    
    /**
     * Removes the mapping for this key from this map if present (optional
     * operation). <p>
     *
     * This implementation iterates over <tt>entrySet()</tt> searching for an
     * entry with the specified key.  If such an entry is found, its value is
     * obtained with its <tt>getValue</tt> operation, the entry is removed
     * from the Collection (and the backing map) with the iterator's
     * <tt>remove</tt> operation, and the saved value is returned.  If the
     * iteration terminates without finding such an entry, <tt>null</tt> is
     * returned.  Note that this implementation requires linear time in the
     * size of the map; many implementations will override this method.<p>
     *
     * Note that this implementation throws an
     * <tt>UnsupportedOperationException</tt> if the <tt>entrySet</tt> iterator
     * does not support the <tt>remove</tt> method and this map contains a
     * mapping for the specified key.
     *
     * @param key key whose mapping is to be removed from the map.
     * @return previous value associated with specified key, or <tt>null</tt>
     *	       if there was no entry for key.  (A <tt>null</tt> return can
     *	       also indicate that the map previously associated <tt>null</tt>
     *	       with the specified key, if the implementation supports
     *	       <tt>null</tt> values.)
     * @throws UnsupportedOperationException if the <tt>remove</tt> operation
     * 		  is not supported by this map.
     */
    public function remove(key:*):* {
      var k:* = key || null;
      var i:Iterator = entrySet().iterator();
      var correctEntry:Entry = null;

      while(correctEntry == null && i.hasNext()) {
        var e:Entry = Entry(i.next());
        if(key === e.getKey()) {
          correctEntry = e;
        }
      }

      var oldValue:* = null;
      if(correctEntry != null) {
        oldValue = correctEntry.getValue();
        i.remove();
      }

      return oldValue;
    }
    
    /**
     * Removes all mappings from this map (optional operation). <p>
     *
     * This implementation calls <tt>entrySet().clear()</tt>.
     *
     * Note that this implementation throws an
     * <tt>UnsupportedOperationException</tt> if the <tt>entrySet</tt>
     * does not support the <tt>clear</tt> operation.
     *
     * @throws    UnsupportedOperationException clear is not supported
     * 		  by this map.
     */
    public function clear():void {
      entrySet().clear();
    }
    
    /**
     * Returns the number of key-value mappings in this map.  If the map
     * contains more than <tt>Number.MAX_VALUE</tt> elements, returns
     * <tt>Number.MAX_VALUE</tt>.<p>
     *
     * This implementation returns <tt>entrySet().size()</tt>.
     *
     * @return the number of key-value mappings in this map.
     */
    public function size():int {
      return entrySet().size();
    }
    
    private var v:Collection = null;
    
    /**
     * Returns a collection view of the values contained in this map.  The
     * collection is backed by the map, so changes to the map are reflected in
     * the collection, and vice-versa.  (If the map is modified while an
     * iteration over the collection is in progress, the results of the
     * iteration are undefined.)  The collection supports element removal,
     * which removes the corresponding entry from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Collection.remove</tt>,
     * <tt>removeAll</tt>, <tt>retainAll</tt> and <tt>clear</tt> operations.
     * It does not support the <tt>add</tt> or <tt>addAll</tt> operations.<p>
     *
     * This implementation returns a collection that subclasses abstract
     * collection.  The subclass's iterator method returns a "wrapper object"
     * over this map's <tt>entrySet()</tt> iterator.  The size method
     * delegates to this map's size method and the contains method delegates
     * to this map's containsValue method.<p>
     *
     * The collection is created the first time this method is called, and
     * returned in response to all subsequent calls.  No synchronization is
     * performed, so there is a slight chance that multiple calls to this
     * method will not all return the same Collection.
     *
     * @return a collection view of the values contained in this map.
     */    
    public function values():Collection {
      if(v == null) {
        v = new CollectionImpl(this);
      }
      return v;
    }
    
    private var k:Set = null;
    
    /**
     * Returns a Set view of the keys contained in this map.  The Set is
     * backed by the map, so changes to the map are reflected in the Set,
     * and vice-versa.  (If the map is modified while an iteration over
     * the Set is in progress, the results of the iteration are undefined.)
     * The Set supports element removal, which removes the corresponding entry
     * from the map, via the Iterator.remove, Set.remove,  removeAll
     * retainAll, and clear operations.  It does not support the add or
     * addAll operations.<p>
     *
     * This implementation returns a Set that subclasses
     * AbstractSet.  The subclass's iterator method returns a "wrapper
     * object" over this map's entrySet() iterator.  The size method delegates
     * to this map's size method and the contains method delegates to this
     * map's containsKey method.<p>
     *
     * The Set is created the first time this method is called,
     * and returned in response to all subsequent calls.  No synchronization
     * is performed, so there is a slight chance that multiple calls to this
     * method will not all return the same Set.
     *
     * @return a Set view of the keys contained in this map.
     */
    public function keySet():Set {
      if(k == null ) {
        k = new AbstractEntrySet(this);
      }
      return k;
    }
    
    /**
     * Returns a set view of the mappings contained in this map.  Each element
     * in this set is a Map.Entry.  The set is backed by the map, so changes
     * to the map are reflected in the set, and vice-versa.  (If the map is
     * modified while an iteration over the set is in progress, the results of
     * the iteration are undefined.)  The set supports element removal, which
     * removes the corresponding entry from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Set.remove</tt>, <tt>removeAll</tt>,
     * <tt>retainAll</tt> and <tt>clear</tt> operations.  It does not support
     * the <tt>add</tt> or <tt>addAll</tt> operations.
     *
     * @return a set view of the mappings contained in this map.
     */
    public function entrySet():Set {
      throw new UnsupportedOperationException();
    }
    
    /**
     * Returns <tt>true</tt> if this map contains no key-value mappings. <p>
     *
     * This implementation returns <tt>size() == 0</tt>.
     *
     * @return <tt>true</tt> if this map contains no key-value mappings.
     */
    public function isEmpty():Boolean {
      return size() == 0;
    }
    
    /**
     * Copies all of the mappings from the specified map to this map
     * (optional operation).  These mappings will replace any mappings that
     * this map had for any of the keys currently in the specified map.<p>
     *
     * This implementation iterates over the specified map's
     * <tt>entrySet()</tt> collection, and calls this map's <tt>put</tt>
     * operation once for each entry returned by the iteration.<p>
     *
     * Note that this implementation throws an
     * <tt>UnsupportedOperationException</tt> if this map does not support
     * the <tt>put</tt> operation and the specified map is nonempty.
     *
     * @param t mappings to be stored in this map.
     * 
     * @throws UnsupportedOperationException if the <tt>putAll</tt> operation
     * 		  is not supported by this map.
     * 
     * @throws IllegalArgumentException if some aspect of a key or value in
     *	          the specified map prevents it from being stored in this map.
     * @throws NullPointerException if the specified map is <tt>null</tt>, or if
     *         this map does not permit <tt>null</tt> keys or values, and the
     *         specified map contains <tt>null</tt> keys or values.
     */
    public function putAll(map:Map):void {
      var i:Iterator = map.entrySet().iterator();
      while(i.hasNext()) {
        var e:Entry = i.next() as Entry;
        put(e.getKey(), e.getValue());
      }
    }
    
    public function equals(object:*):Boolean {
      return object === this;
    }
  }	
}

import org.idmedia.as3commons.util.AbstractCollection;
import org.idmedia.as3commons.util.AbstractSet;
import org.idmedia.as3commons.util.Entry;
import org.idmedia.as3commons.util.Iterator;
import org.idmedia.as3commons.util.Map;

internal class AbstractEntrySet extends AbstractSet {
  
  private var m:Map = null;
  
  function AbstractEntrySet(m:Map) {
    this.m = m;
  }
  
  override public function iterator():Iterator {
    return new KeyIterator(m.entrySet().iterator());
  }
  
  override public function size():int {
    return m.size();
  }
  
  override public function contains(value:*):Boolean {
    return m.containsKey(value);	
  }
}

internal final class CollectionImpl extends AbstractCollection {
  
  private var map:Map;
  
  function CollectionImpl(map:Map) {
    this.map = map;
  }
  
  override public function iterator():Iterator {
    return new ValueIterator(map.entrySet().iterator());
  }
  
  override public function size():int { 
    return map.size();
  }
}

internal class KeyIterator implements Iterator {
  
  protected var iter:Iterator;
  
  function KeyIterator(iter:Iterator) {
    this.iter = iter;
  }
  
  public function hasNext():Boolean {
    return iter.hasNext();
  }
  
  public function next():* {
    return Entry(iter.next()).getKey();
  }
  
  public function remove():void {
    iter.remove();
  }
}

internal final class ValueIterator extends KeyIterator {
  
  function ValueIterator(iter:Iterator) {
    super(iter);
  }
  
  override public function next():* {
    return Entry(iter.next()).getValue();
  }
}