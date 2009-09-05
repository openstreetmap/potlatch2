package net.systemeD.potlatch2 {
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.controller.*;
	import flash.events.*;
	import flash.geom.*;

    public class EditController implements MapController {

        private var _map:Map;
        private var tagViewer:TagViewer;
        private var selectedWay:Way;
        private var selectedNode:Node;
        
        private var draggingNode:Node = null;
        
        private var state:ControllerState;
        private var _connection:Connection;
        

        public function EditController(map:Map, tagViewer:TagViewer) {
            this._map = map;
            this.tagViewer = tagViewer;
            setState(new NoSelection());
            
            map.parent.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_UP, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_DOWN, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.CLICK, mapMouseEvent);
        }

        public function setActive():void {
            map.setController(this);
            _connection = map.connection;
        }

        public function get map():Map {
            return _map;
        }
        
        public function get connection():Connection {
            return _connection;
        }
        
        public function setTagViewer(entity:Entity):void {
            tagViewer.setEntity(entity);
        }
        
        private function mapMouseEvent(event:MouseEvent):void {
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, null);
            setState(newState);
            if ( draggingNode != null ) {
            }
        }
        
        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            //if ( event.type == MouseEvent.MOUSE_DOWN )
                event.stopPropagation();
                
            var newState:ControllerState = state.processMouseEvent(event, entity);
            setState(newState);

            /*
            if ( entity is Node || draggingNode != null ) {
                processNodeEvent(event, entity);
            } else if ( enity is Way ) {
                processWayEvent(event, entity);
            }
            
            if ( event.type == MouseEvent.CLICK ) {
                if ( selectedWay != null ) {
                    map.setHighlight(selectedWay, "selected", false);
                    map.setHighlight(selectedWay, "showNodes", false);
                }
                tagViewer.setEntity(entity);
                map.setHighlight(entity, "selected", true);
                map.setHighlight(entity, "showNodes", true);
                selectedWay = entity;
            } else if ( event.type == MouseEvent.MOUSE_OVER )
                map.setHighlight(entity, "hover", true);
            else if ( event.type == MouseEvent.MOUSE_OUT )
                map.setHighlight(entity, "hover", false);
            */
        }
        
        private function setState(newState:ControllerState):void {
            if ( newState == state )
                return;
                
            if ( state != null )
                state.exitState();
            newState.setController(this);
            newState.setPreviousState(state);
            state = newState;
            state.enterState();
        }

        private function processNodeEvent(event:MouseEvent, entity:Entity):void {
            if ( draggingNode != null ) {
                if ( event.type == MouseEvent.MOUSE_UP ) {
                    draggingNode = null;
                } else if ( event.type == MouseEvent.MOUSE_MOVE ) {
                    draggingNode.lat = map.coord2lat(event.localY);
                    draggingNode.lon = map.coord2lon(event.localX);
                }
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
                draggingNode = entity as Node;
            }
        }
        
    }

    
}

