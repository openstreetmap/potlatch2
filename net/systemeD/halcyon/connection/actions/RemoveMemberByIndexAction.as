package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    public class RemoveMemberByIndexAction extends UndoableEntityAction {

        private var relation:Relation;
        private var members:Array;
        private var index:uint;
        private var removed:Array;
        private var fireEvent:Boolean;

        public function RemoveMemberByIndexAction(relation:Relation, members:Array, index:uint, fireEvent:Boolean = true) {
            super(relation, "Remove member at index "+index+" from "+relation);
            this.relation = relation;
            this.members = members;
            this.index = index;
            this.fireEvent = fireEvent;
        }

        public override function doAction():uint {
            removed = members.splice(index,1);
            var e:Entity = removed[0].entity;

            if (relation.findEntityMemberIndex(e)==-1)
                e.removeParent(relation);

            markDirty();
            if (fireEvent) {
              relation.dispatchEvent(new RelationMemberEvent(Connection.RELATION_MEMBER_REMOVED, e, relation, index));
            }

            return SUCCESS;
        }

        public override function undoAction():uint {
            members.splice(index, 0, removed[0]);
            var e:Entity = removed[0].entity;
            e.addParent(relation);

            markClean();
            if (fireEvent) {
              relation.dispatchEvent(new RelationMemberEvent(Connection.RELATION_MEMBER_ADDED, e, relation, index));
            }

            return SUCCESS;
        }

    }

}