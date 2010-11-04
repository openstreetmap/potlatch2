package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
    
    public class UnjoinNodeAction extends CompositeUndoableAction {

        private var node:Node;
        private var selectedWay:Way;

        public function UnjoinNodeAction(node:Node, selectedWay:Way) {
            super("Unjoin node "+node.id);
            this.node = node;
            this.selectedWay = selectedWay;
        }
            
        public override function doAction():uint {
            if (node.parentWays.length < 2) {
              return NO_CHANGE;
            }

            for each (var way:Way in node.parentWays) {
              if (way == selectedWay) {
                continue;
              } else {
                var newNode:Node = Connection.getConnection().createNode(node.getTagsCopy(), node.lat, node.lon, push);
                for (var i:int = 0; i < way.length; i++) {
                  if(way.getNode(i) == node) {
                    way.removeNodeByIndex(i, push);
                    way.insertNode(i, newNode, push);
                  }
                }
              }
            }
            node.suspend();
            selectedWay.suspend();
            super.doAction();
            selectedWay.resume();
            node.resume();

            return SUCCESS;
        }
            
        public override function undoAction():uint {
            trace("fail");
            
            return FAIL;
        }
    }
}

