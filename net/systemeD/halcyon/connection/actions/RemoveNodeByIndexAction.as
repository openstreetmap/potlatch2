package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class RemoveNodeByIndexAction extends UndoableEntityAction {
    
        private var way:Way;
        private var nodeList:Array;
        private var index:uint;
        private var removed:Array;
        private var fireEvent:Boolean;
    
        public function RemoveNodeByIndexAction(way:Way, nodeList:Array, index:uint, fireEvent:Boolean=true) {
            super(way, "Remove node " + nodeList[index].id + " from position " + index);
            this.way = way;
            this.nodeList = nodeList;
            this.index = index;
            this.fireEvent = fireEvent;
        }
        
        public override function doAction():uint {
            removed = nodeList.splice(index, 1);
            if (nodeList.indexOf(removed[0])==-1) { removed[0].removeParent(way); }
            markDirty();
            if (fireEvent) {
               entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, removed[0], way, index));
            }
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            nodeList.splice(index, 0, removed[0]);
            removed[0].addParent(way);
            markClean();
            if (fireEvent) {
                entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, removed[0], way, index));
            }
            return SUCCESS;
        }
    }
}