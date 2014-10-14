package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.Stage;
	import flash.ui.Keyboard;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.tools.Parallelise;
	import net.systemeD.halcyon.connection.actions.*;

    /** The state midway during the use of the "parallelise tool", where a parallel way has been created but is stuck to the 
    * mouse cursor, allowing the user to choose how far from the original way it should go. This transforms it in the process. */
    public class SelectedParallelWay extends SelectedWay {
		private var startlon:Number;
		private var startlatp:Number;
		private var parallelise:Parallelise;
		private var originalWay:Way;

        /** Initialises by parallelising the originalWay. */
        public function SelectedParallelWay(originalWay:Way) {
			this.originalWay = originalWay;
			parallelise = new Parallelise(originalWay);
			super (parallelise.parallelWay);
        }

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.MOUSE_UP) {
				var lon:Number =controller.map.coord2lon(controller.map.mouseX);
				var latp:Number=controller.map.coord2latp(controller.map.mouseY);
				parallelise.draw(originalWay.distanceFromWay(lon,latp).distance);
			}
			if (event.type==MouseEvent.MOUSE_UP) {
				return new SelectedWay(firstSelected as Way);
			}
			return this;
        }

		/** Cancel parallel way creation if ESC pressed. */
		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==Keyboard.ESCAPE) {
				Way(firstSelected).remove(MainUndoStack.getGlobalStack().addAction);
				// Parallel way wasn't created, so remove it from undo history.
				MainUndoStack.getGlobalStack().removeLastIfAction(DeleteWayAction);
                MainUndoStack.getGlobalStack().removeLastIfAction(CreateEntityAction);
				
				return new NoSelection();
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		/** Creates the WayUI for the parallel way. */
		override public function enterState():void {
			selection=[parallelise.parallelWay];
			layer.createWayUI(firstSelected as Way);
			startlon =controller.map.coord2lon(controller.map.mouseX);
			startlatp=controller.map.coord2latp(controller.map.mouseY);
        }
		/** Unselects. */
		override public function exitState(newState:ControllerState):void {
            clearSelection(newState);
        }

        override public function toString():String {
            return "SelectedParallelWay";
        }
    }
}
