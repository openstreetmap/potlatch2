package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    
    public class MoveWayAction extends CompositeUndoableAction {
    
        private var way:Way;
        private var lonDelta:Number;
        private var latDelta:Number;
		private var moved:Object;
    
        public function MoveWayAction(way:Way, latDelta:Number, lonDelta:Number, moved:Object) {
            super("Drag way "+way.id);
            this.way = way;
            this.lonDelta = lonDelta;
            this.latDelta = latDelta;
			this.moved = moved;
        }
    
        public override function doAction():uint {
            way.suspend();
            way.dispatchEvent(new EntityDraggedEvent(Connection.ENTITY_DRAGGED, way, 0, 0));
            for (var i:uint=0; i<way.length; i++) {
                var n:Node=way.getNode(i);
                if (!moved[n.id]) {
                    n.setLatLon(n.lat-latDelta, n.lon-lonDelta, push);
                    moved[n.id]=true;
                }
            }
            super.doAction();
            way.resume();
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            way.suspend();
            super.undoAction();
            way.resume();
            return SUCCESS;
        }
        
    }
}