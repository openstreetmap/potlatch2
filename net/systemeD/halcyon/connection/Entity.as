package net.systemeD.halcyon.connection {

    public class Entity {
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
            tags[key] = value;
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

    }

}
