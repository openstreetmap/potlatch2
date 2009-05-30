package org.idmedia.as3commons.util
{   
	/**
	 * This class was added by Derek Wischusen on 10/15/2007.
	 * @author wischusen
	 * 
	 */	
	public class HashSet extends AbstractSet
	{
		private var map : HashMap;
	    private static var PRESENT : Object = new Object();

		public function HashSet(coll : Map = null) : void
		{
			map = new HashMap();
			
			if (coll)
				map.putAll(coll)
		}
		
		override public function iterator() :Iterator
	  	{
	        return map.keySet().iterator();
	    }

	    override public function size() : int
	    {
	        return map.size();
	    }
		
	    override public function isEmpty() : Boolean 
	    {
	        return map.isEmpty();
	    }
		
	    override public function contains(o : *) : Boolean
	    {
	        return map.containsKey(o);
	    }
		
	    override public function add(e : *) : Boolean 
	    {
	        return (map.put(e, PRESENT) == null);
	    }
		
	    override public function remove(o : * = null) : Boolean 
	    {
	        return (map.remove(o) == PRESENT);
	    }
		
	    override public function clear() : void 
	    {
	        map.clear();
	    }

		
			
	}
}