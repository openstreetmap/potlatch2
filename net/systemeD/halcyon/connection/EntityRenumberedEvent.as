package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class EntityRenumberedEvent extends EntityEvent {
        private var _oldID:Number;

        public function EntityRenumberedEvent(type:String, item:Entity, oldID:Number) {
            super(type, item);
            this._oldID = oldID;
        }

        public function get oldID():Number { return _oldID; }
    }

}

