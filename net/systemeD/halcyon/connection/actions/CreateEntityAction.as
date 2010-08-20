package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class CreateEntityAction extends UndoableEntityAction {
        private var setCreate:Function;
        private var deleteAction:UndoableAction;
        
        // This is a bit unusual, since we need to handle undo and specifically redo slightly differently
        // When undo is called, instead of simply removing the entity, we work through
        // to make a Delete[Entity]Action, call that, and store it for later
        // Then, when this action is called again (i.e. a redo), instead of creating yet another entity, we call the deleteAction.undoAction

        public function CreateEntityAction(entity:Entity, setCreate:Function) {
            super(entity, "Create");
            this.setCreate = setCreate;
        }
            
        public override function doAction():uint {
            // check to see if this is the first pass - i.e. not a redo action.
            // if it's redo (i.e. we've stored a deleteAction), undo the deletion
            // if it's the first time, register the new entity with the connection
            if ( deleteAction != null ) {
                deleteAction.undoAction();
            } else {
                setCreate(entity, false);
            }
            markDirty(); // if this is the first action taken, undoing it will then be able to clean the connection
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            // if the undo is called for the first time, call for a deletion, and (via setAction) store the
            // deletion action for later. We'll undo the deletion if we get asked to redo this action
            if ( deleteAction == null ) {
                entity.remove(setAction);
            }
            deleteAction.doAction();
            markClean();
            return SUCCESS;
        }
        
        private function setAction(action:UndoableAction):void {
            deleteAction = action;
        }
    }
}

