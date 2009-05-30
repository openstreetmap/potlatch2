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
  
  /**
   * This class provides a skeletal implementation of the <tt>Set</tt>
   * interface to minimize the effort required to implement this
   * interface. <p>
   *
   * The process of implementing a set by extending this class is identical
   * to that of implementing a Collection by extending AbstractCollection,
   * except that all of the methods and constructors in subclasses of this
   * class must obey the additional constraints imposed by the <tt>Set</tt>
   * interface (for instance, the add method must not permit addition of
   * multiple instances of an object to a set).<p>
   *
   * @author sleistner	
   */
  public class AbstractSet extends AbstractCollection implements Set {
    
    /**
     * Compares the specified object with this set for equality.  Returns
     * <tt>true</tt> if the given object is also a set, the two sets have
     * the same size, and every member of the given set is contained in
     * this set.  This ensures that the <tt>equals</tt> method works
     * properly across different implementations of the <tt>Set</tt>
     * interface.<p>
     *
     * This implementation first checks if the specified object is this
     * set; if so it returns <tt>true</tt>.  Then, it checks if the
     * specified object is a set whose size is identical to the size of
     * this set; if not, it returns false.  If so, it returns
     * <tt>containsAll((Collection) o)</tt>.
     *
     * @param o Object to be compared for equality with this set.
     * @return <tt>true</tt> if the specified object is equal to this set.
     */
    override public function equals(o:*):Boolean {
      if(o === this) return true;

      if(!(o is Set)) return false;
			
      var c:Collection = Collection(o);
      if(c.size() != size()) return false;
			
      try {
        return containsAll(c);
      } catch(unused:NullPointerException) {
        return false;
      }
      return false;
    }
  }
}