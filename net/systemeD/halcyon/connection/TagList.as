package net.systemeD.halcyon.connection {

    public class TagList {
        private var keys:Array = [];
        private var tags:Object;

        public function TagList(tags:Object) {
            this.tags = tags;
            for (var key:String in tags) {
                keys.push(key);
            }
        }

        public function get length():uint {
            return keys.length;
        }

        public function getTagKey(index:uint):String {
            return keys[index];
        }

        public function getTagValue(index:uint):String {
            return tags[keys[index]];
        }

        public function toString():String {
            var str:String = "{";
            for (var i:uint = 0; i < length; i++)
                str += "\""+getTagKey(i) + "=" + getTagValue(i) + "\",";
            return str+"}";
        }
    }

}
