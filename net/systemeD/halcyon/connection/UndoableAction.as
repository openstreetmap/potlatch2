package net.systemeD.halcyon.connection {

    public class UndoableAction {
    
        public static const FAIL:uint = 0;
        public static const SUCCESS:uint = 1;
        public static const NO_CHANGE:uint = 2; 
    
        public function doAction():uint { return FAIL; }
        
        public function undoAction():uint { return FAIL; }
        
        public function mergePrevious(previous:UndoableAction):Boolean {
            return false;
        }
    }
    
}
