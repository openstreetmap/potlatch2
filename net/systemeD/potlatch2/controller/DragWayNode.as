package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.WayUI;

    public class DragWayNode extends ControllerState {
        private var draggingNode:Node;
		private var draggingIndex:int;
        private var isDraggingStarted:Boolean = false;
		private var isNew:Boolean = false;

        private var downX:Number;
        private var downY:Number;
		private var originalLat:Number;
		private var originalLon:Number;
		private var dragstate:uint=NOT_MOVED;
		private const NOT_DRAGGING:uint=0;
		private const NOT_MOVED:uint=1;
		private const DRAGGING:uint=2;
		
		private var parentWay:Way;
		private var initEvent:MouseEvent;
        
        public function DragWayNode(way:Way, index:int, event:MouseEvent, newNode:Boolean) {
			parentWay=way;
			draggingIndex=index;
            downX = event.localX;
            downY = event.localY;
			isNew = newNode;
			initEvent=event;
			// the rest of the init will be done during enterState, because we need the controller to be initialised
        }

        private function addNode(selectedWay:Way,event:MouseEvent):int {
			// find which other ways are under the mouse
			var ways:Array=[]; var w:Way;
			for each (var wayui:WayUI in controller.map.paint.wayuis) {
				w=wayui.hitTest(event.stageX, event.stageY);
				if (w && w!=selectedWay) { ways.push(w); }
			}

            var lat:Number = controller.map.coord2lat(event.localY);
            var lon:Number = controller.map.coord2lon(event.localX);
            var undo:CompositeUndoableAction = new CompositeUndoableAction("Insert node");
            var node:Node = controller.connection.createNode({}, lat, lon, undo.push);
            var index:int = selectedWay.insertNodeAtClosestPosition(node, true, undo.push);
			for each (w in ways) { w.insertNodeAtClosestPosition(node, true, undo.push); }
            MainUndoStack.getGlobalStack().addAction(undo);
			return index;
        }

 
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {

            if (event.type==MouseEvent.MOUSE_UP) {
 				if (dragstate==DRAGGING) {
					// mouse-up while dragging, so end drag
                	return new SelectedWayNode(parentWay,draggingIndex);
				} else if (event.shiftKey && !isNew) {
					// start new way
					var way:Way = controller.connection.createWay({}, [entity],
					    MainUndoStack.getGlobalStack().addAction);
					return new DrawWay(way, true, false);
				} else if (event.shiftKey && isNew) {
                	return new SelectedWayNode(parentWay,draggingIndex);
				} else {
					// select node
					dragstate=NOT_DRAGGING;
                	return SelectedWayNode.selectOrEdit(parentWay, draggingIndex);
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

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==27) {
				draggingNode.setLatLon( originalLat, originalLon, MainUndoStack.getGlobalStack().addAction );
               	return new SelectedWayNode(parentWay,draggingIndex);
			}
			return this;
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
		
		override public function get selectedWay():Way {
			return parentWay;
		}

        override public function enterState():void {
			if (isNew && draggingIndex==-1) { draggingIndex=addNode(parentWay,initEvent); }
            draggingNode = parentWay.getNode(draggingIndex);
			originalLat = draggingNode.lat;
			originalLon = draggingNode.lon;

			controller.map.setHighlightOnNodes(parentWay, { selectedway: true } );
			controller.map.limitWayDrawing(parentWay, draggingIndex);
			controller.map.setHighlight(draggingNode, { selected: true } );
			controller.map.protectWay(parentWay);
			controller.map.limitWayDrawing(parentWay, NaN, draggingIndex);
        }
        override public function exitState(newState:ControllerState):void {
			controller.map.unprotectWay(parentWay);
			controller.map.limitWayDrawing(parentWay);
			controller.map.setHighlightOnNodes(parentWay, { selectedway: false } );
			controller.map.setHighlight(draggingNode, { selected: false } );
        }
        override public function toString():String {
            return "DragWayNode";
        }
    }
}
