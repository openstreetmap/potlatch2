package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import flash.events.*;
    
    public class CreatePOIAction extends CompositeUndoableAction {
    
        private var newNode:Node;
		private var tags:Object;
		private var lat:Number;
		private var lon:Number;
		private var connection:Connection;
        
        public function CreatePOIAction(connection:Connection, tags:Object, lat:Number, lon:Number) {
          super("Create POI");
          this.connection = connection;
          this.tags = tags;
          this.lat = lat;
          this.lon = lon;
        }
        
        public override function doAction():uint {
          if (newNode == null) {
            newNode = connection.createNode(tags,lat,lon,push);
          }
          super.doAction();
          connection.registerPOI(newNode);
          
          return SUCCESS;
        }
        
        public override function undoAction():uint {
          super.undoAction();
          connection.unregisterPOI(newNode);
          
          return SUCCESS;
        }
        
        public function getNode():Node {
          return newNode;
        }
    }
}