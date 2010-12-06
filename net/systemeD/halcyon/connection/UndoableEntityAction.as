package net.systemeD.halcyon.connection {

    /**
    * An UndoableEntityAction is an action that affects an entity. The allows the clean/dirty status of both the individual entity and
    * the connection as a whole to be tracked correctly when doing an action, undoing it and redoing it.
    *
    * Individual entity actions extend this class in order to do useful things.
    */

    public class UndoableEntityAction extends UndoableAction {
        public var wasDirty:Boolean;
		public var connectionWasDirty:Boolean;
        private var initialised:Boolean = false;
        protected var name:String;
        protected var entity:Entity;

        /**
        * Create a new UndoableEntityAction. Usually called as super() from a subclass
        *
        * @param entity The entity that it being modified
        * @param name The name of this action, useful for debugging.
        */
        public function UndoableEntityAction(entity:Entity, name:String) {
            this.entity = entity;
            this.name = name;
        }

        /**
        * Mark this action as dirty. This will mark the entity and/or connection dirty, as appropriate.
        */
        protected function markDirty():void {
            if ( !initialised ) init();

            if ( !wasDirty ) {
              entity.markDirty();
            }

            if ( !connectionWasDirty ) {
              Connection.getConnectionInstance().markDirty();
            }
        }

        /**
        * Mark this action as clean. This will entity and/or connection clean, as appropriate,
        * based on whether they were clean before this action started.
        */
        protected function markClean():void {
            if ( !initialised ) init();

            if ( !wasDirty ) {
              entity.markClean();
            }

            if ( !connectionWasDirty ) {
              Connection.getConnectionInstance().markClean();
            }
        }

        /**
        * Record whether or not the entity and connection were clean before this action started.
        * This allows the correct state to be restored when undo/redo is called
        */
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

