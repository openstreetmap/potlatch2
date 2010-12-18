package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
    import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Globals;

    /** The state of moving a way around with the mouse. */
    public class DragWay extends ControllerState {
        private var isDraggingStarted:Boolean = false;
		private var enterTime:Number;

        private var downX:Number;
        private var downY:Number;
		private var dragstate:uint=NOT_MOVED;
		/** Not used? */
		private const NOT_DRAGGING:uint=0;
		
		/** "Dragging" but hasn't actually moved yet. */
		private const NOT_MOVED:uint=1;
		
		/** While moving. */
		private const DRAGGING:uint=2;
        
        /** Start the drag by recording the dragged way, where it started, and when. */
        public function DragWay(way:Way, event:MouseEvent) {
            selection = [way];
            downX = event.localX;
            downY = event.localY;
			enterTime = (new Date()).getTime();
        }
 
       /** Handle dragging and end drag events. Filters out very short or quick drags. */
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            if (event.type==MouseEvent.MOUSE_UP) {
                if (dragstate==DRAGGING) { 
                  MainUndoStack.getGlobalStack().addAction(
                          new MoveWayAction(firstSelected as Way, downX, downY, event.localX, event.localY, controller.map)); 
                }
                return new SelectedWay(firstSelected as Way, new Point(event.stageX,event.stageY));

			} else if ( event.type == MouseEvent.MOUSE_MOVE) {
				// dragging
				if (dragstate==NOT_DRAGGING) {
					return this;
				} else if (dragstate==NOT_MOVED && 
					       ((Math.abs(downX - event.localX) < 3 && Math.abs(downY - event.localY) < 3) ||
					        (new Date().getTime()-enterTime)<300)) {
					return this;
				}
				dragstate=DRAGGING;
                return dragTo(event);

			} else {
				// event not handled
                return this;
			}
        }

		/** Abort dragging if ESC pressed. */
		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==Keyboard.ESCAPE) {
				firstSelected.dispatchEvent(new WayDraggedEvent(Connection.WAY_DRAGGED, firstSelected as Way, 0, 0));
				return new SelectedWay(firstSelected as Way);
			}
			return this;
		}

        private function dragTo(event:MouseEvent):ControllerState {
			firstSelected.dispatchEvent(new WayDraggedEvent(Connection.WAY_DRAGGED, firstSelected as Way, event.localX-downX, event.localY-downY));
            return this;
        }
        
		public function forceDragStart():void {
			dragstate=NOT_MOVED;
		}

        /** Highlight the dragged way. */
        override public function enterState():void {
            controller.map.setHighlight(firstSelected, { selected: true } );
			Globals.vars.root.addDebug("**** -> "+this);
        }
        
        /** Un-highlight the dragged way. */
        override public function exitState(newState:ControllerState):void {
            controller.map.setHighlight(firstSelected, { selected: false } );
			Globals.vars.root.addDebug("**** <- "+this);
        }
        /** "DragWay" */
        override public function toString():String {
            return "DragWay";
        }


    }
}
