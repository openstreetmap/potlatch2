package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class RemoveNodeFromWayAction extends UndoableEntityAction {
        private var node:Node;
        private var nodeList:Array;
        private var nodeRemovedFrom:Array;
        
        public function RemoveNodeFromWayAction(way:Way, node:Node, nodeList:Array) {
            super(way, "Remove node "+node.id+" from ");
            this.node = node;
            this.nodeList = nodeList;
        }
            
        public override function doAction():uint {
            nodeRemovedFrom = [];
			var i:int;
			while ((i=nodeList.indexOf(node))>-1) {
				nodeList.splice(i,1);
				nodeRemovedFrom.push(i);
            	entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node, Way(entity), i));
			}
			
			if ( nodeRemovedFrom.length > 0 ) {
			    node.removeParent(entity);
			    markDirty();
			    return SUCCESS;
			}
            
            return NO_CHANGE;
        }
            
        public override function undoAction():uint {
            node.addParent(entity);
            
            for (var i:int = nodeRemovedFrom.length - 1; i >= 0; i--) {
                var index:int = nodeRemovedFrom[i];
                nodeList.splice(index, 0, node);
            	entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, Way(entity), index));
            }
            
            markClean();
            
            return SUCCESS;
        }
    }
}

