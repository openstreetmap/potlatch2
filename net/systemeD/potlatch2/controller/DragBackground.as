package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapEvent;
	import net.systemeD.halcyon.Globals;

    public class DragBackground extends ControllerState {

        private var downX:Number;
        private var downY:Number;
        
        public function DragBackground(event:MouseEvent) {
            downX = event.localX;
            downY = event.localY;
        }
 
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

        override public function enterState():void {
			controller.map.draggable=false;
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState(newState:ControllerState):void {
			controller.map.draggable=true;
			Globals.vars.root.addDebug("**** <- "+this);
        }
        override public function toString():String {
            return "DragBackground";
        }
    }
}
