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

            var ways:Array=[];
            for each (var way:Way in node.parentWays) {
              way.suspend(); ways.push(way);
              if (way == selectedWay) {
            	way.dispatchEvent(new EntityEvent(Connection.WAY_REORDERED, way));	// no longer a junction, so force redraw
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
            super.doAction();
            for each (way in ways) { way.resume(); }

            return SUCCESS;
        }
            
        public override function undoAction():uint {
            node.suspend();
            selectedWay.suspend();
            super.undoAction();
            selectedWay.resume();
            node.resume();
            
            return SUCCESS;
        }
    }
}

