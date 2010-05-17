package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class DragWayNode extends ControllerState {
        private var draggingNode:Node;
		private var draggingIndex:int;
        private var isDraggingStarted:Boolean = false;
		private var isNew:Boolean = false;

        private var downX:Number;
        private var downY:Number;
		private var dragstate:uint=NOT_MOVED;
		private const NOT_DRAGGING:uint=0;
		private const NOT_MOVED:uint=1;
		private const DRAGGING:uint=2;
        
        public function DragWayNode(way:Way, index:int, event:MouseEvent, newNode:Boolean) {
            selectedWay = way;
			draggingIndex = index;
            draggingNode = way.getNode(index);
            downX = event.localX;
            downY = event.localY;
			isNew = newNode;
        }
 
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {

            if (event.type==MouseEvent.MOUSE_UP) {
 				if (dragstate==DRAGGING) {
					// mouse-up while dragging, so end drag
                	return new SelectedWayNode(selectedWay,draggingIndex);
//	                return endDrag();
				} else if (event.shiftKey && !isNew) {
					// start new way
					var way:Way = controller.connection.createWay({}, [entity],
					    MainUndoStack.getGlobalStack().addAction);
					return new DrawWay(way, true, false);
				} else if (event.shiftKey && isNew) {
                	return new SelectedWayNode(selectedWay,draggingIndex);
				} else {
					// select node
					dragstate=NOT_DRAGGING;
                	return SelectedWayNode.selectOrEdit(selectedWay, draggingIndex);
				}

			} else if ( event.type == MouseEvent.MOUSE_MOVE) {
				// dragging
				if (dragstate==NOT_DRAGGING) {
					return this;
				} else if (dragstate==NOT_MOVED && Math.abs(downX - event.localX) < 3 && Math.abs(downY - event.localY) < 3) {
					return this;
				}
				dragstate=DRAGGING;
                return dragTo(event);

			} else {
				// event not handled
                return this;
			}
        }

        private function endDrag():ControllerState {
            return previousState;
        }
        
        private function dragTo(event:MouseEvent):ControllerState {
			draggingNode.setLatLon( controller.map.coord2lat(event.localY),
                                    controller.map.coord2lon(event.localX),
                                    MainUndoStack.getGlobalStack().addAction );
            return this;
        }
        
		public function forceDragStart():void {
			dragstate=NOT_MOVED;
		}

        override public function enterState():void {
            controller.map.setHighlight(selectedWay, { showNodes: true } );
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
            controller.map.setHighlight(selectedWay, { showNodes: false } );
			Globals.vars.root.addDebug("**** <- "+this);
        }
        override public function toString():String {
            return "DragWayNode";
        }
    }
}
