package net.systemeD.halcyon.connection {

    public class Relation extends Entity {
        private var members:Array;
		public static var entity_type:String = 'relation';

        public function Relation(id:Number, version:uint, tags:Object, loaded:Boolean, members:Array) {
            super(id, version, tags, loaded);
            this.members = members;
			for each (var member:RelationMember in members) { member.entity.addParent(this); }
        }

        public function update(version:uint, tags:Object, loaded:Boolean, members:Array):void {
			var member:RelationMember;
			for each (member in this.members) { member.entity.removeParent(this); }
			updateEntityProperties(version,tags,loaded); this.members=members;
			for each (member in members) { member.entity.addParent(this); }
		}
		
        public function get length():uint {
            return members.length;
        }

        public function findEntityMemberIndex(entity:Entity):int {
            for (var index:uint = 0; index < members.length; index++) {
                var member:RelationMember = members[index];
                if ( member.entity == entity )
                    return index;
            }
            return -1;
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
		
		public override function toString():String {
            return "Relation("+id+"@"+version+"): "+members.length+" members "+getTagList();
        }

    }

}
