package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;

    import net.systemeD.halcyon.connection.actions.*;

    /** An Entity is an object stored in the map database, and therefore uploaded and downloaded. This includes Nodes, Ways, Relations but also Changesets etc. */
    public class Entity extends EventDispatcher {
        private var _id:Number;
        private var _version:uint;
        private var _uid:Number;
        private var _timestamp:String;
        private var tags:Object = {};
        private var modified:Boolean = false;
        private var _loaded:Boolean = true;
        private var parents:Dictionary = new Dictionary();
        /** Lock against purging when off-screen */
        public var locked:Boolean = false;
        public var deleted:Boolean = false;
        /** Have all its parents (ie, relations that contain this object as a member, ways that contain this node) been loaded into memory */
        public var parentsLoaded:Boolean = true;

        public function Entity(id:Number, version:uint, tags:Object, loaded:Boolean, uid:Number, timestamp:String) {
            this._id = id;
            this._version = version;
            this._uid = uid;
            this._timestamp = timestamp;
            this.tags = tags;
			this._loaded = loaded;
            modified = id < 0;
        }

        /** OSM ID. */
        public function get id():Number {
            return _id;
        }

        /** Current version number. */
        public function get version():uint {
            return _version;
        }

        /** User ID who last edited this entity (from OSM API). */
        public function get uid():Number {
            return _uid;
        }

		/** Is entity fully loaded, or is it just a placeholder reference (as a relation member)? */
        public function get loaded():Boolean {
            return _loaded;
        }

		/** List of entities. Overridden by EntityCollection. */
		public function get entities():Array {
			return [this];
		}

        /** Most recent modification of the entity (from OSM API). */
        public function get timestamp():String {
            return _timestamp;
        }

        /** Set a bunch of properties in one hit. Implicitly makes entity not deleted. */
        public function updateEntityProperties(version:uint, tags:Object, loaded:Boolean, parentsLoaded:Boolean, uid:Number, timestamp:String):void {
            _version=version; this.tags=tags; _loaded=loaded; this.parentsLoaded=parentsLoaded; _uid = uid; _timestamp = timestamp;
            deleted=false;
        }

        /** Assign a new ID and version. */
        public function renumber(newID:Number, newVersion:uint):void {
            this._id = newID;
            this._version = newVersion;
        }

		// Tag-handling methods

        /** Whether the entity has > 0 tags. */
        public function hasTags():Boolean {
            for (var key:String in tags)
                return true;
            return false;
        }

        /** Whether the entity has any tags other than meta-tags (attribution, created_by, source, tiger:...) */
        public function hasInterestingTags():Boolean {
            for (var key:String in tags) {
              if (key != "attribution" && key != "created_by" && key != "source" && key.indexOf('tiger:') != 0) {
                //trace(key);
                return true;
              }
            }
            return false;
        }

        /** Rough function to detect entities untouched since TIGER import. */
        public function isUneditedTiger():Boolean {
            // todo: make this match the rules from the tiger edited map
            // http://github.com/MapQuest/TIGER-Edited-map/blob/master/inc/layer-tiger.xml.inc
            if (this is Way && (uid == 7168 || uid == 15169 || uid == 20587)) {//todo fixme etc
              return true;
            }
            return false;
        }

        /** Retrieve a tag by key. */
        public function getTag(key:String):String {
            return tags[key];
        }

        /** @return true if there exists key=value */
        public function tagIs(key:String,value:String):Boolean {
            if (!tags[key]) { return false; }
            return tags[key]==value;
        }

        /** Set key=value, with optional undoability.
         * @param key Name of key to set
         * @param value Value to set tag to
         * @param performAction Single-argument function to pass a SetTagAction to.
         * @example setTag("highway", "residential", MainUndoStack.getGlobalStack().addAction);
         */
        public function setTag(key:String, value:String, performAction:Function):void {
            performAction(new SetTagAction(this, key, value));
        }

        /** Change oldKey=[value] to newKey=[value], with optional undoability.
         * @param oldKey Name of key to rename
         * @parame newKey New name of key
         * @param performAction Single-argument function to pass a SetTagKeyAction to.
         * @example renameTag("building", "amenity", MainUndoStack.getGlobalStack().addAction);
         */
        public function renameTag(oldKey:String, newKey:String, performAction:Function):void {
            performAction(new SetTagKeyAction(this, oldKey, newKey));
        }

        public function getTagList():TagList {
            return new TagList(tags);
        }

        /** Returns an object that duplicates the tags on this entity. */
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

        /** Returns an array that duplicates the tags on this entity. */
        public function getTagArray():Array {
            var copy:Array = [];
            for (var key:String in tags )
                copy.push(new Tag(this, key, tags[key]));
            return copy;
        }

		// Clean/dirty methods

        /** Check if entity is modified since last markClean(). */
        public function get isDirty():Boolean {
            return modified;
        }

        /** Reset modified flag. You should not be calling this directly, instead you should be calling markClean from your UndoableEntityAction */
        public function markClean():void {
            modified = false;
        }

        /** Set entity as modified. You should not be calling this directly, instead you should be calling markDirty from your UndoableEntityAction */
        internal function markDirty():void {
            modified = true;
        }


        /** Delete entity - must be overridden. */
        public function remove(performAction:Function):void {
            // to be overridden
        }

        /** Whether entity is marked deleted. */
        public function isDeleted():Boolean {
            return deleted;
        }

        /** Mark entity as deleted. */
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

        /** Whether entity is "empty" - to be overridden by subclass. */
        internal function isEmpty():Boolean {
            return false;
        }

        /** Free up memory by converting entity to a dummy entity, for entities that we no longer need
        *  but which are part of a still-in-memory relation */
        public function nullify():void {
            nullifyEntity();
        }

        /** Implement nullifybehaviour: delete tags, etc. */
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

        /** Create parent link from this entity to another. */
        public function addParent(parent:Entity):void {
            parents[parent]=true;

            if ( parent is Relation )
                dispatchEvent(new RelationMemberEvent(Connection.ADDED_TO_RELATION, this, parent as Relation, -1));
        }

        /** Remove parent link. */
        public function removeParent(parent:Entity):void {
            delete parents[parent];

            if ( parent is Relation )
                dispatchEvent(new RelationMemberEvent(Connection.REMOVED_FROM_RELATION, this, parent as Relation, -1));
        }

        /** Get array of all Ways of which this object (presumably a node) is a child. */
        public function get parentWays():Array {
            var a:Array=[];
            for (var o:Object in parents) {
                if (o is Way) { a.push(o); }
            }
            return a;
        }

        /** Whether this entity has any parents. */
        public function get hasParents():Boolean {
            for (var o:Object in parents) { return true; }
            return false;
        }

        /** Whether this entity has any parents that are Ways. */
        public function get hasParentWays():Boolean {
            for (var o:Object in parents) {
                if (o is Way) { return true; }
            }
            return false;
        }

        /** How many parents are Ways? */
        public function get numParentWays():uint {
            var i:uint=0;
            for (var o:Object in parents) {
                if (o is Way) { i++; }
            }
            return i;
        }

        /** All parents that are Relations */
        public function get parentRelations():Array {
            var a:Array=[];
            for (var o:Object in parents) {
                if (o is Relation) { a.push(o); }
            }
            return a;
        }

        /** Returns parents that are relations, and of the specified type, and of which this entity is the correct role (if provided).
        *
        * @example entity.findParentRelationsOfType('multipolygon','inner');
        */
        public function findParentRelationsOfType(type:String, role:String=null):Array {
            var a:Array=[];
            for (var o:Object in parents) {
                if (o is Relation && Relation(o).tagIs('type',type) && (role==null || Relation(o).hasMemberInRole(this,role))) {
                    a.push(o);
                }
            }
            return a;
        }

		public function getRelationMemberships():Array {
			var memberships:Array = [];
			for each( var rel:Relation in parentRelations ) {
				for each( var memberIndex:int in rel.findEntityMemberIndexes(this)) {
					memberships.push({
						relation: rel,
						id: rel.id,
						index: memberIndex,
						role: rel.getMember(memberIndex).role,
						description: rel.getDescription(),
						id_idx: rel.id + "/"+memberIndex });
				}
			}
			return memberships;
		}

        /** How many parents does this entity have that satisfy the "within" constraint? */
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

        /** All parents of this entity. */
        public function get parentObjects():Array {
            var a:Array=[];
            for (var o:Object in parents) { a.push(o); }
                return a;
            }

        /** Whether 'entity' is a parent of this Entity. */
        public function hasParent(entity:Entity):Boolean {
            return parents[entity] == true;
        }

            /** Returns all relations that this Entity is part of, as array of {relation, position, role}, sorted by position. */
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



		/** Temporarily prevent redrawing of the object. */
		public function suspend():void {
			dispatchEvent(new EntityEvent(Connection.SUSPEND_REDRAW, this));
		}
		/** Resume redrawing of the object */
		public function resume():void {
			dispatchEvent(new EntityEvent(Connection.RESUME_REDRAW, this));
		}


                /** Basic description of Entity - should be overriden by subclass. */
		public function getDescription():String {
			var basic:String=this.getType()+" "+_id;
			if (tags['ref'] && tags['name']) { return tags['ref']+' '+tags['name']+' ('+basic+')'; }
			if (tags['ref']) { return tags['ref']+' ('+basic+')'; }
			if (tags['name']) { return tags['name']+' ('+basic+')'; }
			return basic;
		}

        /** The type of Entity (node, way etc). By default, returns ''. */
        public function getType():String {
            return '';
        }

		/** Compare type against supplied string */
		public function isType(str:String):Boolean {
			return getType()==str;
		}

    }

}

