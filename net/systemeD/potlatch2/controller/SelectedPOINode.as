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
            if ( node == selectedNode )
                return;

            clearSelection();
            controller.setSelectedEntity(node);
            controller.map.setHighlight(node, { selected: true });
            selectedNode = node;
            initNode = node;
        }
                
        protected function clearSelection():void {
            if ( selectedNode != null ) {
                controller.map.setHighlight(selectedNode, { selected: false });
                controller.setSelectedEntity(null);
                selectedNode = null;
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
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		public function deletePOI():ControllerState {
			controller.connection.unregisterPOI(selectedNode);
			selectedNode.remove(MainUndoStack.getGlobalStack().addAction);
			return new NoSelection();
		}
		
        override public function enterState():void {
            selectNode(initNode);
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedPOINode";
        }

    }
}
