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
   * Hash table based implementation of the <tt>Map</tt> interface.  This
   * implementation provides all of the optional map operations, and permits
   * <tt>null</tt> values and the <tt>null</tt> key. 
   * This class makes no guarantees as to the order of the map; in particular, 
   * it does not guarantee that the order will remain constant over time.
   *
   * <p>This implementation provides constant-time performance for the basic
   * operations (<tt>get</tt> and <tt>put</tt>), assuming the hash function
   * disperses the elements properly among the buckets.  Iteration over
   * collection views requires time proportional to the "capacity" of the
   * <tt>HashMap</tt> instance (the number of buckets) plus its size (the number
   * of key-value mappings).
   *
   * <p>The iterators returned by all of this class's "collection view methods"
   * are <i>fail-fast</i>: if the map is structurally modified at any time after
   * the iterator is created, in any way except through the iterator's own
   * <tt>remove</tt> or <tt>add</tt> methods, the iterator will throw a
   * <tt>ConcurrentModificationException</tt>.  Thus, in the face of concurrent
   * modification, the iterator fails quickly and cleanly, rather than risking
   * arbitrary, non-deterministic behavior at an undetermined time in the
   * future.
   *
   * <p>Note that the fail-fast behavior of an iterator cannot be guaranteed
   * as it is, generally speaking, impossible to make any hard guarantees in the
   * presence of unsynchronized concurrent modification.  Fail-fast iterators
   * throw <tt>ConcurrentModificationException</tt> on a best-effort basis. 
   * Therefore, it would be wrong to write a program that depended on this
   * exception for its correctness: <i>the fail-fast behavior of iterators
   * should be used only to detect bugs.</i>
   * 
   * @author sleistner
   * @inheritDoc
   */
  public class HashMap extends AbstractMap implements Map {
    
    private var entries:Set;
    
    /**
     * Constructs an empty <tt>HashMap</tt>
     */
    function HashMap() {
      entries = new EntrySet();
    }
    
    /**
     * Returns a collection view of the mappings contained in this map.  Each
     * element in the returned collection is a <tt>Entry</tt>.  The
     * collection is backed by the map, so changes to the map are reflected in
     * the collection, and vice-versa.  The collection supports element
     * removal, which removes the corresponding mapping from the map, via the
     * <tt>Iterator.remove</tt>, <tt>Collection.remove</tt>,
     * <tt>removeAll</tt>, <tt>retainAll</tt>, and <tt>clear</tt> operations.
     * It does not support the <tt>add</tt> or <tt>addAll</tt> operations.
     *
     * @return a collection view of the mappings contained in this map.
     * @see Entry Entry
     */
    override public function entrySet():Set {
      return entries;	
    }
    
    /**
     * Associates the specified value with the specified key in this map.
     * If the map previously contained a mapping for this key, the old
     * value is replaced.
     *
     * @param key key with which the specified value is to be associated.
     * @param value value to be associated with the specified key.
     * @return previous value associated with specified key, or <tt>null</tt>
     *	       if there was no mapping for key.  A <tt>null</tt> return can
     *	       also indicate that the HashMap previously associated
     *	       <tt>null</tt> with the specified key.
     */
    override public function put(key:*, value:*):* {
      //if(key == null) {
        //throw new NullPointerException();
      //}

      var iter:Iterator = entries.iterator();
      while(iter.hasNext()) {
        var e:Entry = Entry(iter.next());
        if(e.getKey() === key) {
          var oldValue:* = e.getValue();
          e.setValue(value);
          return oldValue;	
        }	
      }
      entries.add(new EntryImpl(key, value));
      return null;
    }
    
    /**
     * This method was added by Derek Wischusen on 10/15/2007.
     * 
     * Iterates throughs the hash and passes each key value pair 
     * to the function that is passed in as parameter.
     * 
     * @param block a function that the following signature:
     *              function(key : Object, value : object){}
     * 
     */    
    public function forEach (block : Function) : void
    {
		var keys : Array = this.keySet().toArray();				
		for each (var key : Object in keys)
		{
			block(key, this.get(key))
		}    	
    }
  }
}

import org.idmedia.as3commons.lang.IllegalArgumentException;
import org.idmedia.as3commons.lang.IllegalStateException;
import org.idmedia.as3commons.lang.NoSuchElementException;
import org.idmedia.as3commons.util.AbstractSet;
import org.idmedia.as3commons.util.Entry;
import org.idmedia.as3commons.util.Iterator;

internal class EntryImpl implements Entry {
  
  private var key:*;
  private var value:*;
  
  function EntryImpl(key:*, value:*) {
    this.key = key;
    this.value = value;
  }
  
  public function getKey():* {
    return key;
  }
  
  public function getValue():* {
    return value;
  }
  
  public function setValue(newValue:*):* {
    var oldValue:* = value;
    value = newValue;
    return oldValue;
  }
  
  public function equals(o:*):Boolean {
    return o === this;
  }
}


