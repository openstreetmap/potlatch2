package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.MapPaint;

    /** Behaviour that takes place while a way is selected includes: adding a node to the way, straightening/reshaping the way, dragging it. */
    public class SelectedBackgroundWay extends ControllerState {
        /** The selected way itself. */
        protected var initWay:Way;
        private var clicked:Point;		// did the user enter this state by clicking at a particular point?
		private var wayList:Array;		// list of ways to cycle through with '/' keypress
		private var initIndex: int;     // index of last selected node if entered from SelectedWayNode
        
        /** 
        * @param way The way that is now selected.
        * @param point The location that was clicked.
        * @param ways An ordered list of ways sharing a node, to make "way cycling" work. */
        public function SelectedBackgroundWay(way:Way, layer:MapPaint, point:Point=null, ways:Array=null, index:int=0) {
            initWay = way;
			clicked = point;
			wayList = ways;
			initIndex=index;
			this.layer = layer;
        }

        private function updateSelectionUI(e:Event):void {
            controller.updateSelectionUIWithoutTagChange();
        }

        /** Tidy up UI as we transition to a new state without the current selection. */
        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
            	layer.setHighlight(firstSelected, { selected: false, hover: false });
            	layer.setHighlightOnNodes(firstSelected as Way, { selectedway: false });
                selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }
        
        /** The only things we want to do here are deselect and stay selected */
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            if (event.type==MouseEvent.MOUSE_MOVE) { return this; }
            if (event.type==MouseEvent.MOUSE_UP) { return this; }
            var cs:ControllerState = sharedMouseEvents(event, entity);
            return cs ? cs : this;
        }
        
		/** TODO - key press for "completing" a way */
		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {


            }
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

        /** Officially enter this state by marking the previously nominated way as selected. */
        override public function enterState():void {
            if (firstSelected!=initWay) {
                clearSelection(this);
                layer.setHighlight(initWay, { selected: true, hover: false });
	            layer.setHighlightOnNodes(initWay, { selectedway: true });
	            selection = [initWay];
	            controller.updateSelectionUI();
			}
			layer.setPurgable(selection,false);
        }
        
        /** Officially leave the state */
        override public function exitState(newState:ControllerState):void {
            layer.setPurgable(selection,true);
            clearSelection(newState);
        }

        /** @return "SelectedWay" */
        override public function toString():String {
            return "SelectedBackgroundWay";
        }

    }
}
