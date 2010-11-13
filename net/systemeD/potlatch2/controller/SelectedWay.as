package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.potlatch2.tools.Parallelise;
    import net.systemeD.potlatch2.tools.Simplify;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.Globals;

    public class SelectedWay extends ControllerState {
        protected var initWay:Way;
        
        public function SelectedWay(way:Way) {
            initWay = way;
        }
 
        protected function selectWay(way:Way):void {
            if ( firstSelected is Way && Way(firstSelected)==way )
                return;

            clearSelection(this);
            controller.map.setHighlight(way, { selected: true, hover: false });
            controller.map.setHighlightOnNodes(way, { selectedway: true });
            selection = [way];
            controller.updateSelectionUI();
            initWay = way;
        }

        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
            	controller.map.setHighlight(firstSelected, { selected: false, hover: false });
            	controller.map.setHighlightOnNodes(firstSelected as Way, { selectedway: false });
                selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP && entity is Node && event.shiftKey ) {
				// start new way
				var way:Way = controller.connection.createWay({}, [entity], MainUndoStack.getGlobalStack().addAction);
				return new DrawWay(way, true, false);
			} else if ( event.type == MouseEvent.MOUSE_DOWN && entity is Way && focus==firstSelected && event.shiftKey) {
				// insert node within way (shift-click)
                var d:DragWayNode=new DragWayNode(firstSelected as Way, -1, event, true);
				d.forceDragStart();
				return d;
			} else if ( event.type == MouseEvent.MOUSE_DOWN && entity is Way && event.shiftKey ) {
				// merge way
				return mergeWith(entity as Way);
			} else if ( event.type == MouseEvent.MOUSE_DOWN && event.ctrlKey && entity!=firstSelected) {
				// multiple selection
				return new SelectedMultiple([firstSelected,entity]);
			}
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
        }
        
		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 80:					return new SelectedParallelWay(firstSelected as Way);
				case 82:					repeatTags(firstSelected); return this;
                case 86:                    Way(firstSelected).reverseNodes(MainUndoStack.getGlobalStack().addAction); return this;
                case 89:                    Simplify.simplify(firstSelected as Way, controller.map, true); return this;         
				case Keyboard.BACKSPACE:	if (event.shiftKey) { return deleteWay(); } break;
				case Keyboard.DELETE:		if (event.shiftKey) { return deleteWay(); } break;
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		protected function mergeWith(otherWay:Way):ControllerState {
			var way1:Way;
			var way2:Way;
			if ( firstSelected.id < otherWay.id && firstSelected.id >= 0 ) {
			    way1 = firstSelected as Way;
			    way2 = otherWay;
			} else {
			    way1 = otherWay;
			    way2 = firstSelected as Way;
			}
			
			var undo:Function = MainUndoStack.getGlobalStack().addAction;
			
			// find common point
			if (way1 == way2) { return this; }
			if      (way1.getNode(0)   ==way2.getNode(0)   ) { way1.mergeWith(way2,0,0,undo); }
			else if (way1.getNode(0)   ==way2.getLastNode()) { way1.mergeWith(way2,0,way2.length-1,undo); }
			else if (way1.getLastNode()==way2.getNode(0)   ) { way1.mergeWith(way2,way1.length-1,0,undo); }
			else if (way1.getLastNode()==way2.getLastNode()) { way1.mergeWith(way2,way1.length-1,way2.length-1,undo); }
			return new SelectedWay(way1);
		}
        
		public function deleteWay():ControllerState {
			controller.map.setHighlightOnNodes(firstSelected as Way, {selectedway: false});
			selectedWay.remove(MainUndoStack.getGlobalStack().addAction);
			return new NoSelection();
		}

        override public function enterState():void {
            selectWay(initWay);
			controller.map.setPurgable(selection,false);
			Globals.vars.root.addDebug("**** -> "+this+" "+firstSelected.id);
        }
        override public function exitState(newState:ControllerState):void {
			controller.clipboards['way']=firstSelected.getTagsCopy();
			controller.map.setPurgable(selection,true);
            clearSelection(newState);
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWay";
        }

    }
}
