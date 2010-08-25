package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    /* This is needed so that the specific type of CUA can be detected when CreatePOIAction is called */
    public class BeginWayAction extends CompositeUndoableAction {

        public function BeginWayAction(){
          super("Begin Way Action");
        }

    }
}