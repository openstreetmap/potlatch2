package net.systemeD.potlatch2 {
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapController;
    import net.systemeD.halcyon.connection.*;
	import flash.events.*;
	import flash.geom.*;

    public class EditController implements MapController {

        private var map:Map;
        private var tagViewer:TagViewer;
        private var selectedEntity:Entity;
        
        private var draggingNode:Node = null;
        

        public function EditController(map:Map, tagViewer:TagViewer) {
            this.map = map;
            this.tagViewer = tagViewer;
            
            map.parent.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_UP, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_DOWN, mapMouseEvent);
        }

        public function setActive():void {
            map.setController(this);
        }

        private function mapMouseEvent(event:MouseEvent):void {
            if ( draggingNode != null ) {
                var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
                event.localX = mapLoc.x;
                event.localY = mapLoc.y;

                processNodeEvent(event, null);
            }
        }
        
        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if ( event.type == MouseEvent.MOUSE_DOWN )
                event.stopPropagation();

            if ( entity is Node || draggingNode != null ) {
                processNodeEvent(event, entity);
                return;
            }
            
            if ( event.type == MouseEvent.CLICK ) {
                if ( selectedEntity != null ) {
                    map.setHighlight(selectedEntity, "selected", false);
                    map.setHighlight(selectedEntity, "showNodes", false);
                }
                tagViewer.setEntity(entity);
                map.setHighlight(entity, "selected", true);
                map.setHighlight(entity, "showNodes", true);
                selectedEntity = entity;
            } else if ( event.type == MouseEvent.MOUSE_OVER )
                map.setHighlight(entity, "hover", true);
            else if ( event.type == MouseEvent.MOUSE_OUT )
                map.setHighlight(entity, "hover", false);

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

