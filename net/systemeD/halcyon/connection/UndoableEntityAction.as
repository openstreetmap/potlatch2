package net.systemeD.halcyon.connection {

    public class UndoableEntityAction extends UndoableAction {
        public var wasDirty:Boolean;
		public var connectionWasDirty:Boolean;
        private var initialised:Boolean = false;
        protected var name:String;
        protected var entity:Entity;
            
        public function UndoableEntityAction(entity:Entity, name:String) {
            this.entity = entity;
            this.name = name;
        }
            
        protected function markDirty():void {
            if ( !initialised ) init();

            if ( !wasDirty ) {
              entity.markDirty();
            }

            if ( !connectionWasDirty ) {
              Connection.getConnectionInstance().markDirty();
            }
        }
            
        protected function markClean():void {
            if ( !initialised ) init();

            if ( !wasDirty ) {
              entity.markClean();
            }

            if ( !connectionWasDirty ) {
              Connection.getConnectionInstance().markClean();
            }
        }
        
        private function init():void {
            wasDirty = entity.isDirty;
            connectionWasDirty = Connection.getConnectionInstance().isDirty;
            initialised = true;
        }
            
        public function toString():String {
            return name + " " + entity.getType() + " " + entity.id;
        }
    }
}

