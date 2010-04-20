package net.systemeD.halcyon.connection {

    public class Tag {
        private var entity:Entity;
        private var _key:String;
        private var _value:String;

        public function Tag(entity:Entity, key:String, value:String) {
            this.entity = entity;
            entity.addEventListener(Connection.TAG_CHANGED, tagChanged, false, 0, true);
            this._key = key;
            this._value = value;
        }

        public function get key():String { return _key; }
        public function get value():String { return _value; }

        public function set key(key:String):void {
            var oldKey:String = _key;
            var realVal:String = entity.getTag(oldKey);
            _key = key;
            if ( oldKey != null && realVal != null && realVal != "" )
                entity.renameTag(oldKey, key, MainUndoStack.getGlobalStack().addAction);
        }

        public function set value(value:String):void {
            entity.setTag(_key, value, MainUndoStack.getGlobalStack().addAction);
        }

        private function tagChanged(event:TagEvent):void {
            if ( event.key == _key )
                _value = event.newValue;
        }
    }


}

