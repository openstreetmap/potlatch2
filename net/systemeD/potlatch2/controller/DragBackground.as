package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapEvent;
	import net.systemeD.halcyon.Globals;

    /** The state of realigning the background imagery by holding down a key and moving the mouse. This moves the background, but 
    * doesn't move the map, thereby adjusting the offset between the background and the map. */
    public class DragBackground extends ControllerState {

        private var downX:Number;
        private var downY:Number;
        
        /** Start the drag by recording the location of the mouse. */
        public function DragBackground(event:MouseEvent) {
            downX = event.localX;
            downY = event.localY;
        }
 
       /** Respond to dragging and end drag. */
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {

            if (event.type==MouseEvent.MOUSE_UP) {
               	return previousState;

			} else if ( event.type == MouseEvent.MOUSE_MOVE) {
				// dragging
				controller.map.nudgeBackground(event.localX-downX, event.localY-downY);
	            downX = event.localX;
	            downY = event.localY;
				return this;

			} else {
				// event not handled
                return this;
			}
        }

        /** Prevent map panning while background is being dragged. */
        override public function enterState():void {
			controller.map.draggable=false;
			Globals.vars.root.addDebug("**** -> "+this);
        }
        
        /** Re-allow map panning. */
        override public function exitState(newState:ControllerState):void {
			controller.map.draggable=true;
			Globals.vars.root.addDebug("**** <- "+this);
        }
        
        /** "DragBackground" */
        override public function toString():String {
            return "DragBackground";
        }
    }
}
