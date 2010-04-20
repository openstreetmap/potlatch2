package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class DeleteNodeAction extends UndoableEntityAction {
        private var setDeleted:Function;
        private var effects:CompositeUndoableAction;
        
        public function DeleteNodeAction(node:Node, setDeleted:Function) {
            super(node, "Delete");
            this.setDeleted = setDeleted;
        }
            
        public override function doAction():uint {
            var node:Node = entity as Node;
            if ( node.isDeleted() )
                return NO_CHANGE;

            effects = new CompositeUndoableAction("Delete refs");            
            node.removeFromParents(effects.push);
            effects.doAction();
            setDeleted(true);
            markDirty();
            node.dispatchEvent(new EntityEvent(Connection.NODE_DELETED, node));
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            setDeleted(false);
            markClean();
            entity.dispatchEvent(new EntityEvent(Connection.NEW_NODE, entity));
            effects.undoAction();
            return SUCCESS;
        }
    }
}

