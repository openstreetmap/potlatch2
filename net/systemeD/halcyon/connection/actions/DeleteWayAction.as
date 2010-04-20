package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class DeleteWayAction extends UndoableEntityAction {
        private var setDeleted:Function;
        private var effects:CompositeUndoableAction;
        private var nodeList:Array;
        private var oldNodeList:Array;
        
        public function DeleteWayAction(way:Way, setDeleted:Function, nodeList:Array) {
            super(way, "Delete");
            this.setDeleted = setDeleted;
            this.nodeList = nodeList;
        }
            
        public override function doAction():uint {
            var way:Way = entity as Way;
            if ( way.isDeleted() )
                return NO_CHANGE;

            effects = new CompositeUndoableAction("Delete refs");            
			var node:Node;
			way.suspend();
			way.removeFromParents(effects.push);
			oldNodeList = nodeList.slice();
			while (nodeList.length > 0) {
				node=nodeList.pop();
				way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node, way, 0));
				node.removeParent(way);
				if (!node.hasParents) { node.remove(effects.push); }
			}
			effects.doAction();
			setDeleted(true);
			markDirty();
            way.dispatchEvent(new EntityEvent(Connection.WAY_DELETED, way));
			way.resume();

            return SUCCESS;
        }
            
        public override function undoAction():uint {
            var way:Way = entity as Way;
			way.suspend();
            setDeleted(false);
            markClean();
            way.dispatchEvent(new EntityEvent(Connection.NEW_WAY, way));
            effects.undoAction();
            for each(var node:Node in oldNodeList) {
                nodeList.push(node);
                way.dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, way, 0));
            }
            way.resume();
            return SUCCESS;
        }
    }
}

