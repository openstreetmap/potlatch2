package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedWayNode extends SelectedWay {
		protected var selectedIndex:int;
		protected var initIndex:int;
        
        public function SelectedWayNode(way:Way,index:int) {
			super (way);
			initIndex = index;
        }
 
        protected function selectNode(way:Way,index:int):void {
			var node:Node=way.getNode(index);
            if ( way == selectedWay && node == selectedNode )
                return;

            clearSelection(this);
            controller.setSelectedEntity(node);
            controller.map.setHighlight(way, { hover: false });
            controller.map.setHighlight(node, { selected: true });
            controller.map.setHighlightOnNodes(way, { selectedway: true });
            selectedWay = way; initWay = way;
			selectedIndex = index; initIndex = index;
            selectedNode = node;
        }
                
        override protected function clearSelection(newState:ControllerState):void {
            if ( selectedNode != null ) {
            	controller.map.setHighlight(selectedWay, { selected: false });
				controller.map.setHighlight(selectedNode, { selected: false });
				controller.map.setHighlightOnNodes(selectedWay, { selectedway: false });
                if (!newState.isSelectionState()) { controller.setSelectedEntity(null); }
                selectedNode = null;
				selectedWay = null;
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
			} else if ( event.type == MouseEvent.MOUSE_UP && entity is Node && focus == selectedWay ) {
				// select node within way
				return selectOrEdit(selectedWay, getNodeIndex(selectedWay,Node(entity)));
            } else if ( event.type == MouseEvent.MOUSE_DOWN && entity is Way && focus==selectedWay && event.shiftKey) {
				// insert node within way (shift-click)
          		var d:DragWayNode=new DragWayNode(selectedWay, addNode(event), event, true);
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
				case 82:					repeatTags(selectedNode); return this;	// 'R'
				case Keyboard.BACKSPACE:	return deleteNode();
				case Keyboard.DELETE:		return deleteNode();
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		override public function enterState():void {
            selectNode(initWay,initIndex);
			controller.map.setPurgable(selectedNode,false);
			Globals.vars.root.addDebug("**** -> "+this);
        }
		override public function exitState(newState:ControllerState):void {
			controller.clipboards['node']=selectedNode.getTagsCopy();
			controller.map.setPurgable(selectedNode,true);
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
			isLast = selectedWay.getNode(selectedWay.length - 1) == node;
			if ( isFirst == isLast )    // both == looped, none == central node 
			    return new SelectedWayNode(selectedWay, index);
			else
			    return new DrawWay(selectedWay, isLast, true);
        }

		public function splitWay():ControllerState {
			// abort if start or end
			if (selectedWay.getNode(0                   ) == selectedNode) { return this; }
			if (selectedWay.getNode(selectedWay.length-1) == selectedNode) { return this; }

			controller.map.setHighlightOnNodes(selectedWay, { selectedway: false } );
			controller.map.setPurgable(selectedWay,true);
            MainUndoStack.getGlobalStack().addAction(new SplitWayAction(selectedWay, selectedNode));

			return new SelectedWay(selectedWay);
		}
		
		public function removeNode():ControllerState {
			if (selectedNode.numParentWays==1 && selectedWay.hasOnceOnly(selectedNode)) {
				return deleteNode();
			}
			selectedWay.removeNodeByIndex(selectedIndex, MainUndoStack.getGlobalStack().addAction);
			return new SelectedWay(selectedWay);
		}
		
		public function deleteNode():ControllerState {
			controller.map.setPurgable(selectedNode,true);
			selectedNode.remove(MainUndoStack.getGlobalStack().addAction);
			return new SelectedWay(selectedWay);
		}

    }
}
