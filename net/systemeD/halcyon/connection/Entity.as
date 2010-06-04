package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    
    import net.systemeD.halcyon.connection.actions.*;

    public class Entity extends EventDispatcher {
        private var _id:Number;
        private var _version:uint;
        private var tags:Object = {};
        private var modified:Boolean = false;
		private var _loaded:Boolean = true;
		private var parents:Dictionary = new Dictionary();
		private var locked:Boolean = false;
		public var deleted:Boolean = false;

        public function Entity(id:Number, version:uint, tags:Object, loaded:Boolean) {
            this._id = id;
            this._version = version;
            this.tags = tags;
			this._loaded = loaded;
            modified = id < 0;
        }

        public function get id():Number {
            return _id;
        }

        public function get version():uint {
            return _version;
        }

        public function get loaded():Boolean {
            return _loaded;
        }

		public function updateEntityProperties(version:uint, tags:Object, loaded:Boolean):void {
			_version=version; this.tags=tags; _loaded=loaded;
		}

		// Tag-handling methods

        public function hasTags():Boolean {
            for (var key:String in tags)
                return true;
            return false;
        }

		// ** we could do with hasInterestingTags - don't bother with source, created_by, any TIGER tags, etc.

        public function getTag(key:String):String {
            return tags[key];
        }
        
        public function setTag(key:String, value:String, performAction:Function):void {
            performAction(new SetTagAction(this, key, value));
        }

        public function renameTag(oldKey:String, newKey:String, performAction:Function):void {
            performAction(new SetTagKeyAction(this, oldKey, newKey));
        }

        public function getTagList():TagList {
            return new TagList(tags);
        }

        public function getTagsCopy():Object {
            var copy:Object = {};
            for (var key:String in tags )
                copy[key] = tags[key];
            return copy;
        }

		public function getTagsHash():Object {
			// hm, not sure we should be doing this, but for read-only purposes
			// it's faster than using getTagsCopy
			return tags;
		}

        public function getTagArray():Array {
            var copy:Array = [];
            for (var key:String in tags )
                copy.push(new Tag(this, key, tags[key]));
            return copy;
        }

		// Clean/dirty methods

        public function get isDirty():Boolean {
            return modified;
        }

        public function markClean(newID:Number, newVersion:uint):void {
            this._id = newID;
            this._version = newVersion;
            modified = false;
        }

        internal function markDirty():void {
            modified = true;
        }

		// Delete entity
		
		public function remove(performAction:Function):void {
			// to be overridden
		}
		
		public function isDeleted():Boolean {
		    return deleted;
		}
		
		public function setDeletedState(isDeleted:Boolean):void {
		    deleted = isDeleted;
		}
		
		internal function isEmpty():Boolean {
			return false;	// to be overridden
		}
		
		public function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			return true;	// to be overridden
		}

		public function removeFromParents(performAction:Function):void {
			for (var o:Object in parents) {
				if (o is Relation) { Relation(o).removeMember(this, performAction); }
				else if (o is Way) { Way(o).removeNode(Node(this), performAction); }
				if (o.isEmpty()) { o.remove(performAction); }
			}
		}

		// Parent handling
		
		public function addParent(parent:Entity):void {
			parents[parent]=true;
			
			if ( parent is Relation )
			    dispatchEvent(new RelationMemberEvent(Connection.ADDED_TO_RELATION, this, parent as Relation, -1));
		}

		public function removeParent(parent:Entity):void {
			delete parents[parent];

			if ( parent is Relation )
			    dispatchEvent(new RelationMemberEvent(Connection.REMOVED_FROM_RELATION, this, parent as Relation, -1));
		}
		
		public function get parentWays():Array {
			var a:Array=[];
			for (var o:Object in parents) {
				if (o is Way) { a.push(o); }
			}
			return a;
		}

		public function get hasParents():Boolean {
			for (var o:Object in parents) { return true; }
			return false;
		}
		
		public function get hasParentWays():Boolean {
			for (var o:Object in parents) {
				if (o is Way) { return true; }
			}
			return false;
		}
		
		public function get numParentWays():uint {
			var i:uint=0;
			for (var o:Object in parents) {
				if (o is Way) { i++; }
			}
			return i;
		}
		
		public function get parentRelations():Array {
			var a:Array=[];
			for (var o:Object in parents) {
				if (o is Relation) { a.push(o); }
			}
			return a;
		}
		
		public function get parentObjects():Array {
			var a:Array=[];
			for (var o:Object in parents) { a.push(o); }
			return a;
		}
		
		public function hasParent(entity:Entity):Boolean {
            return parents[entity] == true;
        }

		public function get memberships():Array {
			var list:Array=[];
			for (var o:Object in parents) {
				if (o is Relation) {
					for (var i:uint=0; i<o.length; i++) {
						if (o.getMember(i).entity==this) {
							list.push( { relation:o, position:i, role: o.getMember(i).role } );
						}
					}
				}
			}
            // it's useful to return in a sorted order, even if the relations are interleaved
            // e.g. [{r0 p1},{r1 p1},{r0 p4}]
			return list.sortOn("position"); 
		}

		// Resume/suspend redraw
		
		public function suspend():void {
			dispatchEvent(new EntityEvent(Connection.SUSPEND_REDRAW, this));
		}
		
		public function resume():void {
			dispatchEvent(new EntityEvent(Connection.RESUME_REDRAW, this));
		}

		// To be overridden

        public function getType():String {
            return '';
        }

    }

}

