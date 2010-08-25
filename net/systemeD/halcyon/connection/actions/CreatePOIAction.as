package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import flash.events.*;
    
    public class CreatePOIAction extends CompositeUndoableAction {
    
        private var newNode:Node;
        private var event:MouseEvent;
        private var map:Map;
        
        public function CreatePOIAction(event:MouseEvent, map:Map) {
          super("Create POI");
          this.event = event;
          this.map = map;
        }
        
        public override function doAction():uint {
          if (newNode == null) {
            newNode = Connection.getConnection().createNode(
                {},
                map.coord2lat(event.localY),
                map.coord2lon(event.localX), push);
          }
          super.doAction();
          Connection.getConnection().registerPOI(newNode);
          
          return SUCCESS;
        }
        
        public override function undoAction():uint {
          super.undoAction();
          Connection.getConnection().unregisterPOI(newNode);
          
          return SUCCESS;
        }
        
        public function getNode():Node {
          return newNode;
        }
    }
}