package net.systemeD.halcyon.connection {

    /**
    * UndoableAction is the base class from which other actions types inherit. An undoable action
    * is an object that can be added to a list of actions, for example the MainUndoStack or any
    * other list of actions.
    *
    * @see CompositeUndoableAction
    * @see UndoableEntityAction
    */

    public class UndoableAction {


        /** Something went wrong while attempting the action */
        public static const FAIL:uint = 0;
        /** The action worked, and entities were changed */
        public static const SUCCESS:uint = 1;
        /** No entity was altered by this action */
        public static const NO_CHANGE:uint = 2; 

        /**
        * The doAction function is called when it is time to execute this action or
        * combination of actions. It is usually triggered by either MainUndoStack.addAction
        * or by MainUndoStack.redo.
        *
        * This should be overridden.
        *
        * @return whether the action succeed, failed or nothing happened
        */
        public function doAction():uint { return FAIL; }

        /**
        * The undoAction function is called in order to undo this action or combination
        * of actions. It is usually triggered by MainUndoStack.undo.
        *
        * This should be overridden.
        *
        * @return whether undoing the action succeed, failed or nothing happened
        */
        public function undoAction():uint { return FAIL; }

        /**
        * Can this action be merged with the previous action? This is sometimes wanted, such as
        * when moving nodes around.
        *
        * This is overridden when needed.
        *
        * @see net.systemeD.halcyon.connection.actions.MoveNodeAction#mergePrevious
        */
        public function mergePrevious(previous:UndoableAction):Boolean {
            return false;
        }
    }
    
}
