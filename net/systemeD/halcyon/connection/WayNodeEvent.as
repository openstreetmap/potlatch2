package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class WayNodeEvent extends EntityEvent {
        private var _way:Way;
        private var _index:uint;

        public function WayNodeEvent(type:String, node:Node, way:Way, index:uint) {
            super(type, node);
            this._way = way;
            this._index = index;
        }

        public function get way():Way { return _way; }
        public function get node():Node { return entity as Node; }
        public function get index():uint { return _index; }

        public override function toString():String {
            return super.toString() + " in "+_way+" at "+_index;
        }
    }

}

