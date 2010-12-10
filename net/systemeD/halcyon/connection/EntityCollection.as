package net.systemeD.halcyon.connection {

	import flash.events.TimerEvent;
	import flash.utils.Timer;
    
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;

    public class EntityCollection extends Entity {
		private var entities:Array;
		private var tagChangedTimer:Timer;
		private var delayedEvent:TagEvent;

        public function EntityCollection(entities:Array) {
			super(-1, 0, {}, true, -1, "");
            this.entities = entities;
			
			//To avoid firing on every contained entity, we wait some short time before firing the tag changed event
			tagChangedTimer = new Timer(50, 1);
			tagChangedTimer.addEventListener(TimerEvent.TIMER, onTagChangedTimerFinished);			
			for each(var entity:Entity in entities) {
				entity.addEventListener(Connection.TAG_CHANGED, onTagChanged);	
			}
        }
		
		private function onTagChanged(event:TagEvent):void {
			if(tagChangedTimer.running) return;
			delayedEvent = new TagEvent(Connection.TAG_CHANGED, this, event.key, event.key, event.oldValue, event.newValue)
			tagChangedTimer.start();
		}
		
		private function onTagChangedTimerFinished(event:TimerEvent): void {
			dispatchEvent(delayedEvent);
		}
		
		
		// Tag-handling methods
		
		private function getMergedTags():Object {
			//Builds an object with tags of all entities in this collection. If the value of a tag differs or is not set in all entities, value is marked
			var differentMarker:String = "<different>";
			var mergedTags:Object = entities[0].getTagsCopy();
			for each(var entity:Entity in entities) {
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
			for each (var entity:Entity in entities) {
				undoAction.push(new SetTagAction(entity, key, value));
			}
            performAction(undoAction);
        }

        public override function renameTag(oldKey:String, newKey:String, performAction:Function):void {
			var undoAction:CompositeUndoableAction = new CompositeUndoableAction("rename_tag_entity_collection");
			for each (var entity:Entity in entities) {
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

		// Clean/dirty methods

        public override function get isDirty():Boolean {
            for each (var entity:Entity in entities) {
				if(entity.isDirty) return true;
			}
			return false;
        }

        public override function markClean():void {
             for each (var entity:Entity in entities) {
				entity.markClean();
			}
        }

        internal override function markDirty():void {
            for each (var entity:Entity in entities) {
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
			 for each (var entity:Entity in entities) {
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

