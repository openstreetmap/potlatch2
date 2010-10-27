package net.systemeD.halcyon.connection {

    public class Changeset extends Entity {
		public static var entity_type:String = 'changeset';

        public function Changeset(id:Number, tags:Object) {
            super(id, 0, tags, true, NaN, '');
        }

        public override function toString():String {
            return "Changeset("+id+"): "+getTagList();
        }

		public override function getType():String {
			return 'changeset';
		}
    }

}
