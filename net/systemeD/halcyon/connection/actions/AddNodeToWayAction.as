package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class AddNodeToWayAction extends UndoableEntityAction {
        private var node:Node;
        private var nodeList:Array;
        private var index:int;
        private var firstNode:Node;
        
        public function AddNodeToWayAction(way:Way, node:Node, nodeList:Array, index:int) {
            super(way, "Add node "+node.id+" to");
            this.node = node;
            this.nodeList = nodeList;
            this.index = index;
        }
            
        public override function doAction():uint {
            var way:Way = entity as Way;

			// undelete way if it was deleted before (only happens on redo)
			if (way.deleted) {
				way.setDeletedState(false);
				if (!firstNode.hasParentWays) firstNode.connection.unregisterPOI(firstNode);
				firstNode.addParent(way);
				way.connection.dispatchEvent(new EntityEvent(Connection.NEW_WAY, way));
			}

			// add node
            if ( index == -1 ) index = nodeList.length;
            node.addParent(way);
            nodeList.splice(index, 0, node);
            markDirty();
			way.expandBbox(node);
            way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, way, index));
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            var way:Way = entity as Way;

			// ** FIXME: if the user undoes adding the 2nd node, then we delete the way and create a POI from the
			//           one remaining node (see below). _However_, when we delete the way, we also need to remove 
			//           it from any relations... and to do that, this needs to be a CompositeUndoableAction.
			//           Which it isn't (because we want all the markDirty/markClean stuff). So, for now, we'll
			//           simply refuse to undo adding the 2nd node if the way is in any relations. (This should
			//           be a vanishingly small case anyway, because usually the AddMemberToRelationAction will
			//           have been undone already.)
			if (way.length==2 && way.parentRelations.length) return FAIL;

			// remove node
            var removed:Array=nodeList.splice(index, 1);
			if (nodeList.indexOf(removed[0])==-1) { removed[0].removeParent(way); }
			markClean();
            way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, removed[0], way, index));
            
			// delete way if it's now 1-length, and convert the one remaining node to a POI
			if (way.length==1) {
				way.setDeletedState(true);
				way.dispatchEvent(new EntityEvent(Connection.WAY_DELETED, way));
				firstNode=way.getNode(0);
				firstNode.removeParent(way);
				if (!firstNode.hasParentWays) firstNode.connection.registerPOI(firstNode);
				MainUndoStack.getGlobalStack().removeLastIfAction(BeginWayAction);
			}
			return SUCCESS;
        }
    }
}
