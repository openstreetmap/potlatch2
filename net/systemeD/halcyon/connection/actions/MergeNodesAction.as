package net.systemeD.halcyon.connection.actions
{
	import net.systemeD.halcyon.connection.*;


	public class MergeNodesAction extends CompositeUndoableAction {
        // Node2's tags are merged into node1, then node2 is deleted.       
        private var node1:Node;
        private var node2:Node;
        static public var lastProblemTags:Array;
    
        public function MergeNodesAction(destnode:Node, sourcenode:Node) {
            super("Merge nodes "+destnode.id+" "+sourcenode.id);
            this.node1 = destnode;
            this.node2 = sourcenode;
            lastProblemTags=null;
        }
        
        public override function doAction():uint {

            super.clearActions();
            node1.suspend();

//            mergeRelations(); TODO
            lastProblemTags= node1.mergeTags(node2,push); // TODO use to warn user
            node2.replaceWith(node1, push);
            node2.remove(push);

            super.doAction();
            node1.resume();
            
            return SUCCESS;
        }

        public override function undoAction():uint {
            node1.suspend();
            super.undoAction();
            node1.resume();
            
            return SUCCESS;
        }
        
        public function mergeRelations():void {
            for each (var r:Relation in node2.parentRelations) {
                // ** needs to copy roles as well
                if (r.findEntityMemberIndex(node1)==-1) {
                    r.appendMember(new RelationMember(node1, ''), push);
                }
            }
        }
    }

}