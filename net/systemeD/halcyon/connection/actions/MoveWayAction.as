package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
    
    public class MoveWayAction extends CompositeUndoableAction {
    
        private var way:Way;
        private var downX:Number;
        private var downY:Number;
        private var x:Number;
        private var y:Number;
        private var map:Map;
    
        public function MoveWayAction(way:Way, downX:Number, downY:Number, x:Number, y:Number, map:Map) {
            super("Drag way "+way.id);
            this.way = way;
            this.downX = downX;
            this.downY = downY;
            this.x = x;
            this.y = y;
            this.map = map;
        }
    
        public override function doAction():uint {
            var lonDelta:Number = map.coord2lon(downX)-map.coord2lon(x);
            var latDelta:Number = map.coord2lat(downY)-map.coord2lat(y);
            var moved:Object = {};
            way.suspend();
            way.dispatchEvent(new WayDraggedEvent(Connection.WAY_DRAGGED, way, 0, 0));
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