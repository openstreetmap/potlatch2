package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.collections.Imagery;
    import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.potlatch2.save.SaveManager;
	import flash.ui.Keyboard;
    /** Represents a particular state of the controller, such as "dragging a way" or "nothing selected". Key methods are 
    * processKeyboardEvent and processMouseEvent which take some action, and return a new state for the controller. 
    * 
    * This abstract class has some behaviour that applies in most states, and lots of 'null' behaviour. 
    * */
    public class ControllerState {

        protected var controller:EditController;
        protected var previousState:ControllerState;

		protected var _selection:Array=[];

        public function ControllerState() {}

        public function setController(controller:EditController):void {
            this.controller = controller;
        }

        public function setPreviousState(previousState:ControllerState):void {
            if ( this.previousState == null )
                this.previousState = previousState;
        }

		public function isSelectionState():Boolean {
			return true;
		}

        /** When triggered by a mouse action such as a click, perform an action on the given entity, then move to a new state. */
        public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            return this;
        }
		
		/** When triggered by a keypress, perform an action on the given entity, then move to a new state. */
        public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
            return this;
        }

		public function get map():Map {
			return controller.map;
		}

        public function enterState():void {}
        public function exitState(newState:ControllerState):void {}

		/** Represent the state in text for debugging. */
		public function toString():String {
			return "(No state)";
		}
		/** Default behaviour for the current state that should be called if state-specific action has been taken care of or ruled out. */
		protected function sharedKeyboardEvents(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 66:	setSourceTag(); break;													// B - set source tag for current object
				case 67:	controller.connection.closeChangeset(); break;							// C - close changeset
				case 68:	controller.map.paint.alpha=1.3-controller.map.paint.alpha; return null;	// D - dim
				case 83:	SaveManager.saveChanges(); break;										// S - save
				case 84:	controller.tagViewer.togglePanel(); return null;						// T - toggle tags panel
				case 90:	MainUndoStack.getGlobalStack().undo(); return null;						// Z - undo
				case Keyboard.NUMPAD_ADD:															// + - add tag
				case 187:	controller.tagViewer.selectAdvancedPanel();								//   |
							controller.tagViewer.addNewTag(); return null;							//   |
			}
			return null;
		}

		/** Default behaviour for the current state that should be called if state-specific action has been taken care of or ruled out. */
		protected function sharedMouseEvents(event:MouseEvent, entity:Entity):ControllerState {
			var paint:MapPaint = getMapPaint(DisplayObject(event.target));
            var focus:Entity = getTopLevelFocusEntity(entity);

			if ( paint && paint.isBackground ) {
				if ( event.type == MouseEvent.MOUSE_DOWN && ((event.shiftKey && event.ctrlKey) || event.altKey) ) {
					// alt-click to pull data out of vector background layer
					var newEntity:Entity=paint.findSource().pullThrough(entity,controller.connection);
					if (entity is Way) { return new SelectedWay(newEntity as Way); }
					else if (entity is Node) { return new SelectedPOINode(newEntity as Node); }
                } else if (event.type == MouseEvent.MOUSE_DOWN && entity is Marker) {
                    return new SelectedMarker(entity as Marker, paint.findSource());
				} else if ( event.type == MouseEvent.MOUSE_UP ) {
					return (this is NoSelection) ? null : new NoSelection();
				} else { return null; }
			}

			if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Node && selectedWay && entity.hasParent(selectedWay) ) {
					// select node within this way
                	return new DragWayNode(selectedWay,  getNodeIndex(selectedWay,entity as Node),  event, false);
				} else if ( entity is Node && focus is Way ) {
					// select way node
					return new DragWayNode(focus as Way, getNodeIndex(focus as Way,entity as Node), event, false);
				} else if ( controller.keyDown(Keyboard.SPACE) ) {
					// drag the background imagery to compensate for poor alignment
					return new DragBackground(event);
				} else if (entity && selection.indexOf(entity)>-1) {
					return new DragSelection(selection, event);
				} else if (entity) {
					return new DragSelection([entity], event);
				}
            } else if ( event.type == MouseEvent.CLICK && focus == null && map.dragstate!=map.DRAGGING && this is SelectedMarker) {
                // this is identical to the below, but needed for unselecting markers on vector background layers.
                // Deselecting a POI or way on the main layer emits both CLICK and MOUSE_UP, but markers only CLICK
                // I'll leave it to someone who understands to decide whether they are the same thing and should be
                // combined with a (CLICK || MOUSE_UP)
                
                // "&& this is SelectedMarker" added by Steve Bennett. The CLICK event being processed for SelectedWay state
                // causes way to get unselected...so restrict the double processing as much as possible.  
                
                return (this is NoSelection) ? null : new NoSelection();
			} else if ( event.type == MouseEvent.MOUSE_UP && focus == null && map.dragstate!=map.DRAGGING) {
				return (this is NoSelection) ? null : new NoSelection();
			} else if ( event.type == MouseEvent.MOUSE_UP && focus && map.dragstate!=map.NOT_DRAGGING) {
				map.mouseUpHandler();	// in case the end-drag is over an EntityUI
			} else if ( event.type == MouseEvent.ROLL_OVER ) {
				controller.map.setHighlight(focus, { hover: true });
			} else if ( event.type == MouseEvent.MOUSE_OUT ) {
				controller.map.setHighlight(focus, { hover: false });
            } else if ( event.type == MouseEvent.MOUSE_WHEEL ) {
                if (event.delta > 0) {
                  map.zoomIn();
                } else if (event.delta < 0) {
                  map.zoomOut();
                }
            }
			return null;
		}

		/** Gets the way that the selected node is part of, if that makes sense. If not, return the node, or the way, or nothing. */
		public static function getTopLevelFocusEntity(entity:Entity):Entity {
			if ( entity is Node ) {
				for each (var parent:Entity in entity.parentWays) {
					return parent;
				}
				return entity;
			} else if ( entity is Way ) {
				return entity;
			} else {
				return null;
			}
		}

		/** Find the MapPaint object that this DisplayObject belongs to. */
		protected function getMapPaint(d:DisplayObject):MapPaint {
			while (d) {
				if (d is MapPaint) { return MapPaint(d); }
				d=d.parent;
			}
			return null;
		}

		protected function getNodeIndex(way:Way,node:Node):uint {
			for (var i:uint=0; i<way.length; i++) {
				if (way.getNode(i)==node) { return i; }
			}
			return null;
		}

		/** Create a "repeat tags" action on the current entity, if possible. */
		protected function repeatTags(object:Entity):void {
			if (!controller.clipboards[object.getType()]) { return; }
			object.suspend();

		    var undo:CompositeUndoableAction = new CompositeUndoableAction("Repeat tags");
			for (var k:String in controller.clipboards[object.getType()]) {
				object.setTag(k, controller.clipboards[object.getType()][k], undo.push)
			}
			MainUndoStack.getGlobalStack().addAction(undo);
                        controller.updateSelectionUI();
			object.resume();


		}

		/** Create an action to add "source=*" tag to current entity based on background imagery. This is a convenient shorthand for users. */
		protected function setSourceTag():void {
			if (selectCount!=1) { return; }
			if (Imagery.instance().selected && Imagery.instance().selected.sourcetag) {
				firstSelected.setTag('source',Imagery.instance().selected.sourcetag, MainUndoStack.getGlobalStack().addAction);
			}
			controller.updateSelectionUI();
		}

		// Selection getters

		public function get selectCount():uint {
			return _selection.length;
		}

		public function get selection():Array {
			return _selection;
		}

		public function get firstSelected():Entity {
			if (_selection.length==0) { return null; }
			return _selection[0];
		}

		public function get selectedWay():Way {
			if (firstSelected is Way) { return firstSelected as Way; }
			return null;
		}

		public function get selectedWays():Array {
			var selectedWays:Array=[];
			for each (var item:Entity in _selection) {
				if (item is Way) { selectedWays.push(item); }
			}
			return selectedWays;
		}

        public function get selectedNodes():Array {
            var selectedNodes:Array=[];
            for each (var item:Entity in _selection) {
                if (item is Node) { selectedNodes.push(item); }
            }
            return selectedNodes;
        }

		public function hasSelectedWays():Boolean {
			for each (var item:Entity in _selection) {
				if (item is Way) { return true; }
			}
			return false;
		}

		public function hasSelectedAreas():Boolean {
			for each (var item:Entity in _selection) {
				if (item is Way && Way(item).isArea()) { return true; }
			}
			return false;
		}

		public function hasSelectedUnclosedWays():Boolean {
			for each (var item:Entity in _selection) {
				if (item is Way && !Way(item).isArea()) { return true; }
			}
			return false;
		}

        /** Determine whether or not any nodes are selected, and if so whether any of them belong to areas. */
        public function hasSelectedWayNodesInAreas():Boolean {
            for each (var item:Entity in _selection) {
                if (item is Node) {
                    var parentWays:Array = Node(item).parentWays;
                    for each (var way:Entity in parentWays) {
                        if (Way(way).isArea()) { return true; }
                    }
                }
            }
            return false;
        }

		public function hasAdjoiningWays():Boolean {
			if (_selection.length<2) { return false; }
			var endNodes:Object={};
			for each (var item:Entity in _selection) {
				if (item is Way && !Way(item).isArea()) {
					if (endNodes[Way(item).getNode(0).id]) return true;
					if (endNodes[Way(item).getLastNode().id]) return true;
					endNodes[Way(item).getNode(0).id]=true;
					endNodes[Way(item).getLastNode().id]=true;
				}
			}
			return false;
		}

		// Selection setters

		public function set selection(items:Array):void {
			_selection=items;
		}

		public function addToSelection(items:Array):void {
			for each (var item:Entity in items) {
				if (_selection.indexOf(item)==-1) { _selection.push(item); }
			}
		}

		public function removeFromSelection(items:Array):void {
			for each (var item:Entity in items) {
				if (_selection.indexOf(item)>-1) {
					_selection.splice(_selection.indexOf(item),1);
				}
			}
		}

		public function toggleSelection(item:Entity):Boolean {
			if (_selection.indexOf(item)==-1) {
				_selection.push(item); return true;
			}
			_selection.splice(_selection.indexOf(item),1); return false;
		}
    }
}
