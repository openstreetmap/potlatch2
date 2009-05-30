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
  import org.idmedia.as3commons.lang.NullPointerException;
  
  /**
   * This class represents an Observable object, or "data"
   * in the model-view paradigm. It can be subclassed to represent an 
   * object that the application wants to have observed. 
   * <p>
   * An observable object can have one or more observers. An observer 
   * may be any object that implements interface <tt>Observer</tt>. After an 
   * Observable instance changes, an application calling the 
   * <code>Observable</code>'s <code>notifyObservers</code> method  
   * causes all of its observers to be notified of the change by a call 
   * to their <code>update</code> method. 
   * <p>
   * The order in which notifications will be delivered is unspecified.  
   * The default implementation provided in the Observable class will
   * notify Observers in the order in which they registered interest, but 
   * subclasses may change this order, use no guaranteed order,
   * or may guarantee that their
   * subclass follows this order, as they choose.
   * <p>
   * When an Observable object is newly created, its set of observers is 
   * empty. Two observers are considered the same if and only if the 
   * <tt>equals</tt> method returns true for them.
   *
   * @author sleistner
   */
  public class Observable {
    
    private var observers:List;
    private var changed:Boolean;
    
    /** Construct an Observable with zero Observers. */
    public function Observable() {
      observers = new ArrayList();
      changed = false;
    }
    
    /**
     * Marks this <tt>Observable</tt> object as having been changed; the 
     * <tt>hasChanged</tt> method will now return <tt>true</tt>.
     */
    public function setChanged():void {
      changed = true;
    }
    
    /**
     * Tests if this object has changed. 
     *
     * @return  <code>true</code> if and only if the <code>setChanged</code> 
     *          method has been called more recently than the 
     *          <code>clearChanged</code> method on this object; 
     *          <code>false</code> otherwise.
     * @see     #clearChanged()
     * @see     #setChanged()
     */
    public function hasChanged():Boolean {
      return changed;
    }
    
    /**
     * Indicates that this object has no longer changed, or that it has 
     * already notified all of its observers of its most recent change, 
     * so that the <tt>hasChanged</tt> method will now return <tt>false</tt>. 
     * This method is called automatically by the 
     * <code>notifyObservers</code> methods. 
     *
     * @see #notifyObservers()
     */
    public function clearChanged():void {
      changed = false;	
    }
    
    /**
     * Adds an observer to the set of observers for this object, provided 
     * that it is not the same as some observer already in the set. 
     * The order in which notifications will be delivered to multiple 
     * observers is not specified. See the class comment.
     *
     * @param   observer  an observer to be added.
     * @throws NullPointerException   if the parameter observer is null.
     */
    public function addObserver(observer:Observer):void {
      if(observer == null) {
        throw new NullPointerException('observer must not be null');
      }
      if(!observers.contains(observer)) {
        observers.add(observer);
      }	
    }
    
    /**
     * Deletes an observer from the set of observers of this object. 
     * Passing <CODE>null</CODE> to this method will have no effect.
     * @param   observer   the observer to be deleted.
     */
    public function deleteObserver(observer:Observer = null):void {
      observers.remove(observer);	
    }
    
    /**
     * Clears the observer list so that this object no longer has any observers.
     */
    public function deleteObservers():void {
      observers.clear();	
    }
    
    /**
     * If this object has changed, as indicated by the 
     * <code>hasChanged</code> method, then notify all of its observers 
     * and then call the <code>clearChanged</code> method to indicate 
     * that this object has no longer changed. 
     * <p>
     * Each observer has its <code>update</code> method called with two
     * arguments: this observable object and the <code>arg</code> argument.
     *
     * @param   args   any object.
     * @see     #clearChanged() #hasChanged()
     * @see     #hasChanged() #hasChanged()
     * @see     org.idmedia.as3commons.util.Observer#update() Observer#update()
     */
    public function notifyObservers(args:*):void {
      if(!changed) {
        return;	
      }
			
      clearChanged();
			
      var iter:Iterator = observers.iterator();
      while(iter.hasNext()) {
        Observer(iter.next()).update(this, args);
      }	
    }
    
    /**
     * Returns the number of observers of this <tt>Observable</tt> object.
     *
     * @return  the number of observers of this object.
     */
    public function countObservers():int {
      return observers.size();	
    }
  }
}