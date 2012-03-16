package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class TagEvent extends EntityEvent {
        private var _key:String;
        private var _oldKey:String;
        private var _oldValue:String;
        private var _newValue:String;

        public function TagEvent(type:String, item:Entity, oldKey:String, newKey:String, oldValue:String, newValue:String) {
            super(type, item);
            this._key = newKey;
            this._oldKey = oldKey;
            this._oldValue = oldValue;
            this._newValue = newValue;
        }

        public function get key():String { return _key; }
        public function get oldKey():String { return _oldKey; }
        public function get oldValue():String { return _oldValue; }
        public function get newValue():String { return _newValue; }

        public override function toString():String {
            return super.toString() + "::'"+_oldKey+"' '"+_key +"' '"+_oldValue+"' '"+_newValue+"' ["+item+"]";
        }
    }

}

