package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;
	import flash.geom.Point;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.potlatch2.tools.Parallelise;
    import net.systemeD.potlatch2.tools.Simplify;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.Globals;

    public class SelectedWay extends ControllerState {
        protected var initWay:Way;
        private var clicked:Point;		// did the user enter this state by clicking at a particular point?
		private var wayList:Array;		// list of ways to cycle through with '/' keypress
        
        public function SelectedWay(way:Way, point:Point=null, ways:Array=null) {
            initWay = way;
			clicked = point;
			wayList = ways;
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
			} else if ( event.type == MouseEvent.MOUSE_DOWN && event.ctrlKey && entity && entity!=firstSelected) {
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
				case 191:					return cycleWays();
				case Keyboard.BACKSPACE:	if (event.shiftKey) { return deleteWay(); } break;
				case Keyboard.DELETE:		if (event.shiftKey) { return deleteWay(); } break;
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
        
		private function cycleWays():ControllerState {
			if (!clicked || (wayList && wayList.length<2)) { return this; }

			if (!wayList) {
				wayList=[initWay];
				for each (var wayui:WayUI in controller.map.paint.wayuis) {
					var w:Way=wayui.hitTest(clicked.x, clicked.y);
					if (w && w!=initWay) { wayList.push(w); }
				}
			}
			wayList=wayList.slice(1).concat(wayList[0]);
			return new SelectedWay(wayList[0], clicked, wayList);
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
			if (firstSelected.hasTags()) {
              controller.clipboards['way']=firstSelected.getTagsCopy();
            }
			controller.map.setPurgable(selection,true);
            clearSelection(newState);
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWay";
        }

    }
}
