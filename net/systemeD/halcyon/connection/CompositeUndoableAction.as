package net.systemeD.halcyon.connection {

    /**
    * A CompositeUndoableAction is an UndoableAction that is made up of multiple individual actions.
    * You want to use one where you have multiple entities being altered in a given situation that you
    * want to treat as one overall action (e.g. they are all done together, and should be undone in one go too).
    *
    * A CompositeUndoableAction will store the stack of individual actions, and when doAction is called will go through each one of
    * them and call doAction on the individual action.
    *
    * Sometimes a composite action can be made without further ado, and actions pushed into this one and this one added to
    * the relevant undo stack. But often more complex things needs to be done, so this is often extended into a more specific action.
    */

    public class CompositeUndoableAction extends UndoableAction {
        
        private var name:String;
        private var actions:Array = [];
        private var actionsDone:Boolean = false;

        /**
        * @param name The name you want to give to this CompositeUndoableAction - useful for debugging
        */
        public function CompositeUndoableAction(name:String) {
            this.name = name;
        }

        /**
        * Add an action to the list of actions that make up this CompositeUndoableAction
        */
        public function push(action:UndoableAction):void {
            actions.push(action);
        }

        /**
        * Clear the list of actions
        */
        public function clearActions():void {
            actions = [];
        }

        /**
        * Do all the actions on the list. Can be overridden by an specific implementation, usually to manage
        * the suspending and resuming of entities. If so, you'll want to call super.doAction from that implementation
        * to actually execute the list of actions that you've added via push
        *
        * If any action fails while exectuing, the preceeding actions will be undone and this composite will return FAIL
        *
        * @return whether the entire stack of actions succeeded, failed or resulted in nothing changing.
        *
        * @see #push
        */
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

        /**
        * Undo the actions on the list. If overridden call super.undoAction
        */
        public override function undoAction():uint {
            if ( !actionsDone )
                return UndoableAction.FAIL;
                
            undoFrom(actions.length);
            return UndoableAction.SUCCESS;
        }

        /**
        * Undo the actions from a given index. Used when the composite needs to be aborted when one of the
        * individual actions fails
        */
        public function undoFrom(index:int):void {
            for ( var i:int = index - 1; i >= 0; i-- ) {
                var action:UndoableAction = actions[i];
                
                action.undoAction();
            }
            actionsDone = false;
        }

        /**
        * Returns the name of this composite action, along with the (recursive) description of all the sub actions
        */
        public function toString():String {
            var str:String = " {" + actions.join(",") + "}";
            return name + str;
        }
    }

}

