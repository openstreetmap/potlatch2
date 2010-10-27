package net.systemeD.halcyon.connection {

    public class Changeset extends Entity {
        private var nodes:Array;
		public static var entity_type:String = 'changeset';

        public function Changeset(id:Number, tags:Object) {
            super(id, 0, tags, true, NaN, '');
        }

        public override function toString():String {
            return "Changeset("+id+"): "+getTagList();
        }

		public function isArea():Boolean {
			return (nodes[0].id==nodes[nodes.length-1].id  && nodes.length>2);
		}

		public override function getType():String {
			return 'changeset';
		}
    }

}
