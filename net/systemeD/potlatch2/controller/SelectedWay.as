package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;

    public class SelectedWay extends ControllerState {
        private var selectedWay:Way;
        private var initWay:Way;
        
        public function SelectedWay(way:Way) {
            initWay = way;
        }
 
        protected function selectWay(way:Way):void {
            if ( way == selectedWay )
                return;

            clearSelection();
            controller.setTagViewer(way);
            controller.map.setHighlight(way, "selected", true);
            controller.map.setHighlight(way, "showNodes", true);
            selectedWay = way;
            initWay = way;
        }
        
        protected function clearSelection():void {
            if ( selectedWay != null ) {
                controller.map.setHighlight(selectedWay, "selected", false);
                controller.map.setHighlight(selectedWay, "showNodes", false);
                controller.setTagViewer(null);
                selectedWay = null;
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);
            if ( event.type == MouseEvent.CLICK ) {
                if ( (entity is Node && entity.hasParent(selectedWay)) || focus == selectedWay )
                    return clickOnWay(event, entity);
                else if ( focus is Way )
                    selectWay(focus as Way);
                else if ( focus is Node )
                    trace("select poi");
                else if ( focus == null )
                    return previousState;
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
                if ( entity is Node && entity.hasParent(selectedWay) )
                    return new DragWayNode(selectedWay, Node(entity), event);
            }

            return this;
        }

        public function clickOnWay(event:MouseEvent, entity:Entity):ControllerState {
            if ( event.shiftKey ) {
                if ( entity is Way )
                    addNode(event);
                else
                    trace("start new way");
            } else {
                if ( entity is Node )
                    trace("select way node");
            }
            
            return this;
        }
        
        public function addNode(event:MouseEvent):void {
            trace("add node");
            var lat:Number = controller.map.coord2lat(event.localY);
            var lon:Number = controller.map.coord2lon(event.localX);
            var node:Node = controller.connection.createNode({}, lat, lon);
            selectedWay.insertNodeAtClosestPosition(node, true);
        }
        
        override public function enterState():void {
            selectWay(initWay);
        }
        override public function exitState():void {
            clearSelection();
        }
    }
}
