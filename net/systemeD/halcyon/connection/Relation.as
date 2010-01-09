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
			markDirty();
        }

        public function insertMember(index:uint, member:RelationMember):void {
 			member.entity.addParent(this);
            members.splice(index, 0, member);
			markDirty();
        }

        public function appendMember(member:RelationMember):uint {
 			member.entity.addParent(this);
            members.push(member);
			markDirty();
            return members.length;
        }

		public function removeMember(entity:Entity):void {
			var i:int;
			while ((i=findEntityMemberIndex(entity))>-1) {
				members.splice(i, 1);
			}
			entity.removeParent(this);
			markDirty();
		}

        public function removeMemberByIndex(index:uint):void {
            var removed:Array=members.splice(index, 1);
			var entity:Entity=removed[0].entity;
			if (findEntityMemberIndex(entity)==-1) { entity.removeParent(this); }
			markDirty();
        }

		public override function remove():void {
			removeFromParents();
			for each (var member:RelationMember in members) { member.entity.removeParent(this); }
			members=[];
			deleted=true;
            dispatchEvent(new EntityEvent(Connection.RELATION_DELETED, this));
		}

		internal override function isEmpty():Boolean {
			return (deleted || (members.length==0));
		}

        public function getDescription():String {
            var desc:String = "";
            var relTags:Object = getTagsHash();
            if ( relTags["type"] ) {
                desc = relTags["type"];
                if ( relTags[desc] )
                    desc += " " + relTags[desc];
            }
            if ( relTags["ref"] )
                desc += " " + relTags["ref"];
            if ( relTags["name"] )
                desc += " " + relTags["name"];
            return desc;
        }

		public override function getType():String {
			return 'relation';
		}
		
		public override function toString():String {
            return "Relation("+id+"@"+version+"): "+members.length+" members "+getTagList();
        }

    }

}
