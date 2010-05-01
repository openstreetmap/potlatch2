package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class CreateEntityAction extends UndoableEntityAction {
        private var setCreate:Function;
        private var deleteAction:UndoableAction;
        
        public function CreateEntityAction(entity:Entity, setCreate:Function) {
            super(entity, "Create");
            this.setCreate = setCreate;
        }
            
        public override function doAction():uint {
            if ( deleteAction != null ) {
                deleteAction.undoAction();
            } else {
                setCreate(entity, false);
            }
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            if ( deleteAction == null ) {
                entity.remove(setAction);
            }
            deleteAction.doAction();
            
            return SUCCESS;
        }
        
        private function setAction(action:UndoableAction):void {
            deleteAction = action;
        }
    }
}

