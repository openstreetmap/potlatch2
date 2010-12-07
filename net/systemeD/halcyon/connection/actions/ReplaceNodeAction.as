package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    public class ReplaceNodeAction extends CompositeUndoableAction {

        private var node:Node;
        private var replacement:Node;

        /**
        * @param node The node we're getting rid of
        * @param replacement The node we want to end up with
        */
        public function ReplaceNodeAction(node:Node, replacement:Node) {
            super("Replace node "+node+" with "+replacement);
            this.node = node;
            this.replacement = replacement;
        }

        public override function doAction():uint {

            for each (var way:Way in node.parentWays) {
              for (var x:uint=0; x<way.length; x++) {
                if (way.getNode(x) == node) {
                  way.removeNodeByIndex(x, push);
                  way.insertNode(x, replacement, push);
                }
              }
            }

            for each (var relation:Relation in node.parentRelations) {
              for (var y:uint=0; y<relation.length; y++) {
                var member:RelationMember = relation.getMember(y);
                if (member.entity == node) {
                  relation.removeMemberByIndex(y, push);
                  relation.insertMember(y, new RelationMember(replacement, member.role), push);
                }
              }
            }

            node.remove(push);

            return super.doAction();
        }

        public override function undoAction():uint {
            return super.undoAction();
        }
    }
}

