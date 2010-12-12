package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    /** An UndoableEntityAction corresponding to the setting of a single tag and value. */
    public class SetTagAction extends UndoableEntityAction {
        private var oldValue:String;
        private var key:String;
        private var value:String;

        public function SetTagAction(entity:Entity, key:String, value:String) {
            super(entity, "Set "+key+"="+value);
            this.key = key;
            this.value = value;
        }

        public override function doAction():uint {
            var tags:Object = entity.getTagsHash();
            oldValue = tags[key];
            if ( oldValue != value ) {
                if ( value == null || value == "" )
                    delete tags[key];
                else
                    tags[key] = value;
                markDirty();
                entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, key, key, oldValue, value));
                return SUCCESS;
            } else {
                return NO_CHANGE;
            }
        }

        public override function undoAction():uint {
            var tags:Object = entity.getTagsHash();
            if ( oldValue == null || oldValue == "" )
                delete tags[key];
            else
                tags[key] = oldValue;
            markClean();
            entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, key, key, value, oldValue));

            return SUCCESS;
        }

        public override function mergePrevious(prev:UndoableAction):Boolean {
            if ( !(prev is SetTagAction) )
                return false;

            var prevSet:SetTagAction = prev as SetTagAction;
            if ( prevSet.entity == entity && prevSet.key == key ) {
                oldValue = prevSet.oldValue;
                return true;
            }
            return false;
        }
    }
}

