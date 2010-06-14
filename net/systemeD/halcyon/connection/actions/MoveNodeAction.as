package net.systemeD.halcyon.connection.actions {

    import flash.utils.getTimer;

    import net.systemeD.halcyon.connection.*;
    
    public class MoveNodeAction extends UndoableEntityAction {
        private var createTime:uint;
        private var oldLat:Number;
        private var oldLon:Number;
        private var newLat:Number;
        private var newLon:Number;        
        private var setLatLon:Function;
        
        public function MoveNodeAction(node:Node, newLat:Number, newLon:Number, setLatLon:Function) {
            super(node, "Move to "+newLon+","+newLat);
            this.newLat = newLat;
            this.newLon = newLon;
            this.setLatLon = setLatLon;
            createTime = getTimer();
        }
            
        public override function doAction():uint {
            var node:Node = entity as Node;
            oldLat = node.lat;
            oldLon = node.lon;
            if ( oldLat == newLat && oldLon == newLon )
                return NO_CHANGE;
            
            setLatLon(newLat, newLon);
            markDirty();
            entity.dispatchEvent(new NodeMovedEvent(Connection.NODE_MOVED, node, oldLat, oldLon));
            
            return SUCCESS;
        }
            
        public override function undoAction():uint {
            setLatLon(oldLat, oldLon);
            markClean();
            entity.dispatchEvent(new NodeMovedEvent(Connection.NODE_MOVED, Node(entity), newLat, newLon));
            return SUCCESS;
        }
        
        public override function mergePrevious(prev:UndoableAction):Boolean {
            if ( !(prev is MoveNodeAction) )
                return false;
                
            var prevMove:MoveNodeAction = prev as MoveNodeAction;
            if ( prevMove.entity == entity && prevMove.createTime + 1000 > createTime ) {
                oldLat = prevMove.oldLat;
                oldLon = prevMove.oldLon;
                return true;
            }
            
            return false;
        }
    }
}

