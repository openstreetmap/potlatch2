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
			var preceding:Node=(index>1) ? nodeList[index-1] : null;
			var node:Node=nodeList[index];
			removed=[];

			while (nodeList[index]==node || nodeList[index]==preceding) {
				var removedNode:Node=nodeList.splice(index, 1)[0];
				removed.push(removedNode);
				if (nodeList.indexOf(removedNode)==-1) { removedNode.removeParent(way); }
				if (fireEvent) {
				   entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, removedNode, way, index));
				}
			}
			way.deleted = nodeList.length == 0;
			markDirty();
			return SUCCESS;
		}
		
		public override function undoAction():uint {
			for (var i:uint=removed.length-1; i>=0; i--) {
				nodeList.splice(index, 0, removed[i]);
				removed[i].addParent(way);
				if (fireEvent) {
					entity.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, removed[i], way, index));
				}
			}
			way.deleted = nodeList.length == 0;
			markClean();
			return SUCCESS;
        }
    }
}