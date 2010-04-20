package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class SetTagKeyAction extends UndoableEntityAction {
        private var oldKey:String;
        private var newKey:String;
        
        public function SetTagKeyAction(entity:Entity, oldKey:String, newKey:String) {
            super(entity, "Rename tag "+oldKey+"->"+newKey);
            this.oldKey = oldKey;
            this.newKey = newKey;
        }
            
        public override function doAction():uint {
            var tags:Object = entity.getTagsHash();
            var value:String = tags[oldKey];
            if ( oldKey != newKey ) {
                delete tags[oldKey];
                tags[newKey] = value;
                markDirty();
                entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, oldKey, newKey, value, value));
                return SUCCESS;
            } else {
                return NO_CHANGE;
            }
        }
            
        public override function undoAction():uint {
            var tags:Object = entity.getTagsHash();
            var value:String = tags[newKey];
            delete tags[newKey];
            tags[oldKey] = value;
            markClean();
            entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, newKey, oldKey, value, value));
            
            return SUCCESS;
        }
    }
}

