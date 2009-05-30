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
   * A collection that contains no duplicate elements.  More formally, sets
   * contain no pair of elements <code>e1</code> and <code>e2</code> such that
   * <code>e1.equals(e2)</code>, and at most one null element.  As implied by
   * its name, this interface models the mathematical <i>set</i> abstraction.<p>
   *
   * The <tt>Set</tt> interface places additional stipulations, beyond those
   * inherited from the <tt>Collection</tt> interface, on the contracts of all
   * constructors and on the contracts of the <tt>add</tt>, <tt>equals</tt> and
   * <tt>hashCode</tt> methods.  Declarations for other inherited methods are
   * also included here for convenience.  (The specifications accompanying these
   * declarations have been tailored to the <tt>Set</tt> interface, but they do
   * not contain any additional stipulations.)<p>
   *
   * @author sleistner
   */
  public interface Set extends Collection {
  }
}