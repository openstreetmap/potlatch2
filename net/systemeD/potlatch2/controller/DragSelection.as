package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
    import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Globals;

    /** The state of moving a selection around with the mouse. */
    public class DragSelection extends ControllerState {
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
        public function DragSelection(sel:Array, event:MouseEvent) {
            selection = sel.concat();
            downX = event.localX;
            downY = event.localY;
			enterTime = (new Date()).getTime();
        }
 
       /** Handle dragging and end drag events. Filters out very short or quick drags. */
       override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            if (event.type==MouseEvent.MOUSE_UP) {
                if (dragstate==DRAGGING) { 
					var undo:CompositeUndoableAction = new CompositeUndoableAction("Move items");
					var lonDelta:Number = controller.map.coord2lon(downX)-controller.map.coord2lon(event.localX);
					var latDelta:Number = controller.map.coord2lat(downY)-controller.map.coord2lat(event.localY);
					var moved:Object = {};
					for each (var entity:Entity in selection) {
						if (entity is Node) {
							var node:Node=Node(entity);
							node.setLatLon(node.lat-latDelta, node.lon-lonDelta, undo.push);
							moved[node.id]=true;
						} else if (entity is Way) {
							undo.push(new MoveWayAction(Way(entity), latDelta, lonDelta, moved));
						}
					}
					MainUndoStack.getGlobalStack().addAction(undo);
                }
				return controller.findStateForSelection(selection);

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
				for each (var entity:Entity in selection) {
					entity.dispatchEvent(new EntityDraggedEvent(Connection.ENTITY_DRAGGED, entity, 0, 0));
				}
				return controller.findStateForSelection(selection);
			}
			return this;
		}

        private function dragTo(event:MouseEvent):ControllerState {
			for each (var entity:Entity in selection) {
				entity.dispatchEvent(new EntityDraggedEvent(Connection.ENTITY_DRAGGED, entity, event.localX-downX, event.localY-downY));
			}
            return this;
        }
        
		public function forceDragStart():void {
			dragstate=NOT_MOVED;
		}

        /** Highlight the dragged selection. */
        override public function enterState():void {
			for each (var entity:Entity in selection) {
				controller.map.setHighlight(entity, { selected: true });
			}
			Globals.vars.root.addDebug("**** -> "+this);
        }
        
        /** Un-highlight the dragged selection. */
        override public function exitState(newState:ControllerState):void {
			for each (var entity:Entity in selection) {
				controller.map.setHighlight(entity, { selected: false });
			}
			Globals.vars.root.addDebug("**** <- "+this);
        }
        /** "DragSelection" */
        override public function toString():String {
            return "DragSelection";
        }


    }
}
