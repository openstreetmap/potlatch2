package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class WayDraggedEvent extends EntityEvent {
        private var _way:Way;
		private var _xDelta:Number;
		private var _yDelta:Number;

        public function WayDraggedEvent(type:String, way:Way, xDelta:Number, yDelta:Number) {
            super(type, way);
            this._way = way;
            this._xDelta = xDelta;
            this._yDelta = yDelta;
        }

        public function get way():Way { return _way; }
        public function get xDelta():Number { return _xDelta; }
        public function get yDelta():Number { return _yDelta; }

        public override function toString():String {
            return super.toString() + " in "+_way+" by "+_xDelta+","+_yDelta;
        }
    }

}

