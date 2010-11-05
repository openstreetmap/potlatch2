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
            
            // The Delete[entity]Action is unusual, since it can be called both to delete an entity, and is also used to undo its creation
            // (hence preserving the negative id, if the creation is subsequently redone). Normally a deletion would mark the entity dirty, but
            // if a newly created entity is being deleted, the entity is now clean. 
            // When the creation is "redone", it's actually an undo on the deletion of the new entity (see below),
            // and so the connection will need to be considered dirty again. Usually it's an existing object that's deleted and restored,
            // which would make things clean.
            // See also CreateEntityAction
            
            if (node.id < 0) {
              markClean();
            } else {
              markDirty();
            }
            node.dispatchEvent(new EntityEvent(Connection.NODE_DELETED, node));	// delete NodeUI
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            var node:Node = entity as Node;
            setDeleted(false);
            
            // See note above
            if (node.id < 0) {
              markDirty();
            } else {
              markClean();
            }
            Connection.getConnection().dispatchEvent(new EntityEvent(Connection.NEW_NODE, entity));
            if ( effects != null )
                effects.undoAction();
            return SUCCESS;
        }
    }
}

