package net.systemeD.halcyon.connection {

    import flash.events.EventDispatcher;

    public class Entity extends EventDispatcher {
        private var _id:Number;
        private var _version:uint;
        private var tags:Object = {};

        public function Entity(id:Number, version:uint, tags:Object) {
            this._id = id;
            this._version = version;
            this.tags = tags;
        }

        public function get id():Number {
            return _id;
        }

        public function get version():uint {
            return _version;
        }

        public function hasTags():Boolean {
            for (var key:String in tags)
                return true;
            return false;
        }

        public function getTag(key:String):String {
            return tags[key];
        }

        public function setTag(key:String, value:String):void {
            var old:String = tags[key];
            if ( old != value ) {
                if ( value == null || value == "" )
                    delete tags[key];
                else
                    tags[key] = value;
                dispatchEvent(new TagEvent(Connection.TAG_CHANGE, this, key, key, old, value));
            }
        }

        public function renameTag(oldKey:String, newKey:String):void {
            var value:String = tags[oldKey];
            if ( oldKey != newKey ) {
                delete tags[oldKey];
                tags[newKey] = value;
                dispatchEvent(new TagEvent(Connection.TAG_CHANGE, this, oldKey, newKey, value, value));
            }
        }

        public function getTagList():TagList {
            return new TagList(tags);
        }

        public function getTagsCopy():Object {
            var copy:Object = {};
            for (var key:String in tags )
                copy[key] = tags[key];
            return copy;
        }

        public function getTagArray():Array {
            var copy:Array = [];
            for (var key:String in tags )
                copy.push(new Tag(this, key, tags[key]));
            return copy;
        }

    }

}
