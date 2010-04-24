package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class ReverseNodesAction extends UndoableEntityAction {
    
        private var nodeList:Array;
    
        public function ReverseNodesAction(way:Way, nodeList:Array) {
            super(way, "Reverse");
            this.nodeList = nodeList;
        }
        
        public override function doAction():uint {
            nodeList.reverse();
            markDirty();
            entity.dispatchEvent(new EntityEvent(Connection.WAY_REORDERED, entity));
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            nodeList.reverse();
            markClean();
            entity.dispatchEvent(new EntityEvent(Connection.WAY_REORDERED, entity));
            return SUCCESS;
        }
    }
}