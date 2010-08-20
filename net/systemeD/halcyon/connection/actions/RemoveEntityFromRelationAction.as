package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class RemoveEntityFromRelationAction extends UndoableEntityAction {
        private var member:Entity;
        private var memberList:Array;
        private var memberRemovedFrom:Array;
        private var removedMembers:Array;
        
        public function RemoveEntityFromRelationAction(rel:Relation, member:Entity, memberList:Array) {
            super(rel, "Remove "+member.getType()+" "+member.id+" from ");
            this.member = member;
            this.memberList = memberList;
        }
            
        public override function doAction():uint {
            memberRemovedFrom = [];
            removedMembers = [];
            
            var rel:Relation = entity as Relation;
			var i:int;
			while ((i=rel.findEntityMemberIndex(member))>-1) {
				var removed:RelationMember = memberList.splice(i, 1)[0];
				memberRemovedFrom.push(i);
				removedMembers.push(removed);
			}
			
			if ( removedMembers.length > 0 ) {
			    member.removeParent(rel);
			    markDirty();
			    rel.dispatchEvent(new RelationMemberEvent(
			        Connection.RELATION_MEMBER_REMOVED, member, rel, memberRemovedFrom[0]));
			    return SUCCESS;
			}
            
            return NO_CHANGE;
        }
            
        public override function undoAction():uint {
            member.addParent(entity);
            
            var last:int = 0;
            for (var i:int = removedMembers.length - 1; i >= 0; i--) {
                var removed:RelationMember = removedMembers[i];
                var index:int = memberRemovedFrom[i];
                memberList.splice(index, 0, removed);
                last = index;
            }

            markClean();
            
			entity.dispatchEvent(new RelationMemberEvent(
			        Connection.RELATION_MEMBER_ADDED, member, Relation(entity), memberRemovedFrom[0]));
            
            return SUCCESS;
        }
    }
}

