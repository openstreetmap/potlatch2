package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapPaint;

    public class SelectedPOINode extends ControllerState {
        protected var initNode:Node;

        public function SelectedPOINode(node:Node, layer:MapPaint=null) {
			if (layer) this.layer=layer;
            initNode = node;
        }
 
        protected function selectNode(node:Node):void {
            if ( firstSelected is Node && Node(firstSelected)==node )
                return;

            clearSelection(this);
            layer.setHighlight(node, { selected: true });
            selection = [node];
            controller.updateSelectionUI();
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
			var paint:MapPaint = getMapPaint(DisplayObject(event.target));

			if (event.type==MouseEvent.MOUSE_DOWN && event.ctrlKey && entity && entity!=firstSelected && paint==layer) {
				return new SelectedMultiple([firstSelected,entity],layer);
			} else if (event.type==MouseEvent.MOUSE_DOWN && event.shiftKey && !entity && !layer.isBackground) {
				return new DrawQuadrilateral(firstSelected as Node);
			} else if ( event.type == MouseEvent.MOUSE_UP && entity==firstSelected ) {
				return this;
			}
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
			firstSelected.connection.unregisterPOI(firstSelected as Node);
			firstSelected.remove(MainUndoStack.getGlobalStack().addAction);
			return new NoSelection();
		}

        override public function enterState():void {
            selectNode(initNode);
			layer.setPurgable(selection,false);
        }
        override public function exitState(newState:ControllerState):void {
            if(firstSelected.hasTags()) {
              controller.clipboards['node']=firstSelected.getTagsCopy();
            }
			layer.setPurgable(selection,true);
            clearSelection(newState);
        }

        override public function toString():String {
            return "SelectedPOINode";
        }

    }
}
