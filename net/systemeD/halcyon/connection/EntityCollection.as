package net.systemeD.halcyon.connection {

	import flash.events.TimerEvent;
	import flash.utils.Timer;
    
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;

	// ** FIXME:
	// - Can we rework the ControllerStates so they work with this (rather than just a raw Array)?
	// - It may be possible to generalise the event timer code into a tidier "event grouping" class of some sort

    public class EntityCollection extends Entity {
		private var _entities:Array;
		private var tagChangedTimer:Timer;
		private var addedToRelationTimer:Timer;
		private var removedFromRelationTimer:Timer;
		private var delayedEvents:Array = [];

        public function EntityCollection(entities:Array) {
			super(-1, 0, {}, true, -1, "");
            _entities = entities;
			
			//To avoid firing on every contained entity, we wait some short time before firing the events
			tagChangedTimer         = new Timer(50, 1); tagChangedTimer.addEventListener(TimerEvent.TIMER, onTimerFinished, false, 0, true);
			addedToRelationTimer    = new Timer(50, 1); addedToRelationTimer.addEventListener(TimerEvent.TIMER, onTimerFinished, false, 0, true);
			removedFromRelationTimer= new Timer(50, 1); removedFromRelationTimer.addEventListener(TimerEvent.TIMER, onTimerFinished, false, 0, true);
			for each(var entity:Entity in _entities) {
				entity.addEventListener(Connection.TAG_CHANGED, onTagChanged, false, 0, true);
				entity.addEventListener(Connection.ADDED_TO_RELATION, onAddedToRelation, false, 0, true);
				entity.addEventListener(Connection.REMOVED_FROM_RELATION, onRemovedFromRelation, false, 0, true);
			}
        }
		
		public function get entities():Array {
			return _entities;
		}
		
		private function onTagChanged(event:TagEvent):void {
			if(tagChangedTimer.running) return;
			delayedEvents.push(new TagEvent(Connection.TAG_CHANGED, this, event.key, event.key, event.oldValue, event.newValue));
			tagChangedTimer.start();
		}
		
		private function onAddedToRelation(event:RelationMemberEvent):void {
			if(addedToRelationTimer.running) return;
			delayedEvents.push(new RelationMemberEvent(Connection.ADDED_TO_RELATION, this, event.relation, event.index));
			addedToRelationTimer.start();
		}
		
		private function onRemovedFromRelation(event:RelationMemberEvent):void {
			if(removedFromRelationTimer.running) return;
			delayedEvents.push(new RelationMemberEvent(Connection.REMOVED_FROM_RELATION, this, event.relation, event.index));
			removedFromRelationTimer.start();
		}
		
		private function onTimerFinished(event:TimerEvent):void { 
			dispatchEvent(delayedEvents.shift());
		}
		
		
		// Tag-handling methods
		
		private function getMergedTags():Object {
			//Builds an object with tags of all entities in this collection. If the value of a tag differs or is not set in all entities, value is marked
			var differentMarker:String = "<different>";
			var mergedTags:Object = _entities[0].getTagsCopy();
			for each(var entity:Entity in _entities) {
				var entityTags:Object = entity.getTagsHash();
				for(var key:String in entityTags) {
					var value:String = entityTags[key];
					if(mergedTags[key] == null || mergedTags[key] != value) {
						mergedTags[key] = differentMarker;
					}
				}
				for(var mergedKey:String in mergedTags) {
					var mergedValue:String = mergedTags[mergedKey];
					if(entityTags[mergedKey] == null || entityTags[mergedKey] != mergedValue) {
						mergedTags[mergedKey] = differentMarker;
					}
				}
			}
			return mergedTags;
		}

        public override function hasTags():Boolean {
			for (var key:String in getMergedTags())
                return true;
            return false;
        }

        public override function hasInterestingTags():Boolean {
			for (var key:String in getMergedTags()) {
              if (key != "attribution" && key != "created_by" && key != "source" && key.indexOf('tiger:') != 0) {
                return true;
              }
            }
            return false;
        }

        public override function isUneditedTiger():Boolean {
            return false;
        }

        public override function getTag(key:String):String {
			return getMergedTags()[key];
        }

		public override function tagIs(key:String,value:String):Boolean {
			if (!getMergedTags[key]) { return false; }
			return getMergedTags[key]==value;
		}
		
		public override function setTag(key:String, value:String, performAction:Function):void {
			var oldValue:String = getMergedTags()[key];	
			var undoAction:CompositeUndoableAction = new CompositeUndoableAction("set_tag_entity_collection");
			for each (var entity:Entity in _entities) {
				undoAction.push(new SetTagAction(entity, key, value));
			}
            performAction(undoAction);
        }

        public override function renameTag(oldKey:String, newKey:String, performAction:Function):void {
			var undoAction:CompositeUndoableAction = new CompositeUndoableAction("rename_tag_entity_collection");
			for each (var entity:Entity in _entities) {
				undoAction.push(new SetTagKeyAction(entity, oldKey, newKey));
			}
            performAction(undoAction);
        }

        public override function getTagList():TagList {
            return new TagList(getMergedTags());
        }

        public override function getTagsCopy():Object {
			return getMergedTags();
        }

		public override function getTagsHash():Object {
			return getMergedTags();
		}

        public override function getTagArray():Array {
            var copy:Array = [];
			var mergedTags:Object = getMergedTags();
            for (var key:String in mergedTags) {
                copy.push(new Tag(this, key, mergedTags[key]));
			}
            return copy;
        }

		public override function get parentRelations():Array {
			var relations:Array = [];
			for each (var entity:Entity in _entities) {
				for each (var relation:Relation in entity.parentRelations) {
					if (relations.indexOf(relation)==-1) relations.push(relation);
				}
			}
			return relations;
		}

		public override function getRelationMemberships():Array {
			var relations:Object = {};
			for each (var entity:Entity in _entities) {
				for each (var rel:Relation in entity.parentRelations) {
					for each(var memberIndex:int in rel.findEntityMemberIndexes(entity)) {
						var role:String=rel.getMember(memberIndex).role;
						if (!relations[rel.id]) {
							relations[rel.id]= { role: role, relation: rel, distinctCount: 0};
						} else if (relations[rel.id].role!=role) {
							relations[rel.id].role="<different>";
						}
					}
					relations[rel.id].distinctCount++;
				}
			}
			var memberships:Array = [];
			for (var id:String in relations) {
				memberships.push({
					relation: relations[id].relation,
					id: Number(id),
					role: relations[id].role,
					description: relations[id].relation.getDescription(),
					universal: relations[id].distinctCount==_entities.length,
					id_idx: id });
			}
			return memberships;
			// ** FIXME: .universal should be shown in the tag panel
		}

		// Clean/dirty methods

        public override function get isDirty():Boolean {
            for each (var entity:Entity in _entities) {
				if(entity.isDirty) return true;
			}
			return false;
        }

        public override function markClean():void {
             for each (var entity:Entity in _entities) {
				entity.markClean();
			}
        }

        internal override function markDirty():void {
            for each (var entity:Entity in _entities) {
				entity.markDirty();
			}
        }
	
	
		// Others
	
		public override function getDescription():String {
			var basic:String=this.getType();
			var mergedTags:Object = getMergedTags();
			if (mergedTags['ref'] && mergedTags['name']) { return mergedTags['ref']+' '+mergedTags['name']+' ('+basic+')'; }
			if (mergedTags['ref']) { return mergedTags['ref']+' ('+basic+')'; }
			if (mergedTags['name']) { return mergedTags['name']+' ('+basic+')'; }
			return basic;
		}

        public override function getType():String {
			var entityType:String = '';
			 for each (var entity:Entity in _entities) {
				if(entityType == '') entityType = entity.getType();
				else if(entityType != entity.getType()) {
					entityType = '';
					break;
				}
			}
            return entityType;
        }

    }

}

