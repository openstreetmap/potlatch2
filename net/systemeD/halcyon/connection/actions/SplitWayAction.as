package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
    
    public class SplitWayAction extends CompositeUndoableAction {
    
        private var selectedWay:Way;
        private var selectedNode:Node;
        private var newWay:Way;
    
        public function SplitWayAction(selectedWay:Way, selectedNode:Node) {
            super("Split way "+selectedWay.id);
            this.selectedWay = selectedWay;
            this.selectedNode = selectedNode;
        }
    
        public override function doAction():uint {
            if (newWay==null) {
				newWay = Connection.getConnection().createWay(
					selectedWay.getTagsCopy(), 
					selectedWay.sliceNodes(selectedWay.indexOfNode(selectedNode),selectedWay.length),
					push);

				selectedWay.deleteNodesFrom(selectedWay.indexOfNode(selectedNode)+1, push);

				// copy relations
				// FIXME make this reversible
				// FIXME should be more clever about the position (for ordered relations).
				//        It should either be before, or after, the selectedWay, depending
				//        on the relative sequence of the relation members compared to the 
				//        direction of selectedWay.
				// FIXME if we insert twice into the same relation, the position may become
				//        boggled (i.e. "10th position" is no longer valid if we previously
				//        inserted something earlier).
				for each (var o:Object in selectedWay.memberships) {
					o.relation.insertMember(o.position, new RelationMember(newWay, o.role));
				}
            }
            newWay.suspend();
            selectedWay.suspend();
            super.doAction();
            newWay.resume();
            selectedWay.resume();
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            selectedWay.suspend();
            newWay.suspend();
            
            super.undoAction();
            
            newWay.resume();
            selectedWay.resume();
            return SUCCESS;
        }
    }

}