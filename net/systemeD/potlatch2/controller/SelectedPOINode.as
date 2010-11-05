package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedPOINode extends ControllerState {
        protected var initNode:Node;

        public function SelectedPOINode(node:Node) {
            initNode = node;
        }
 
        protected function selectNode(node:Node):void {
            if ( firstSelected is Node && Node(firstSelected)==node )
                return;

            clearSelection(this);
            controller.map.setHighlight(node, { selected: true });
            selection = [node];
            controller.updateSelectionUI();
            initNode = node;
        }
                
        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
                controller.map.setHighlight(firstSelected, { selected: false });
                selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE) { return this; }
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case Keyboard.BACKSPACE:	return deletePOI();
				case Keyboard.DELETE:		return deletePOI();
				case 82:					repeatTags(firstSelected); return this;	// 'R'
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		public function deletePOI():ControllerState {
			controller.connection.unregisterPOI(firstSelected as Node);
			firstSelected.remove(MainUndoStack.getGlobalStack().addAction);
			return new NoSelection();
		}

        override public function enterState():void {
            selectNode(initNode);
			controller.map.setPurgable(selection,false);
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState(newState:ControllerState):void {
			controller.clipboards['node']=firstSelected.getTagsCopy();
			controller.map.setPurgable(selection,true);
            clearSelection(newState);
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedPOINode";
        }

    }
}
