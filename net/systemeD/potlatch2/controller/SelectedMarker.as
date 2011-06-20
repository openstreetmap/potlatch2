package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapPaint;

    public class SelectedMarker extends ControllerState {
        protected var initMarker:Marker;

        public function SelectedMarker(marker:Marker, layer:MapPaint) {
            initMarker = marker;
            this.layer = layer;
        }

        protected function selectMarker(marker:Marker):void {
            if ( firstSelected is Marker && Marker(firstSelected)==marker )
                return;

            clearSelection(this);
            layer.setHighlight(marker, { selected: true });
            selection = [marker];
            controller.updateSelectionUI(layer);
            initMarker = marker;
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
            if ( (event.type==MouseEvent.MOUSE_UP || event.type==MouseEvent.CLICK) && entity==initMarker ) { return this; }
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
			layer.setPurgable(selection,false);
        }

        override public function exitState(newState:ControllerState):void {
			layer.setPurgable(selection,true);
            clearSelection(newState);
        }

        override public function toString():String {
            return "SelectedMarker";
        }

    }
}
