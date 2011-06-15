package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapPaint;

    public class SelectedBackgroundNode extends ControllerState {
        protected var initNode:Node;

        public function SelectedBackgroundNode(node:Node, layer:MapPaint) {
            initNode = node;
            this.layer = layer;
        }

        protected function selectNode(node:Node):void {
            if ( firstSelected is Node && Node(firstSelected)==node )
                return;

            clearSelection(this);
            layer.setHighlight(node, { selected: true });
            selection = [node];
            controller.updateSelectionUI(layer);
            initNode = node;
        }

        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
                layer.setHighlight(firstSelected, { selected: false });
                selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE) { return this; }
            if (event.type==MouseEvent.MOUSE_UP) { return this; }
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		public function deletePOI():ControllerState {
			return new NoSelection();
		}

        override public function enterState():void {
            selectNode(initNode);
			layer.setPurgable(selection,false);
        }

        override public function exitState(newState:ControllerState):void {
			layer.setPurgable(selection,true);
            clearSelection(newState);
        }

        override public function toString():String {
            return "SelectedBackgroundNode";
        }

    }
}
