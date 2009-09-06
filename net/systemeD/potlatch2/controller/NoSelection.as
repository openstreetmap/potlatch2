package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;

    public class NoSelection extends ControllerState {
        public function NoSelection() {
        }
 
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            var focus:Entity = getTopLevelFocusEntity(entity);
            if ( event.type == MouseEvent.CLICK )
                if ( focus is Way )
                    return new SelectedWay(focus as Way);
                else if ( focus is Node )
                    trace("select poi");
                else if ( focus == null )
                    return new CreateWay(event);
            else if ( event.type == MouseEvent.MOUSE_OVER )
                controller.map.setHighlight(focus, "hover", true);
            else if ( event.type == MouseEvent.MOUSE_OUT )
                controller.map.setHighlight(focus, "hover", false);
                
            return this;
        }
        
        public static function getTopLevelFocusEntity(entity:Entity):Entity {
            if ( entity is Node ) {
                for each (var parent:Entity in entity.parentWays) {
                    return parent;
                }
                return entity;
            } else if ( entity is Way ) {
                return entity;
            } else {
                return null;
            }
        }
    }
}
