package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class EntityEvent extends Event {
        private var item:Entity;

        public function EntityEvent(type:String, item:Entity) {
            super(type);
            this.item = item;
        }

        public function get entity():Entity {
            return item;
        }
    }

}
