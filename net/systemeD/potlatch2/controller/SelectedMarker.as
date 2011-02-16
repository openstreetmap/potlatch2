package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.VectorLayer;

    public class SelectedMarker extends ControllerState {
        protected var initMarker:Marker;
        protected var layer:VectorLayer;

        public function SelectedMarker(marker:Marker, layer:VectorLayer) {
            initMarker = marker;
            this.layer = layer;
        }

        protected function selectMarker(marker:Marker):void {
            if ( firstSelected is Marker && Marker(firstSelected)==marker )
                return;

            clearSelection(this);
            controller.map.setHighlight(marker, { selected: true });
            selection = [marker];
            controller.updateSelectionUI(layer);
            initMarker = marker;
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
            selectMarker(initMarker);
			controller.map.setPurgable(selection,false);
        }

        override public function exitState(newState:ControllerState):void {
			controller.map.setPurgable(selection,true);
            clearSelection(newState);
        }

        override public function toString():String {
            return "SelectedMarker";
        }

    }
}
