package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
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
              // TODO make this reversible
              for each (var r:Relation in selectedWay.parentRelations) {
                  // ** needs to copy roles as well
                  r.appendMember(new RelationMember(newWay, ''));
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