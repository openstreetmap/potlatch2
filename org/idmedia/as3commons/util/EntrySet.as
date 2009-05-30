package org.idmedia.as3commons.util
{
	import org.idmedia.as3commons.lang.IllegalArgumentException;
	
	internal class EntrySet extends AbstractSet {
	  
	  private var table:Array;
	  private var tableSize:int;
	  
	  function EntrySet() {
	    table = new Array();
	    tableSize = 0;
	  }
	  
	  override public function iterator():Iterator {
	    return new EntrySetIterator(this);	
	  }
	  
	  override public function add(object:*):Boolean {
	    if(!(object is Entry)) {
	      throw new IllegalArgumentException();	
	    }
	
	    if(!contains(object)) {
	      table.push(object);
	      tableSize++;
	      return true;	
	    }
	    return false;
	  }
	  
	  override public function remove(entry:* = null):Boolean {
	    for(var i:int = 0;i < tableSize; i++) {
	      if(Entry(entry).equals(table[i])) {
	        table.splice(i, 1);
	        tableSize--;
	        return true;	
	      }	
	    }
	    return false;
	  }
	  
	  public function get(index:int):* {
	    return table[index];
	  }
	  
	  public function removeEntryForKey(key:*):Entry {
	    var e:Entry = null;
	    for(var i:int = 0;i < tableSize; i++) {
	      if(Entry(table[i]).getKey() === key) {
	        e = table[i];
	        table.splice(i, 1);
	        tableSize--;
	        return e;	
	      }	
	    }
	    return e;
	  }
	  
	  override public function size():int {
	    return tableSize;	
	  }
	}

}