package net.systemeD.halcyon.connection {

    public class Relation extends Entity {
        private var members:Array;

        public function Relation(id:Number, version:uint, tags:Object, members:Array) {
            super(id, version, tags);
            this.members = members;
        }

        public function get length():uint {
            return members.length;
        }

        public function getMember(index:uint):RelationMember {
            return members[index];
        }

        public function setMember(index:uint, member:RelationMember):void {
            members.splice(index, 1, member);
        }

        public function insertMember(index:uint, member:RelationMember):void {
            members.splice(index, 0, member);
        }

        public function appendMember(member:RelationMember):uint {
            members.push(member);
            return members.length;
        }

        public function removeMember(index:uint):void {
            members.splice(index, 1);
        }
    }

}
