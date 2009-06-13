package net.systemeD.halcyon {
    import net.systemeD.halcyon.connection.*;
	import flash.events.*;

    public class EditController implements MapController {

        private var map:Map;
        private var tagViewer:TagViewer;

        public function EditController(map:Map, tagViewer:TagViewer) {
            this.map = map;
            this.tagViewer = tagViewer;
        }

        public function setActive():void {
            map.setController(this);
        }

        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if ( event.type == MouseEvent.CLICK )
                tagViewer.setEntity(entity);
            else if ( event.type == MouseEvent.MOUSE_OVER )
                map.setHighlight(entity, true);
            else if ( event.type == MouseEvent.MOUSE_OUT )
                map.setHighlight(entity, false);

        }

    }

}

