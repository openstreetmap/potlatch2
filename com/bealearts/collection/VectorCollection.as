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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	
	
	/**
	 * A Vector based Collection
	 * 
	 * <p>Allows one to wrap a Vector inorder to access it using Binding in the same way as an ArrayColletion</p>
	 * <p>Reqires a source Vector on instantiation.</p>
	 * <p>Example usage <code>var someBusinessObjects = new VectorCollection(new Vector.<SomeBusinessObject>);</code></p>
	 * 
	 * @see ArrayCollection
	 * @see Vector
	 */
	[RemoteClass]
	[DefaultProperty("source")]
	[Bindable("listChanged")]
	public class VectorCollection extends ListCollectionView implements IExternalizable
	{
		/* PUBLIC */
		
		/**
		 *  The source of data in the VectorCollection.
		 *  The VectorCollection object does not represent any changes that you make
		 *  directly to the source array. Always use the ICollectionView or IList methods to modify the collection.
		 *
		 *  @throws ArgumentError if parameter is not a Vector		 
		 */
		public function get source():Object
		{
			if (this.list && (this.list is VectorList))
				return VectorList(this.list).source;
			else
				return null;
		}

		public function set source(value:Object):void
		{	
			// Check for a Vector
			if ( !VectorList.isVector(value) )
				throw new ArgumentError('Argument is not a Vector');
			
			this.list = new VectorList( value as Vector.<*> );
		}		
		
		
		
		/**
		 * Constructor
		 * 
		 * <p>We have to allow for a 'default' constructor, to support Serialisation</p>
		 * 
		 * @param source Source Vector for the Collection
		 */
		public function VectorCollection(source:Object=null)
		{
			super();
			
			if (source)
				this.source = source;
			else
				this.source = new Vector.<Object>;
		}
		
		
		
		/**
		 *  Removes an item form the Collection
		 *  This is a convenience function which is not part of the IList interface
		 * 
		 *  @param item The item to remove
		 * 
		 *  @return The index the item was at in the collection, -1 if not found
		 */
/*		public function removeItem(item:Object):int
		{
			return VectorList(this.list).removeItem(item);
		}
*/		
		
		
		
		/**
		 *  Only the source property is serialized.
		 */
		public function readExternal(input:IDataInput):void
		{
			if (this.list is IExternalizable)
				IExternalizable(this.list).readExternal(input);
			else
				this.source = input.readObject();
		}
		
		/**
		 *  Only the source property is serialized.
		 */
		public function writeExternal(output:IDataOutput):void
		{
			if (this.list is IExternalizable)
				IExternalizable(this.list).writeExternal(output);
			else
				output.writeObject(this.source);
		}
		
		/* PROTECTED */
		
		/* PRIVATE */
	}
}