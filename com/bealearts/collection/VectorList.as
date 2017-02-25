/**
 *
 * Copyright (c) 2010, David Beale
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
package com.bealearts.collection
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import mx.collections.IList;
	import mx.core.IPropertyChangeNotifier;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.utils.ArrayUtil;
	
	
	/**
	 * A Vector based List
	 * 
	 * @see VectorCollection
	 * @see ArrayList
	 */
	[RemoteClass]
	public class VectorList extends EventDispatcher implements IList, IExternalizable, IPropertyChangeNotifier
	{
		/* PUBLIC */
		
		
		/**
		 * Helper function to test if an Object is a Vector
		 */
		public static function isVector(value:Object):Boolean
		{
			// Have to handle primatives specifically for some reason
			if ( 
				(value is Vector.<*>) ||
				(value is Vector.<int>) ||
				(value is Vector.<uint>) ||
				(value is Vector.<String>) ||
				(value is Vector.<Number>) ||
				(value is Vector.<Boolean>)
			)
				return true;
			else
				return false;
				
		}
		
		
		/**
		 * Source Vector for the List
		 */
		public function get source():Object
		{
			return this._source;
		}
		
		public function set source(value:Object):void
		{
			/* LOCALS */
			var index:uint = 0;
			var event:CollectionEvent = null;
			
			// Check for a Vector
			if ( !VectorList.isVector(value) )
				throw new ArgumentError('Argument is not a Vector');
			
			if (this._source && this._source.length)
			{
				index = this._source.length;
				while (index--)
				{
					this.stopMonitorUpdates(this._source[index]);
				}
			}
			
			this._source = value ? value : new Vector.<Object>;
			
			index = this._source.length;
			while(index--)
			{
				this.monitorUpdates(this._source[index]);
			}
			
			if (this.dispatchItemEvents == 0)
			{
				event = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				event.kind = CollectionEventKind.RESET;
				
				this.dispatchEvent(event);
			}
			
			this.sourceAsArrayValid = false;
		}
		
		
		
		/**
		 * Constructor
		 * 
		 * <p>We have to allow for a 'default' constructor, to support Serialisation</p>
		 * 
		 * @param source Source Vector for the List
		 */
		public function VectorList(source:Object=null)
		{
			super();
			
			this.resourceManager = ResourceManager.getInstance();
			
			if (source)
				this.source = source;
			else
				this.source = new Vector.<Object>;
		}
		
		
		/**
		 * The number of items in this collection. 
		 */
		public function get length():int
		{
			if ( this.source )
				return this.source.length;
			else
				return 0;
		}
		
		
		/**
		 * Adds the specified item to the end of the list.
     	 * Equivalent to <code>addItemAt(item, length)</code>
	 	 */ 
		public function addItem(item:Object):void
		{
			this.addItemAt(item, this.length);
		}
		
		
		/**
	     *  Adds the item at the specified index.  
	     *  The index of any item greater than the index of the added item is increased by one.  
	     *  If the the specified index is less than zero or greater than the length
	     *  of the list, a RangeError is thrown.
	     * 
	     *  @param item The item to place at the index.
	     *  @param index The index at which to place the item.
	     *  @throws RangeError if index is less than 0 or greater than the length of the list. 
		 */
		public function addItemAt(item:Object, index:int):void
		{
			if (index < 0 || index > this.length) 
				throw new RangeError( resourceManager.getString("collections", "outOfBounds", [ index ]) );
			
			this.source.splice(index, 0, item);
			
			this.monitorUpdates(item);
			this.dispatchCollectionEvent(CollectionEventKind.ADD, item, index);
			
			this.sourceAsArrayValid = false;
		}
		
		
		/**
	     *  Gets the item at the specified index.
	     * 
	     *  @param index The index in the list from which to retrieve the item.
	     *
	     *  @param prefetch An <code>int</code> indicating both the direction
	     *  and number of items to fetch during the request if the item is
	     *  not local.
	     *
	     *  @return The item at that index, or <code>null</code> if there is none.
	     *
	     *  @throws mx.collections.errors.ItemPendingError if the data for that index needs to be 
	     *  loaded from a remote location.
	     *
	     *  @throws RangeError if <code>index &lt; 0</code>
	     *  or <code>index >= length</code>.
		 */
		public function getItemAt(index:int, prefetch:int=0):Object
		{
			if (index < 0 || index >= this.length)
				throw new RangeError( resourceManager.getString("collections", "outOfBounds", [ index ]) );
			
			return this.source[index];
		}
		

		/**
		 *  Returns the index of the item if it is in the list such that
		 *  getItemAt(index) == item.
		 * 
		 *  <p>Note: unlike <code>IViewCursor.find<i>xxx</i>()</code> methods,
		 *  The <code>getItemIndex()</code> method cannot take a parameter with 
		 *  only a subset of the fields in the item being serched for; 
		 *  this method always searches for an item that exactly matches
		 *  the input parameter.</p>
		 * 
		 *  @param item The item to find.
		 *
		 *  @return The index of the item, or -1 if the item is not in the list.
		 */		
		public function getItemIndex(item:Object):int
		{
			return ArrayUtil.getItemIndex(item, this.toArray());
		}
		

		/**
		 *  Notifies the view that an item has been updated.  
		 *  This is useful if the contents of the view do not implement 
		 *  <code>IEventDispatcher</code> and dispatches a 
		 *  <code>PropertyChangeEvent</code>.  
		 *  If a property is specified the view may be able to optimize its 
		 *  notification mechanism.
		 *  Otherwise it may choose to simply refresh the whole view.
		 *
		 *  @param item The item within the view that was updated.
		 *
		 *  @param property The name of the property that was updated.
		 *
		 *  @param oldValue The old value of that property. (If property was null,
		 *  this can be the old value of the item.)
		 *
		 *  @param newValue The new value of that property. (If property was null,
		 *  there's no need to specify this as the item is assumed to be
		 *  the new value.)
		 *
		 *  @see mx.events.CollectionEvent
		 *  @see mx.events.PropertyChangeEvent
		 */
		public function itemUpdated(item:Object, property:Object=null, oldValue:Object=null, newValue:Object=null):void
		{
			/* LOCALS */
			var event:PropertyChangeEvent = null;
			
			event = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
			event.kind = PropertyChangeEventKind.UPDATE;
			event.source = item;
			event.property = property;
			event.oldValue = oldValue;
			event.newValue = newValue;
			
			this.onItemUpdate(event);
			
			this.sourceAsArrayValid = false;
		}
		
		
		/** 
		 *  Removes all items from the list.
		 */
		public function removeAll():void
		{
			/* LOCALS */
			var index:uint = 0;
			
			index = this.source.length;
			while (index--)
			{
				this.stopMonitorUpdates(this.source[index]);
			}
		
			this.source.splice(0, this.source.length);
			
			this.dispatchCollectionEvent(CollectionEventKind.RESET);	
			this.sourceAsArrayValid = false;
		}
		
		
		/**
		 *  Removes an item form the Collection
		 *  This is a convenience function which is not par of the IList interface
		 * 
		 *  @param item The item to remove
		 * 
		 *  @return The index the item was at in the collection, -1 if not found
		 */
		public function removeItem(item:Object):int
		{
			var index:int = this.getItemIndex(item);
			
			if (index != -1)
				this.removeItemAt(index);
			
			return index;
		}
		
		
		/**
		 *  Removes the item at the specified index and returns it.  
		 *  Any items that were after this index are now one index earlier.
		 *
		 *  @param index The index from which to remove the item.
		 *
		 *  @return The item that was removed.
		 *
		 *  @throws RangeError is index is less than 0 or greater than length. 
		 */		
		public function removeItemAt(index:int):Object
		{
			/* LOCALS */
			var obj:Object = null;
			
			if (index < 0 || index >= this.source.length)
				throw new RangeError( resourceManager.getString("collections", "outOfBounds", [ index ]) );

			obj = this.source.splice(index, 1)[0];
			this.sourceAsArrayValid = false;
			
			this.stopMonitorUpdates(obj);
			this.dispatchCollectionEvent(CollectionEventKind.REMOVE, obj, index);			
			
			return obj;
		}
		

		/**
		 *  Places the item at the specified index.  
		 *  If an item was already at that index the new item will replace it
		 *  and it will be returned.
		 *
		 *  @param item The new item to be placed at the specified index.
		 *
		 *  @param index The index at which to place the item.
		 *
		 *  @return The item that was replaced, or <code>null</code> if none.
		 *
		 *  @throws RangeError if index is less than 0 or greater than length.
		 */
		public function setItemAt(item:Object, index:int):Object
		{
			/* LOCALS */
			var oldItem:Object = null;
			var hasCollectionListener:Boolean = false;
			var hasPropertyListener:Boolean = false;
			var updateInfo:PropertyChangeEvent = null;
			var event:CollectionEvent = null;
			
			if (index < 0 || index >= this.source.length) 
				throw new RangeError( resourceManager.getString("collections", "outOfBounds", [ index ]) );
			
			oldItem = this.source[index];
			this.source[index] = item;
			this.sourceAsArrayValid = false;
			
			this.stopMonitorUpdates(oldItem);
			this.monitorUpdates(item);
			
			// Dispatch the collection events 
			if (this.dispatchItemEvents == 0)
			{
				hasCollectionListener = this.hasEventListener(CollectionEvent.COLLECTION_CHANGE);
				hasPropertyListener = this.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE);
				
				if (hasCollectionListener || hasPropertyListener)
				{
					updateInfo = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
					updateInfo.kind = PropertyChangeEventKind.UPDATE;
					updateInfo.oldValue = oldItem;
					updateInfo.newValue = item;
					updateInfo.property = index;
				}
				
				if (hasCollectionListener)
				{
					event = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
					event.kind = CollectionEventKind.REPLACE;
					event.location = index;
					event.items.push(updateInfo);
					
					this.dispatchEvent(event);
				}
				
				if (hasPropertyListener)
				{
					this.dispatchEvent(updateInfo);
				}
			}
			
			return oldItem;
		}
		
		
		public function toArray():Array
		{
			//Need to cache this as this is used often
			if ( !this.sourceAsArrayValid )
			{	
				this.sourceAsArray = new Array(this.source.length);
				var i:uint=this.source.length;
				
				while (i--) 
				{
					this.sourceAsArray[i] = this.source[i];
				}
			
				this.sourceAsArrayValid = false;
			}
			
			return this.sourceAsArray.concat();
		}
		
		
		
		
		/**
		 * Only the source property is serialized.
		 */
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject(this._source);
		}
		

		/**
		 * Only the source property is serialized.
		 */
		public function readExternal(input:IDataInput):void
		{
			this.source = input.readObject();
		}
		
		
		/**
		 * Provides access to the unique id for this list.
		 */
		public function get uid():String
		{
			return this._uid;
		}	
		
		public function set uid(value:String):void
		{
			this._uid = value;
		}
		
		
		/* PROTECTED */
		
		/** 
		 * If the item is an IEventDispatcher stop watching it for updates.
		 * 
		 * @param item Item to stop monitoring
		 */
		protected function stopMonitorUpdates(item:Object):void
		{
			if (item && item is IEventDispatcher)
				IEventDispatcher(item).removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, this.onItemUpdate);    
		}		
		
		
		/**
		 *  Handle an item being updated
		 */    
		protected function onItemUpdate(event:PropertyChangeEvent):void
		{
			/* LOCALS */
			var itemEvent:PropertyChangeEvent = null;
			var index:uint = 0;
			
			this.dispatchCollectionEvent(CollectionEventKind.UPDATE, event);
			
			// Dispatch object event now
			if (this.dispatchItemEvents == 0 && this.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE))
			{
				itemEvent = PropertyChangeEvent( event.clone() );
				index = this.getItemIndex(event.target);
				
				itemEvent.property = index.toString() + "." + event.property;
				this.dispatchEvent(itemEvent);
			}
		}		
				
		
		
		/* PRIVATE */
		
		private var _uid:String = '';
		
		private var _source:Object = null;
		
		private var resourceManager:IResourceManager = null;
		
		private var dispatchItemEvents:uint = 0;
		
		private var sourceAsArray:Array = null;
		
		private var sourceAsArrayValid:Boolean = false;
		
		
		/** 
		 * If the item is an IEventDispatcher monitor it for updates. 
		 * 
		 * @param item Item to monitor 
		 */
		private function monitorUpdates(item:Object):void
		{
			if (item && (item is IEventDispatcher))
				IEventDispatcher(item).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, this.onItemUpdate, false, 0, true);
		}
		
		
		/**
		 *  Dispatches a collection event
		 *
		 *  @param kind String indicates what the kind of property the event should be
		 *  @param item Object reference to the item that was added or removed
		 *  @param location int indicating where in the source the item was added.
		 */
		private function dispatchCollectionEvent(kind:String, item:Object = null, location:int = -1):void
		{
			/* LOCALS */
			var event:CollectionEvent = null;
			var itemEvent:PropertyChangeEvent = null;
			
			if (this.dispatchItemEvents == 0)
			{
				if (this.hasEventListener(CollectionEvent.COLLECTION_CHANGE))
				{
					event = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
					event.kind = kind;
					event.items.push(item);
					event.location = location;
					
					this.dispatchEvent(event);
				}
				
				// Dispatch a complementary PropertyChangeEvent
				if (this.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE) && (kind == CollectionEventKind.ADD || kind == CollectionEventKind.REMOVE))
				{
					itemEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
					itemEvent.property = location;
					
					if (kind == CollectionEventKind.ADD)
						itemEvent.newValue = item;
					else
						itemEvent.oldValue = item;
					
					this.dispatchEvent(itemEvent);
				}
			}
		}		
	}
}