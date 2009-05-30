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
	import org.idmedia.as3commons.util.ArrayList;
	import org.idmedia.as3commons.util.Comparator;
	import org.idmedia.as3commons.util.List;

	/**
	 * This class contains various methods for manipulating arrays (such as
	 * sorting and searching).  This class also contains a static factory 
	 * that allows arrays to be viewed as lists.
	 *
	 * <p>The methods in this class all throw a <tt>NullPointerException</tt> if
	 * the specified array reference is null, except where noted.</p>
	 * 
	 * @author sleistner
	 */
	public final class Arrays {
    
		function Arrays (){}
	
		/**
		* Returns a fixed-size list backed by the specified array.  (Changes to
		* the returned list "write through" to the array.)  This method acts
		* as bridge between array-based and collection-based APIs, in
		* combination with <tt>Collection.toArray</tt>.
		*
		* <p>This method also provides a convenient way to create a fixed-size
		* list initialized to contain several elements:
		* <pre>
		*     List<String> stooges = Arrays.asList("Larry", "Moe", "Curly");
		* </pre>
		*
		* @param a the array by which the list will be backed.
		* @return a list view of the specified array.
		* @see Collection#toArray()
		*/
		public static function asList(a:Array):List {
			if(a == null) {
				throw new NullPointerException();
			}
		
			var l:List = new ArrayList();
			var copy:Array = [].concat(a);
			copy.forEach(function(element:*, index:int, arr:Array):void {
				l.add(element);	
			});
			return l;
		}
	
		/**
		* Sorts the specified array of objects according to the order induced by
		* the specified comparator.  All elements in the array must be
		* <i>mutually comparable</i> by the specified comparator (that is,
		* <tt>c.compare(e1, e2)</tt> must not throw a <tt>ClassCastException</tt>
		* for any elements <tt>e1</tt> and <tt>e2</tt> in the array).<p>
		*
		* This sort is guaranteed to be <i>stable</i>:  equal elements will
		* not be reordered as a result of the sort.<p>
		*
		* The sorting algorithm is a modified mergesort (in which the merge is
		* omitted if the highest element in the low sublist is less than the
		* lowest element in the high sublist).  This algorithm offers guaranteed
		* n*log(n) performance. 
		*
		* @param a the array to be sorted.
		* @param c the comparator to determine the order of the array.  A
		*        <tt>null</tt> value indicates that the elements' <i>natural
		*        ordering</i> should be used.
		* @see org.idmedia.as3commons.lang.Comparator
		*/
	    public static function sort(a:Array, c:Comparator):void {
			a.sort(c.compare);
	    }
	}
}
