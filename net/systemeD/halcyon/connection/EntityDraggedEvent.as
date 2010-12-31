package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class EntityDraggedEvent extends EntityEvent {
		private var _xDelta:Number;
		private var _yDelta:Number;

        public function EntityDraggedEvent(type:String, entity:Entity, xDelta:Number, yDelta:Number) {
            super(type, entity);
            this._xDelta = xDelta;
            this._yDelta = yDelta;
        }

        public function get xDelta():Number { return _xDelta; }
        public function get yDelta():Number { return _yDelta; }

        public override function toString():String {
            return super.toString() + " in "+item+" by "+_xDelta+","+_yDelta;
        }
    }

}
