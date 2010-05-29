package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class AddMemberToRelationAction extends UndoableEntityAction {
        private var rel:Relation;
        private var index:uint;
        private var member:RelationMember;
        private var memberList:Array;
        
        public function AddMemberToRelationAction(rel:Relation, index:uint, member:RelationMember, memberList:Array) {
            super(rel, "Add " + member.entity.getType() + " " + member.entity.id + " at position " + index + " to ");
            this.rel = rel;
            this.index = index;
            this.member = member;
            this.memberList = memberList;
        }
        
        public override function doAction():uint {
            memberList.splice(index, 0, member);
            member.entity.addParent(rel);
            markDirty();
            rel.dispatchEvent(new RelationMemberEvent(Connection.RELATION_MEMBER_ADDED, member.entity, rel, index));
            
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            memberList.splice(index, 1);
            member.entity.removeParent(rel);
            markClean();
            rel.dispatchEvent(new RelationMemberEvent(Connection.RELATION_MEMBER_REMOVED, member.entity, rel, index));
            
            return SUCCESS;
        }
    }
}