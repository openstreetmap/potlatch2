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
			var i:int, node2:Node;
			while ((i=nodeList.indexOf(node))>-1) {
				// remove the node from the way
				nodeList.splice(i,1);
				nodeRemovedFrom.push([node,i]);
				entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node, Way(entity), i));

				// remove any repeated nodes that have occurred as a result (i.e. removing B from ABA)
				while (i>0 && nodeList[i-1]==nodeList[i]) {
					node2=nodeList.splice(i,1)[0];
					nodeRemovedFrom.push([node2,i]);
					entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node2, Way(entity), i));
				}
			}
			
			if ( nodeRemovedFrom.length > 0 ) {
			    node.removeParent(entity);
			    entity.deleted = nodeList.length <= 1;
			    markDirty();
			    return SUCCESS;
			}
            
            return NO_CHANGE;
        }
            
        public override function undoAction():uint {
            node.addParent(entity);
            
            for (var i:int = nodeRemovedFrom.length - 1; i >= 0; i--) {
                var removal:Array = nodeRemovedFrom[i];
                var reinstate:Node = removal[0];
                var index:int = removal[1];
                nodeList.splice(index, 0, reinstate);
                entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, reinstate, Way(entity), index));
            }
            
            entity.deleted = nodeList.length == 0;
            markClean();
            
            return SUCCESS;
        }
    }
}

