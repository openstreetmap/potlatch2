package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.potlatch2.tools.Quadrilateralise;

    public class SelectedWayNode extends ControllerState {
		private var parentWay:Way;
		private var initIndex:int;
		private var selectedIndex:int;
        
        public function SelectedWayNode(way:Way,index:int) {
            parentWay = way;
			initIndex = index;
        }
 
        protected function selectNode(way:Way,index:int):void {
			var node:Node=way.getNode(index);
            if ( way == parentWay && node == firstSelected )
                return;

            clearSelection(this);
            controller.map.setHighlight(way, { hover: false });
            controller.map.setHighlight(node, { selected: true });
            controller.map.setHighlightOnNodes(way, { selectedway: true });
            selection = [node]; parentWay = way;
            controller.updateSelectionUI();
			selectedIndex = index; initIndex = index;
        }
                
        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
            	controller.map.setHighlight(parentWay, { selected: false });
				controller.map.setHighlight(firstSelected, { selected: false });
				controller.map.setHighlightOnNodes(parentWay, { selectedway: false });
				selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP && entity is Node && event.shiftKey ) {
				// start new way
                var way:Way = controller.connection.createWay({}, [entity],
                    MainUndoStack.getGlobalStack().addAction);
                return new DrawWay(way, true, false);
			} else if ( event.type == MouseEvent.MOUSE_UP && entity is Node && focus == parentWay ) {
				// select node within way
				return selectOrEdit(parentWay, getNodeIndex(parentWay,Node(entity)));
            } else if ( event.type == MouseEvent.MOUSE_DOWN && entity is Way && focus==parentWay && event.shiftKey) {
				// insert node within way (shift-click)
          		var d:DragWayNode=new DragWayNode(parentWay, -1, event, true);
				d.forceDragStart();
				return d;
			}
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 189:					return removeNode();					// '-'
				case 88:					return splitWay();						// 'X'
                case 81:  /* Q */           Quadrilateralise.quadrilateralise(parentWay, MainUndoStack.getGlobalStack().addAction); return this;
				case 82:					repeatTags(firstSelected); return this;	// 'R'
				case 87:					return new SelectedWay(parentWay);		// 'W'
				case 191:					return cycleWays();						// '/'
                case 74:                    if (event.shiftKey) { return unjoin() }; return join();// 'J'
				case Keyboard.BACKSPACE:	return deleteNode();
				case Keyboard.DELETE:		return deleteNode();
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		override public function get selectedWay():Way {
			return parentWay;
		}

		private function cycleWays():ControllerState {
			var wayList:Array=firstSelected.parentWays;
			if (wayList.length==1) { return this; }
			wayList.splice(wayList.indexOf(parentWay),1);
			return new SelectedWay(wayList[0],
			                       new Point(controller.map.lon2coord(Node(firstSelected).lon),
			                                 controller.map.latp2coord(Node(firstSelected).latp)),
			                       wayList.concat(parentWay));
		}

		override public function enterState():void {
            selectNode(parentWay,initIndex);
			controller.map.setPurgable(selection,false);
			Globals.vars.root.addDebug("**** -> "+this);
        }
		override public function exitState(newState:ControllerState):void {
            if (firstSelected.hasTags()) {
              controller.clipboards['node']=firstSelected.getTagsCopy();
            }
			controller.map.setPurgable(selection,true);
            clearSelection(newState);
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWayNode";
        }

		public static function selectOrEdit(selectedWay:Way, index:int):ControllerState {
			var isFirst:Boolean = false;
			var isLast:Boolean = false;
			var node:Node = selectedWay.getNode(index);
			isFirst = selectedWay.getNode(0) == node;
			isLast = selectedWay.getLastNode() == node;
			if ( isFirst == isLast )    // both == looped, none == central node 
			    return new SelectedWayNode(selectedWay, index);
			else
			    return new DrawWay(selectedWay, isLast, true);
        }

		/** Splits a way into two separate ways, at the currently selected node. Handles simple loops and P-shapes. Untested for anything funkier. */
		public function splitWay():ControllerState {
			var n:Node=firstSelected as Node;
			var ni:uint = parentWay.indexOfNode(n);
			// abort if start or end
			if (parentWay.isPShape() && !parentWay.hasOnceOnly(n)) {
				// If P-shaped, we want to split at the midway point on the stem, not at the end of the loop
				ni = parentWay.getPJunctionNodeIndex();
				
			} else {
			    if (parentWay.getNode(0)    == n) { return this; }
			    if (parentWay.getLastNode() == n) { return this; }
			}

			controller.map.setHighlightOnNodes(parentWay, { selectedway: false } );
			controller.map.setPurgable([parentWay],true);
            MainUndoStack.getGlobalStack().addAction(new SplitWayAction(parentWay, ni));

			return new SelectedWay(parentWay);
		}
		
		public function removeNode():ControllerState {
			if (firstSelected.numParentWays==1 && parentWay.hasOnceOnly(firstSelected as Node) && !(firstSelected as Node).hasInterestingTags()) {
				return deleteNode();
			}
			parentWay.removeNodeByIndex(selectedIndex, MainUndoStack.getGlobalStack().addAction);
			return new SelectedWay(parentWay);
		}
		
		public function deleteNode():ControllerState {
			controller.map.setPurgable(selection,true);
			firstSelected.remove(MainUndoStack.getGlobalStack().addAction);
			return new SelectedWay(parentWay);
		}

        public function unjoin():ControllerState {
            Node(firstSelected).unjoin(parentWay, MainUndoStack.getGlobalStack().addAction);
            return this;
        }

        public function join():ControllerState {
            // detect the ways that overlap this node
            var p:Point = new Point(controller.map.lon2coord(Node(firstSelected).lon),
                                             controller.map.latp2coord(Node(firstSelected).latp));
            var q:Point = map.localToGlobal(p);
            var ways:Array=[]; var w:Way;
            for each (var wayui:WayUI in controller.map.paint.wayuis) {
                w=wayui.hitTest(q.x, q.y);
                if (w && w!=selectedWay) { ways.push(w); }
            }

            Node(firstSelected).join(ways,MainUndoStack.getGlobalStack().addAction);
            return this;
        }
    }
}
