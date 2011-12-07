package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import net.systemeD.halcyon.AttentionEvent;
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
            layer.setHighlight(way, { hover: false });
            layer.setHighlight(node, { selected: true });
            layer.setHighlightOnNodes(way, { selectedway: true });
            selection = [node]; parentWay = way;
            controller.updateSelectionUI();
			selectedIndex = index; initIndex = index;
        }
                
        protected function clearSelection(newState:ControllerState):void {
            if ( selectCount ) {
            	layer.setHighlight(parentWay, { selected: false });
				layer.setHighlight(firstSelected, { selected: false });
				layer.setHighlightOnNodes(parentWay, { selectedway: false });
				selection = [];
                if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP && entity is Node && event.shiftKey ) {
				// start new way
                var way:Way = entity.connection.createWay({}, [entity],
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
				case 79:					return replaceNode();					// 'O'
                case 81:  /* Q */           Quadrilateralise.quadrilateralise(parentWay, MainUndoStack.getGlobalStack().addAction); return this;
				case 82:					repeatTags(firstSelected); return this;	// 'R'
				case 87:					return new SelectedWay(parentWay);		// 'W'
				case 191:					return cycleWays();						// '/'
                case 74:                    if (event.shiftKey) { return unjoin() }; return join();// 'J'
				case Keyboard.BACKSPACE:	return deleteNode();
				case Keyboard.DELETE:		return deleteNode();
				case 188: /* , */           return stepNode(-1);
				case 190: /* . */           return stepNode(+1);           
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		override public function get selectedWay():Way {
			return parentWay;
		}

        public function get selectedNode():Node {
            return parentWay.getNode(selectedIndex);
        }
        
		private function cycleWays():ControllerState {
			var wayList:Array=firstSelected.parentWays;
			if (wayList.length==1) { return this; }
			wayList.splice(wayList.indexOf(parentWay),1);
            // find index of this node in the newly selected way, to maintain state for keyboard navigation
            var newindex:int = Way(wayList[0]).indexOfNode(parentWay.getNode(initIndex));
			return new SelectedWay(wayList[0], layer,
			                       new Point(controller.map.lon2coord(Node(firstSelected).lon),
			                                 controller.map.latp2coord(Node(firstSelected).latp)),
			                       wayList.concat(parentWay),
			                       newindex);
		}

		override public function enterState():void {
            selectNode(parentWay,initIndex);
			layer.setPurgable(selection,false);
        }
		override public function exitState(newState:ControllerState):void {
            if (firstSelected.hasTags()) {
              controller.clipboards['node']=firstSelected.getTagsCopy();
            }
			layer.setPurgable(selection,true);
            clearSelection(newState);
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

		/** Replace the selected node with a new one created at the mouse position. 
			The undo for this is two actions: first, replacement of the old node at the original mouse position; then, moving to the new position.
			It's debatable whether this should be one or two but we can leave it as a FIXME for now.  */
		public function replaceNode():ControllerState {
			// replace old node
			var oldNode:Node=firstSelected as Node;
			var newNode:Node=oldNode.replaceWithNew(layer.connection,
			                                        controller.map.coord2lat(layer.mouseY), 
			                                        controller.map.coord2lon(layer.mouseX), {},
			                                        MainUndoStack.getGlobalStack().addAction);

			// start dragging
			// we fake a MouseEvent because DragWayNode expects the x/y co-ords to be passed that way
			var d:DragWayNode=new DragWayNode(parentWay, parentWay.indexOfNode(newNode), new MouseEvent(MouseEvent.CLICK, true, false, layer.mouseX, layer.mouseY), true);
			d.forceDragStart();
			return d;
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

			layer.setHighlightOnNodes(parentWay, { selectedway: false } );
			layer.setPurgable([parentWay],true);
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
			layer.setPurgable(selection,true);
			firstSelected.remove(MainUndoStack.getGlobalStack().addAction);
			return new SelectedWay(parentWay);
		}

        public function unjoin():ControllerState {
            Node(firstSelected).unjoin(parentWay, MainUndoStack.getGlobalStack().addAction);
            return this;
        }

        /** Attempt to either merge the currently selected node with another very nearby node, or failing that,
        *   attach it mid-way along a very nearby way. */
		// FIXME: why are we only merging one node at once? after all, shift-click to insert a node adds into all ways
        public function join():ControllerState {
			var p:Point = new Point(controller.map.lon2coord(Node(firstSelected).lon),
			                        controller.map.latp2coord(Node(firstSelected).latp));
            var q:Point = map.localToGlobal(p);

            // First, look for POI nodes in 20x20 pixel box around the current node
			// FIXME: why aren't we using a hitTest for this?
            var hitnodes:Array = layer.connection.getObjectsByBbox(
                map.coord2lon(p.x-10),
                map.coord2lon(p.x+10),
                map.coord2lat(p.y-10),
                map.coord2lat(p.y+10)).poisInside;
            
            for each (var n: Node in hitnodes) {
                if (!n.hasParent(selectedWay)) { 
                   return doMergeNodes(n);
                }
            }
            
			var ways:Array=layer.findWaysAtPoint(q.x, q.y, selectedWay);
			for each (var w:Way in ways) {
                // hit a way, now let's see if we hit a specific node
                for (var i:uint = 0; i < w.length; i++) {
					n = w.getNode(i);
					var x:Number = map.lon2coord(n.lon);
					var y:Number = map.latp2coord(n.latp);
					if (n != selectedNode && Math.abs(x-p.x) + Math.abs(y-p.y) < 10) {
						return doMergeNodes(n);
					}
				}
            }

            // No nodes hit, so join our node onto any overlapping ways.
            Node(firstSelected).join(ways,MainUndoStack.getGlobalStack().addAction);
            return this;
        }
        
        private function doMergeNodes(n:Node): ControllerState {
        	n.mergeWith(Node(firstSelected), MainUndoStack.getGlobalStack().addAction);
            // only merge one node at a time - too confusing otherwise?
            var msg:String = "Nodes merged"
            if (MergeNodesAction.lastTagsMerged) msg += ": check conflicting tags";
            controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, msg));
			if (n.isDeleted()) n=Node(firstSelected);
            return new SelectedWayNode(n.parentWays[0], Way(n.parentWays[0]).indexOfNode(n));
        }
        
        /** Move the selection one node further up or down this way, looping if necessary. */
        public function stepNode(delta:int):ControllerState {
            var ni:int = (selectedIndex + delta + parentWay.length) %  parentWay.length
            controller.map.scrollIfNeeded(parentWay.getNode(ni).lat,parentWay.getNode(ni).lon);
            return new SelectedWayNode(parentWay, ni);
        }

    }
    
    
}

