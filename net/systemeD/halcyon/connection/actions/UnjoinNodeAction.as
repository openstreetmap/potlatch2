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
            trace("unjoining node "+node.id);
            if (node.parentWays.length < 2) {
              return NO_CHANGE;
            }

            node.suspend();
            for each (var way:Way in node.parentWays) {
              way.suspend();
              if (way == selectedWay) {
                trace("skipping selected way");
                continue;
              } else {
                trace("need to fettle way: "+way);
                var newNode:Node = Connection.getConnection().createNode(node.getTagsCopy(), node.lat, node.lon, push);
                for (var i:int = 0; i < way.length; i++) {
                  if(way.getNode(i) == node) {
                    way.removeNodeByIndex(i, push);
                    way.insertNode(i, newNode, push);
                    trace("inserted node at" +i); 
                  }
                }
              }
              way.resume();
            }
            super.doAction();
            node.resume();

            return SUCCESS;
        }
            
        public override function undoAction():uint {
            trace("fail");
            
            return FAIL;
        }
    }
}

