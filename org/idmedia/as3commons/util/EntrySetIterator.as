package org.idmedia.as3commons.util
{
	import org.idmedia.as3commons.lang.*;
	
	internal class EntrySetIterator implements Iterator {
	  
	  private var cursor:int = 0;
	  private var current:Entry = null;
	  private var s:EntrySet = null;
	  
	  function EntrySetIterator(s:EntrySet = null) {
	    this.s = s;
	  }
	  
	  public function hasNext():Boolean {
	    return (cursor < s.size());
	  }
	  
	  public function next():* {
	    var h:int = s.size();
	    current = s.get(cursor++) as Entry;
	    if(current == null) {
	      throw new NoSuchElementException();	
	    }
	    return current;
	  }
	  
	  public function remove():void {
	    if(current == null) {
	      throw new IllegalStateException();	
	    }
	    var key:* = current.getKey();
	    current = null;
	    s.removeEntryForKey(key);
	  }
	}
}