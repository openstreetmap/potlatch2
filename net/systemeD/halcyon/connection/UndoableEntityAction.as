package net.systemeD.halcyon.connection {

    public class UndoableEntityAction extends UndoableAction {
        private var wasDirty:Boolean;
        protected var name:String;
        protected var entity:Entity;
            
        public function UndoableEntityAction(entity:Entity, name:String) {
            this.entity = entity;
            this.name = name;
        }
            
        protected function markDirty():void {
            wasDirty = entity.isDirty;
            if ( !wasDirty )
                entity.markDirty();
        }
            
        protected function markClean():void {
            if ( !wasDirty )
                entity.markClean(entity.id, entity.version);
        }
            
        public function toString():String {
            return name + " " + entity.getType() + " " + entity.id;
        }
    }
}

