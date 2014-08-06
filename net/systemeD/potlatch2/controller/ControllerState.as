package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.AttentionEvent;
    import net.systemeD.potlatch2.collections.Imagery;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.potlatch2.history.HistoryDialog;
	import net.systemeD.potlatch2.save.SaveManager;
	import net.systemeD.potlatch2.utils.SnapshotConnection;
    import net.systemeD.halcyon.AttentionEvent;
	import flash.ui.Keyboard;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.core.FlexGlobals;
	
    /** Represents a particular state of the controller, such as "dragging a way" or "nothing selected". Key methods are 
    * processKeyboardEvent and processMouseEvent which take some action, and return a new state for the controller. 
    * 
    * This abstract class has some behaviour that applies in most states, and lots of 'null' behaviour. 
    * */
    public class ControllerState {

        protected var controller:EditController;
		public var layer:MapPaint;

		protected var _selection:Array=[];

        public function ControllerState() {}

        public function setController(controller:EditController):void {
            this.controller=controller;
            if (!layer) layer=controller.map.editableLayer;
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

        /** Retrieves the map associated with the current EditController */
		public function get map():Map {
			return controller.map;
		}

        /** This is called when the EditController sets this ControllerState as the active state.
        * Override this with whatever is needed, such as adding highlights to entities
        */
        public function enterState():void {}

        /** This is called by the EditController as the current controllerstate is exiting.
        * Override this with whatever cleanup is needed, such as removing highlights from entities
        */
        public function exitState(newState:ControllerState):void {}

		/** Represent the state in text for debugging. */
		public function toString():String {
			return "(No state)";
		}

		/** Return contextual help string for this state. */
		public function contextualHelpId():String {
			return toString();
		}

		/** Default behaviour for the current state that should be called if state-specific action has been taken care of or ruled out. */
		protected function sharedKeyboardEvents(event:KeyboardEvent):ControllerState {
			var editableLayer:MapPaint=controller.map.editableLayer;								// shorthand for this method
			switch (event.keyCode) {
				case 48:	removeTags(); break;													// 0 - remove all tags
				case 66:	setSourceTag(); break;													// B - set source tag for current object
				case 67:	editableLayer.connection.closeChangeset(); break;						// C - close changeset
				case 68:	editableLayer.alpha=1.3-editableLayer.alpha; return null;				// D - dim
				case 71:	FlexGlobals.topLevelApplication.trackLoader.load(); break;				// G - GPS tracks **FIXME: move from Application to Map
                case 72:    showHistory(); break;                                                   // H - History
				case 83:	SaveManager.saveChanges(editableLayer.connection); break;				// S - save
				case 84:	controller.tagViewer.togglePanel(); return null;						// T - toggle tags panel
				case 90:	if (!event.shiftKey) { MainUndoStack.getGlobalStack().undo(); return null;}// Z - undo
				            else { MainUndoStack.getGlobalStack().redo(); return null;  }           // Shift-Z - redo 						
				case Keyboard.ESCAPE:	revertSelection(); break;									// ESC - revert to server version
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

			if ( event.type == MouseEvent.MOUSE_UP && focus && map.dragstate!=map.NOT_DRAGGING) {
				map.mouseUpHandler();	// in case the end-drag is over an EntityUI
			} else if ( event.type == MouseEvent.ROLL_OVER && paint && paint.interactive ) {
				paint.setHighlight(focus, { hover: true });
			} else if ( event.type == MouseEvent.MOUSE_OUT && paint && paint.interactive ) {
				paint.setHighlight(focus, { hover: false });
			} else if ( event.type == MouseEvent.MOUSE_WHEEL ) {
				if      (event.delta > 0) { map.zoomIn(); }
				else if (event.delta < 0) { map.zoomOut(); }
			}

			if ( paint && paint.isBackground ) {
				if (event.type == MouseEvent.MOUSE_DOWN && ((event.shiftKey && event.ctrlKey) || event.altKey) ) {
					// alt-click to pull data out of vector background layer
					// extend the current selection (alt-ctrl) or create a new one (alt)?
					var newSelection:Array=(event.altKey && event.ctrlKey) ? _selection : [];
					// create a list of the alt-clicked item, plus anything else already selected (assuming it's in the same layer!)
					var itemsToPullThrough:Array=[]
					if (_selection.length && firstSelected.connection==entity.connection) itemsToPullThrough=_selection.slice();
					if (itemsToPullThrough.indexOf(entity)==-1) itemsToPullThrough.push(entity);
					// make sure they're unhighlighted, and pull them through
					for each (var entity:Entity in itemsToPullThrough) {
						paint.setHighlight(entity, { hover:false, selected: false });
						if (entity is Way) paint.setHighlightOnNodes(Way(entity), { selectedway: false });
						newSelection.push(paint.pullThrough(entity,controller.map.editableLayer));
					}
					return controller.findStateForSelection(newSelection);
				} else if (!paint.interactive) {
					return null;
				} else if (event.type == MouseEvent.MOUSE_DOWN && paint.interactive) {
					if      (entity is Way   ) { return new SelectedWay(entity as Way, paint); }
					else if (entity is Node  ) { if (!entity.hasParentWays) return new SelectedPOINode(entity as Node, paint); }
					else if (entity is Marker) { return new SelectedMarker(entity as Marker, paint); }
				} else if ( event.type == MouseEvent.MOUSE_UP && !event.ctrlKey) {
					return (this is NoSelection) ? null : new NoSelection();
				} else if ( event.type == MouseEvent.CLICK && focus == null && map.dragstate!=map.DRAGGING && !event.ctrlKey) {
					return (this is NoSelection) ? null : new NoSelection();
				}
					
			} else if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Node && selectedWay && entity.hasParent(selectedWay) ) {
					// select node within this way
					return new DragWayNode(selectedWay,  getNodeIndex(selectedWay,entity as Node),  event, false);
				} else if ( controller.spaceHeld ) {
					// drag the background imagery to compensate for poor alignment
					return new DragBackground(event, this);
				} else if (entity && selection.indexOf(entity)>-1) {
					return new DragSelection(selection, event);
				} else if (entity) {
					return controller.findStateForSelection([entity]);
				} else if (event.ctrlKey && !layer.isBackground) {
					return new SelectArea(event.localX,event.localY,selection);
				}

            } else if ( event.type==MouseEvent.MOUSE_UP && focus == null && map.dragstate!=map.DRAGGING && !event.ctrlKey) {
                return (this is NoSelection) ? null : new NoSelection();
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

		/** Create a "repeat relations" action on the current entity, if possible. */
		protected function repeatRelations(object:Entity):void {
			if (!controller.relationClipboards[object.getType()]) { return; }
			object.suspend();

			var undo:CompositeUndoableAction = new CompositeUndoableAction("Repeat relations");
			var relationsadded:uint;
			for each (var rr:Object in controller.relationClipboards[object.getType()]) {
				if (!rr.relation.findEntityMemberIndex(object)>-1) {
					rr.relation.appendMember(new RelationMember(object, rr.role), undo.push);
					relationsadded++;
				}
			}
			MainUndoStack.getGlobalStack().addAction(undo);
			controller.updateSelectionUI();
			object.resume();
			if (relationsadded > 0) {
				var msg:String=relationsadded.toString() + " relation(s) added to " + object.getType() + ".";
				controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, msg));
			}
		}

		/** Copy list of relations from current object, for future repeatRelation() call. */
		protected function copyRelations(object: Entity):void {
			// Leave existing relations alone if it doesn't have any
			if (object.parentRelations.length == 0) return;
			controller.relationClipboards[object.getType()]=[];
			for each (var rm:Object in object.getRelationMemberships() ) {
				var rr:Object = { relation: rm.relation, role: rm.role };
				controller.relationClipboards[object.getType()].push(rr);
			}
		}
		
		/** Remove all tags from current selection. */
		protected function removeTags():void {
			if (selectCount==0) return;
			var undo:CompositeUndoableAction = new CompositeUndoableAction("Remove tags");
			for each (var item:Entity in _selection) {
				item.suspend();
				var tags:Array=item.getTagArray();
				for each (var tag:Tag in tags) item.setTag(tag.key,null,undo.push);
			}
			MainUndoStack.getGlobalStack().addAction(undo);
			controller.updateSelectionUI();
			for each (item in _selection) item.resume();
		}

        /** Show the history dialog, if only one object is selected. */
        protected function showHistory():void {
            if (selectCount == 1) {
                new HistoryDialog().init(firstSelected);
            } else if (selectCount == 0) {
                controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Can't show history, nothing selected"));
            } else {
                controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Can't show history, multiple objects selected"));
            }
        }

		/** Create an action to add "source=*" tag to current entity based on background imagery. This is a convenient shorthand for users. */
		protected function setSourceTag():void {
			if (selectCount!=1) { return; }
			if (!Imagery.instance().selected) { return; }
			var sourceTag:String = Imagery.instance().selected.sourcetag || Imagery.instance().selected.id || Imagery.instance().selected.name;
			if (sourceTag=='None') { return; }
			if ("sourcekey" in Imagery.instance().selected) {
			    firstSelected.setTag(Imagery.instance().selected.sourcekey, sourceTag, MainUndoStack.getGlobalStack().addAction);
			} else {
			    firstSelected.setTag('source', sourceTag, MainUndoStack.getGlobalStack().addAction);
			}
			controller.updateSelectionUI();
		}

		/** Revert all selected items to previously saved state, via a dialog box. */
		protected function revertSelection():void {
			var revertable:Boolean=false;
			for each (var item:Entity in _selection)
				if (item.id>0) revertable=true;
			if (revertable)
				Alert.show("Revert selected items to the last saved version, discarding your changes?","Are you sure?",Alert.YES | Alert.CANCEL,null,revertHandler,null,Alert.CANCEL);
		}
		protected function revertHandler(event:CloseEvent):void {
			if (event.detail==Alert.CANCEL) return;
			for each (var item:Entity in _selection) {
				if (item.id>0) item.connection.loadEntity(item);
			}
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
				if (item is Way && !Way(item).isArea() && Way(item).length>0) {
					var startNode:int=Way(item).getNode(0).id;
					var finishNode:int=Way(item).getLastNode().id;
					if (endNodes[startNode ]) return true;
					if (endNodes[finishNode]) return true;
					endNodes[startNode ]=true;
					endNodes[finishNode]=true;
				}
			}
			return false;
		}

		/** Identify the inners and outer from the current selection for making a multipolygon. */
		
		public function multipolygonMembers():Object {
			if (_selection.length<2) { return {}; }

			var entity:Entity;
			var relation:Relation;
			var outer:Way;
			var inners:Array=[];

			// If there's an existing outer in the selection, use that
			for each (entity in selection) {
				if (!(entity is Way)) return {};
				var r:Array=entity.findParentRelationsOfType('multipolygon','outer');
				if (r.length) { outer=Way(entity); relation=r[0]; }
			}

			// Otherwise, find the way with the biggest area
			var largest:Number=0;
			if (!outer) {
				for each (entity in selection) {
					if (!(entity is Way)) return {};
					if (!Way(entity).isArea()) return {};
					var props:Object=layer.wayUIProperties(entity as Way);
					if (props.patharea>largest) { outer=Way(entity); largest=props.patharea; }
				}
			}
			if (!outer) return {};
			
			// Identify the inners
			for each (entity in selection) {
				if (entity==outer) continue;
				if (!(entity is Way)) return {};
				if (!Way(entity).isArea()) return {};
				var node:Node=Way(entity).getFirstNode();
				if (outer.pointWithin(node.lon,node.lat)) inners.push(entity);
			}
			if (inners.length==0) return {};
			
			return { outer: outer,
			         inners: inners,
			         relation: relation }
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
