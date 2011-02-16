package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class AddNodeToWayAction extends UndoableEntityAction {
        private var node:Node;
        private var nodeList:Array;
        private var index:int;
        
        public function AddNodeToWayAction(way:Way, node:Node, nodeList:Array, index:int) {
            super(way, "Add node "+node.id+" to");
            this.node = node;
            this.nodeList = nodeList;
            this.index = index;
        }
            
        public override function doAction():uint {
            var way:Way = entity as Way;
            if ( index == -1 )
                index = nodeList.length;
            node.addParent(way);
            nodeList.splice(index, 0, node);
            markDirty();
			way.expandBbox(node);
            way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, way, index));
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            var way:Way = entity as Way;
            var removed:Array=nodeList.splice(index, 1);
			if (nodeList.indexOf(removed[0])==-1) { removed[0].removeParent(way); }
			markClean();
            way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, removed[0], way, index));
            
            return SUCCESS;
        }
    }
}

