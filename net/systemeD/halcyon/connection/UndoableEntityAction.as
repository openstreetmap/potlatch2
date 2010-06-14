package net.systemeD.halcyon.connection {

    public class UndoableEntityAction extends UndoableAction {
        public var wasDirty:Boolean;
		public var connectionWasDirty:Boolean;
        protected var name:String;
        protected var entity:Entity;
            
        public function UndoableEntityAction(entity:Entity, name:String) {
            this.entity = entity;
            this.name = name;
        }
            
        protected function markDirty():void {
			var conn:Connection = Connection.getConnectionInstance();
            wasDirty = entity.isDirty;
			connectionWasDirty = conn.isDirty;

            if ( !wasDirty )
                entity.markDirty();

            if ( !connectionWasDirty )
                conn.markDirty();
        }
            
        protected function markClean():void {
            if ( !wasDirty )
                entity.markClean(entity.id, entity.version);

            if ( !connectionWasDirty )
                Connection.getConnectionInstance().markClean();
        }
            
        public function toString():String {
            return name + " " + entity.getType() + " " + entity.id;
        }
    }
}

