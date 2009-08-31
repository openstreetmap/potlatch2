package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class NodeMovedEvent extends EntityEvent {
        private var _oldLat:Number;
        private var _oldLon:Number;

        public function NodeMovedEvent(type:String, item:Node, oldLat:Number, oldLon:Number) {
            super(type, item);
            this._oldLat = oldLat;
            this._oldLon = oldLon;
        }

        public function get oldLat():Number { return _oldLat; }
        public function get oldLon():Number { return _oldLon; }

        public override function toString():String {
            return super.toString() + "::from "+_oldLat+","+_oldLon;
        }
    }

}

