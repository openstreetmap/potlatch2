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
              // FIXME make this reversible
              // FIXME needs to copy roles as well
              // FIXME needs to insert the new way in the correct position in 
              //        the relation, in order to not destroy ordered route relations.
              //        This will either be before, or after, the selectedWay, depending
              //        on the relative sequence of the relation members compared to the 
              //        direction of selectedWay.
              for each (var r:Relation in selectedWay.parentRelations) {
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