package net.systemeD.halcyon.connection {

    public class CompositeUndoableAction extends UndoableAction {
        
        private var name:String;
        private var actions:Array = [];
        private var actionsDone:Boolean = false;
    
        public function CompositeUndoableAction(name:String) {
            this.name = name;
        }
        
        public function push(action:UndoableAction):void {
            actions.push(action);
        }
        
        public function clearActions():void {
            actions = [];
        }
        
        public override function doAction():uint {
            if ( actionsDone )
                return UndoableAction.FAIL;
                
            var somethingDone:Boolean = false;
            for ( var i:int = 0; i < actions.length; i++ ) {
                var action:UndoableAction = actions[i];
                
                var result:uint = action.doAction();
                if ( result == UndoableAction.NO_CHANGE ) {
                    // splice this one out as it doesn't do anything
                    actions.splice(i, 1)
                    i --;
                } else if ( result == UndoableAction.FAIL ) {
                    undoFrom(i);
                    return UndoableAction.FAIL;
                } else {
                    somethingDone = true;
                }
            }
            actionsDone = true;
            return somethingDone ? UndoableAction.SUCCESS : UndoableAction.NO_CHANGE;
        }
        
        public override function undoAction():uint {
            if ( !actionsDone )
                return UndoableAction.FAIL;
                
            undoFrom(actions.length);
            return UndoableAction.SUCCESS;
        }
        
        public function undoFrom(index:int):void {
            for ( var i:int = index - 1; i >= 0; i-- ) {
                var action:UndoableAction = actions[i];
                trace("going to do "+action);
                
                action.undoAction();
            }
            actionsDone = false;
        }
        
        public function toString():String {
            var str:String = " {" + actions.join(",") + "}";
            return name + str;
        }
    }

}

