package net.systemeD.halcyon.connection {

	import net.systemeD.halcyon.connection.actions.*;

    public class Relation extends Entity {
        private var members:Array;
		public static var entity_type:String = 'relation';

        public function Relation(id:Number, version:uint, tags:Object, loaded:Boolean, members:Array, uid:Number = NaN, timestamp:String = null) {
            super(id, version, tags, loaded, uid, timestamp);
            this.members = members;
			for each (var member:RelationMember in members)
			    member.entity.addParent(this);
        }

        public function update(version:uint, tags:Object, loaded:Boolean, members:Array, uid:Number = NaN, timestamp:String = null):void {
			var member:RelationMember;
			for each (member in this.members)
			    member.entity.removeParent(this);

			updateEntityProperties(version,tags,loaded,uid,timestamp);
			this.members=members;
			for each (member in members)
			    member.entity.addParent(this);
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

        public function findEntityMemberIndexes(entity:Entity):Array {
            var indexes:Array = [];
            for (var index:uint = 0; index < members.length; index++) {
                var member:RelationMember = members[index];
                if ( member.entity == entity )
                    indexes.push(index);
            }
            return indexes;
        }
        
        public function getMember(index:uint):RelationMember {
            return members[index];
        }

        public function setMember(index:uint, member:RelationMember):void {
            var oldMember:RelationMember = getMember(index);
            
			members.splice(index, 1, member);
            oldMember.entity.removeParent(this);
 			member.entity.addParent(this);
			markDirty();
        }

		public function findMembersByRole(role:String):Array {
			var a:Array=[];
            for (var index:uint = 0; index < members.length; index++) {
                if (members[index].role==role) { a.push(members[index].entity); }
            }
			return a;
		}

		public function hasMemberInRole(entity:Entity,role:String):Boolean {
            for (var index:uint = 0; index < members.length; index++) {
				if (members[index].role==role && members[index].entity == entity) { return true; }
			}
			return false;
		}
		
        public function insertMember(index:uint, member:RelationMember, performAction:Function):void {
            performAction(new AddMemberToRelationAction(this, index, member, members));
        }

        public function appendMember(member:RelationMember, performAction:Function):uint {
            performAction(new AddMemberToRelationAction(this, -1, member, members));
            return members.length + 1;
        }

		public function removeMember(entity:Entity, performAction:Function):void {
			performAction(new RemoveEntityFromRelationAction(this, entity, members));
		}

        public function removeMemberByIndex(index:uint, performAction:Function):void {
            performAction(new RemoveMemberByIndexAction(this, members, index));
        }

		public override function remove(performAction:Function):void {
			performAction(new DeleteRelationAction(this, setDeletedState, members));
		}

		public override function nullify():void {
			nullifyEntity();
			members=[];
		}
		
		internal override function isEmpty():Boolean {
			return (deleted || (members.length==0));
		}

        public override function getDescription():String {
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
