package net.systemeD.halcyon.connection {

    public class Changeset extends Entity {
		public static var entity_type:String = 'changeset';

        public function Changeset(connection:Connection, id:Number, tags:Object) {
            super(connection, id, 0, tags, true, NaN, '');
        }

        public override function toString():String {
            return "Changeset("+id+"): "+getTagList();
        }

		public override function getType():String {
			return 'changeset';
		}
    }

}
