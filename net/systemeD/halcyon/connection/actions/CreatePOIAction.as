package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    import flash.events.*;
    
    public class CreatePOIAction extends CompositeUndoableAction {
    
        private var newNode:Node;
		private var tags:Object;
		private var lat:Number;
		private var lon:Number;
        
        public function CreatePOIAction(tags:Object, lat:Number, lon:Number) {
          super("Create POI");
          this.tags = tags;
          this.lat = lat;
          this.lon = lon;
        }
        
        public override function doAction():uint {
          if (newNode == null) {
            newNode = Connection.getConnection().createNode(tags,lat,lon,push);
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