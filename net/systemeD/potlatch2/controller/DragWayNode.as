package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;

    public class DragWayNode extends ControllerState {
        private var selectedWay:Way;
        private var draggingNode:Node;
        private var isDraggingStarted:Boolean = false;
        private var downX:Number;
        private var downY:Number;
        
        public function DragWayNode(way:Way, node:Node, mouseDown:MouseEvent) {
            selectedWay = way;
            draggingNode = node;
            downX = mouseDown.localX;
            downY = mouseDown.localY;
        }
 
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            if ( event.type == MouseEvent.MOUSE_UP )
                return endDrag();

            if ( !isDragging(event) )
                return this;
            
            if ( event.type == MouseEvent.MOUSE_MOVE )
                return dragTo(event);
            else   
                return this;
        }

        private function isDragging(event:MouseEvent):Boolean {
            if ( isDraggingStarted )
                return true;
            
            isDraggingStarted = Math.abs(downX - event.localX) > 3 ||
                                Math.abs(downY - event.localY) > 3;
            return isDraggingStarted;
        }
        
        private function endDrag():ControllerState {
            return previousState;
        }
        
        private function dragTo(event:MouseEvent):ControllerState {
            draggingNode.lat = controller.map.coord2lat(event.localY);
            draggingNode.lon = controller.map.coord2lon(event.localX);
            return this;
        }
        
        override public function enterState():void {
            controller.map.setHighlight(selectedWay, "showNodes", true);
        }
        override public function exitState():void {
            controller.map.setHighlight(selectedWay, "showNodes", false);
        }
    }
}
