package net.systemeD.halcyon.connection {

    public class Relation extends Entity {
        private var members:Array;
		public static var entity_type:String = 'relation';

        public function Relation(id:Number, version:uint, tags:Object, members:Array) {
            super(id, version, tags);
            this.members = members;
			for each (var member:RelationMember in members) { member.entity.addParent(this); }
        }

        public function get length():uint {
            return members.length;
        }

        public function getMember(index:uint):RelationMember {
            return members[index];
        }

        public function setMember(index:uint, member:RelationMember):void {
 			member.entity.addParent(this);
			members.splice(index, 1, member);
        }

        public function insertMember(index:uint, member:RelationMember):void {
 			member.entity.addParent(this);
            members.splice(index, 0, member);
        }

        public function appendMember(member:RelationMember):uint {
 			member.entity.addParent(this);
            members.push(member);
            return members.length;
        }

        public function removeMember(index:uint):void {
            var removed:Array=members.splice(index, 1);
			removed[0].entity.removeParent(this);
        }

		public override function getType():String {
			return 'relation';
		}
    }

}
