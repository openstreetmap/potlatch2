package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    
    import net.systemeD.halcyon.connection.actions.*;

    public class Entity extends EventDispatcher {
        private var _id:Number;
        private var _version:uint;
        private var _uid:Number;
        private var _timestamp:String;
        private var tags:Object = {};
        private var modified:Boolean = false;
		private var _loaded:Boolean = true;
		private var parents:Dictionary = new Dictionary();
		public var locked:Boolean = false;						// lock against purging when off-screen
		public var deleted:Boolean = false;

        public function Entity(id:Number, version:uint, tags:Object, loaded:Boolean, uid:Number, timestamp:String) {
            this._id = id;
            this._version = version;
            this._uid = uid;
            this._timestamp = timestamp;
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

        public function get uid():Number {
            return _uid;
        }

        public function get loaded():Boolean {
            return _loaded;
        }

		public function get timestamp():String {
			return _timestamp;
		}

		public function updateEntityProperties(version:uint, tags:Object, loaded:Boolean, uid:Number, timestamp:String):void {
			_version=version; this.tags=tags; _loaded=loaded; _uid = uid; _timestamp = timestamp;
			deleted=false;
		}

		public function renumber(newID:Number, newVersion:uint):void {
			this._id = newID;
			this._version = newVersion;
		}

		// Tag-handling methods

        public function hasTags():Boolean {
            for (var key:String in tags)
                return true;
            return false;
        }

        public function hasInterestingTags():Boolean {
            for (var key:String in tags) {
              if (key != "attribution" && key != "created_by" && key != "source" && key.indexOf('tiger:') != 0) {
                //trace(key);
                return true;
              }
            }
            return false;
        }

        public function isUneditedTiger():Boolean {
            // todo: make this match the rules from the tiger edited map
            // http://github.com/MapQuest/TIGER-Edited-map/blob/master/inc/layer-tiger.xml.inc
            if (this is Way && (uid == 7168 || uid == 15169 || uid == 20587)) {//todo fixme etc
              return true;
            }
            return false;
        }

        public function getTag(key:String):String {
            return tags[key];
        }

		public function tagIs(key:String,value:String):Boolean {
			if (!tags[key]) { return false; }
			return tags[key]==value;
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

        public function markClean():void {
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
            if (this is Node) {
              var n:Node = Node(this);
              if (isDeleted) {
                Connection.getConnection().removeDupe(n);
              } else {
                Connection.getConnection().addDupe(n);
              }
            }
		}
		
		internal function isEmpty():Boolean {
			return false;	// to be overridden
		}

		public function nullify():void {
			// this retains a dummy entity in memory, for entities that we no longer need
			// but which are part of a still-in-memory relation
			nullifyEntity();
		}
		
		protected function nullifyEntity():void {
			// this is the common nullify behaviour for all entity types (we'd call this by super() if ActionScript let us)
			_version=0;
			_loaded=false;
			tags={};
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
		
		public function findParentRelationsOfType(type:String, role:String=null):Array {
			var a:Array=[];
			for (var o:Object in parents) {
				if (o is Relation && Relation(o).tagIs('type',type) && (role==null || Relation(o).hasMemberInRole(this,role))) { 
					a.push(o);
				}
			}
			return a;
		}
		
		public function countParentObjects(within:Object):uint {
			var count:uint=0;
			for (var o:Object in parents) {
				if (o.getType()==within.entity && o.getTag(within.k)) {
					if (within.v && within.v!=o.getTag(within.k)) { break; }
					if (within.role && !Relation(o).hasMemberInRole(this,within.role)) { break; }
					count++;
				}
			}
			return count;
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

		public function getDescription():String {
			var basic:String=this.getType()+" "+_id;
			if (tags['ref'] && tags['name']) { return tags['ref']+' '+tags['name']+' ('+basic+')'; }
			if (tags['ref']) { return tags['ref']+' ('+basic+')'; }
			if (tags['name']) { return tags['name']+' ('+basic+')'; }
			return basic;
		}

        public function getType():String {
            return '';
        }

    }

}

