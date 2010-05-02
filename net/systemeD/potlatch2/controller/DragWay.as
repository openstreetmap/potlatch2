package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Globals;

    public class DragWay extends ControllerState {
        private var isDraggingStarted:Boolean = false;
		private var enterTime:Number;

        private var downX:Number;
        private var downY:Number;
		private var dragstate:uint=NOT_MOVED;
		private const NOT_DRAGGING:uint=0;
		private const NOT_MOVED:uint=1;
		private const DRAGGING:uint=2;
        
        public function DragWay(way:Way, event:MouseEvent) {
            selectedWay = way;
            downX = event.localX;
            downY = event.localY;
			enterTime = (new Date()).getTime();
        }
 
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {

            if (event.type==MouseEvent.MOUSE_UP) {
                if (dragstate==DRAGGING) { 
                  MainUndoStack.getGlobalStack().addAction(
                          new MoveWayAction(selectedWay, downX, downY, event.localX, event.localY, controller.map)); 
                }
                return new SelectedWay(selectedWay);

			} else if ( event.type == MouseEvent.MOUSE_MOVE) {
				// dragging
				if (dragstate==NOT_DRAGGING) {
					return this;
				} else if (dragstate==NOT_MOVED && 
					       ((Math.abs(downX - event.localX) < 3 && Math.abs(downY - event.localY) < 3) ||
					        (new Date().getTime()-enterTime)<300)) {
					// ** add time check too
					return this;
				}
				dragstate=DRAGGING;
                return dragTo(event);

			} else {
				// event not handled
                return this;
			}
        }

        private function dragTo(event:MouseEvent):ControllerState {
			selectedWay.dispatchEvent(new WayDraggedEvent(Connection.WAY_DRAGGED, selectedWay, event.localX-downX, event.localY-downY));
            return this;
        }
        
		public function forceDragStart():void {
			dragstate=NOT_MOVED;
		}

        override public function enterState():void {
            controller.map.setHighlight(selectedWay, { highlight: true } );
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
            controller.map.setHighlight(selectedWay, { highlight: false } );
			Globals.vars.root.addDebug("**** <- "+this);
        }
        override public function toString():String {
            return "DragWay";
        }


    }
}
