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
            var arr:Array = [];
            for (var i:uint = 0; i < length; i++)
                arr.push(getTagKey(i) + "=" + getTagValue(i));
            return arr.join('; ');
        }

		public static function fromString(str:String):Object {
			var kv:Object={};
			var arr:Array=str.split('; ');
			for (var i:uint = 0; i < arr.length; i++)
				kv[arr[i].split('=')[0]] = arr[i].split('=')[1];
			return kv;
		}
    }
}
