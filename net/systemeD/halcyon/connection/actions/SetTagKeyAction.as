package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class SetTagKeyAction extends UndoableEntityAction {
        private var oldKey:String;
        private var newKey:String;
        private var oldValue:String;
        
        public function SetTagKeyAction(entity:Entity, oldKey:String, newKey:String) {
            super(entity, "Rename tag "+oldKey+"->"+newKey);
            this.oldKey = oldKey;
            this.newKey = newKey;
        }
            
        public override function doAction():uint {
            var tags:Object = entity.getTagsHash();
            oldValue = tags[oldKey];
            var newValue:String;
            if ( oldKey != newKey ) {
                delete tags[oldKey];
                if (newKey=='') {
                    newValue = null;
                } else {
                    tags[newKey] = oldValue;
                    newValue = oldValue;
				} 
                markDirty();
                entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, oldKey, newKey, oldValue, newValue));
                return SUCCESS;
            } else {
                return NO_CHANGE;
            }
        }
            
        public override function undoAction():uint {
            var tags:Object = entity.getTagsHash();
            delete tags[newKey];
            tags[oldKey] = oldValue;
            markClean();
            entity.dispatchEvent(new TagEvent(Connection.TAG_CHANGED, entity, newKey, oldKey, oldValue, oldValue));
            
            return SUCCESS;
        }
    }
}

