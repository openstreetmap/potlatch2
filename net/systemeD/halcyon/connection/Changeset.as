package net.systemeD.halcyon.connection {

    public class Changeset extends Entity {
		public static var entity_type:String = 'changeset';

        public function Changeset(connection:Connection, id:Number, tags:Object) {
            super(connection, id, 0, tags, true, NaN, null, null);
        }

        public override function toString():String {
            return "Changeset("+id+"): "+getTagList();
        }

		public override function getType():String {
			return 'changeset';
		}

		public function get comment():String {
			var t:Object=getTagsHash();
			var s:String=t['comment'] ? t['comment'] : '';
			if (t['source']) { s+=" ["+t['source']+"]"; }
			return s;
		}
    }

}
