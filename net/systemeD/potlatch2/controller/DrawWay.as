package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.*;
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;
	import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.actions.*;
	import net.systemeD.halcyon.Elastic;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.MapPaint;

	public class DrawWay extends SelectedWay {
		private var elastic:Elastic;
		private var editEnd:Boolean;
		private var leaveNodeSelected:Boolean;
		private var lastClick:Entity=null;
		private var lastClickTime:Date;
		private var hoverEntity:Entity;			// keep track of the currently rolled-over object, because
												// Flash can fire a mouseDown from the map even if you
												// haven't rolled out of the way
		
		public function DrawWay(way:Way, editEnd:Boolean, leaveNodeSelected:Boolean) {
			super(way);
			this.editEnd = editEnd;
			this.leaveNodeSelected = leaveNodeSelected;
			if (way.length==1 && way.getNode(0).parentWays.length==1) {
				// drawing new way, so keep track of click in case creating a POI
				lastClick=way.getNode(0);
				lastClickTime=new Date();
			}
            way.addEventListener(Connection.WAY_NODE_REMOVED, fixElastic);
            way.addEventListener(Connection.WAY_NODE_ADDED, fixElastic);
		}
		
		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			var mouse:Point;
			var node:Node;
			var paint:MapPaint = getMapPaint(DisplayObject(event.target));
			var isBackground:Boolean = paint && paint.isBackground;

			if (entity == null && hoverEntity) { entity=hoverEntity; }
			var focus:Entity = getTopLevelFocusEntity(entity);

			if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity == null || isBackground ) {
					node = createAndAddNode(event);
					resetElastic(node);
					lastClick=node;
				} else if ( entity is Node ) {
					if (entity==lastClick && (new Date().getTime()-lastClickTime.getTime())<1000) {
						if (selectedWay.length==1 && selectedWay.getNode(0).parentWays.length==1) {
							// double-click to create new POI
                            stopDrawing();
                            MainUndoStack.getGlobalStack().undo(); // undo the BeginWayAction that (presumably?) just happened
                            
                            var newPoiAction:CreatePOIAction = new CreatePOIAction(event, controller.map);
                            MainUndoStack.getGlobalStack().addAction(newPoiAction);
                            return new SelectedPOINode(newPoiAction.getNode());
						} else {
							// double-click at end of way
							return stopDrawing();
						}
					} else {
						appendNode(entity as Node, MainUndoStack.getGlobalStack().addAction);
						if (focus is Way) {
                          controller.map.setHighlightOnNodes(focus as Way, { hoverway: false });
                        }
						controller.map.setHighlight(entity, { selectedway: true });
						resetElastic(entity as Node);
						lastClick=entity;
						if (selectedWay.getNode(0)==selectedWay.getNode(selectedWay.length-1)) {
							return new SelectedWay(selectedWay);
						}
					}
				} else if ( entity is Way ) {
					if (entity as Way==selectedWay) {
						// add junction node - self-intersecting way
			            var lat:Number = controller.map.coord2lat(event.localY);
			            var lon:Number = controller.map.coord2lon(event.localX);
			            var undo:CompositeUndoableAction = new CompositeUndoableAction("Insert node");
			            node = controller.connection.createNode({}, lat, lon, undo.push);
			            selectedWay.insertNodeAtClosestPosition(node, true, undo.push);
						appendNode(node,undo.push);
			            MainUndoStack.getGlobalStack().addAction(undo);
					} else {
						// add junction node - another way
						node = createAndAddNode(event);
						Way(entity).insertNodeAtClosestPosition(node, true,
						    MainUndoStack.getGlobalStack().addAction);
					}
					resetElastic(node);
					lastClick=node;
					controller.map.setHighlightOnNodes(entity as Way, { hoverway: false });
					controller.map.setHighlightOnNodes(selectedWay, { selectedway: true });
				}
				lastClickTime=new Date();
			} else if ( event.type == MouseEvent.MOUSE_MOVE ) {
				mouse = new Point(
						  controller.map.coord2lon(event.localX),
						  controller.map.coord2latp(event.localY));
				elastic.end = mouse;
			} else if ( event.type == MouseEvent.ROLL_OVER && !isBackground ) {
				if (focus is Way && focus!=selectedWay) {
					hoverEntity=focus;
					controller.map.setHighlightOnNodes(focus as Way, { hoverway: true });
				}
				if (entity is Node && focus is Way && Way(focus).endsWith(Node(entity))) {
					if (focus==selectedWay) { controller.setCursor(controller.pen_so); }
					                   else { controller.setCursor(controller.pen_o); }
				} else if (entity is Node) {
					controller.setCursor(controller.pen_x);
				} else {
					controller.setCursor(controller.pen_plus);
				}
			} else if ( event.type == MouseEvent.MOUSE_OUT && !isBackground ) {
				if (focus is Way && entity!=selectedWay) {
					hoverEntity=null;
					controller.map.setHighlightOnNodes(focus as Way, { hoverway: false });
					// ** We could do with an optional way of calling WayUI.redraw to only do the nodes, which would be a
					// useful optimisation.
				}
				controller.setCursor(controller.pen);
			}

			return this;
		}
		
		protected function resetElastic(node:Node):void {
			var mouse:Point = new Point(node.lon, node.latp);
			elastic.start = mouse;
			elastic.end = mouse;
		}

        /* Fix up the elastic after a WayNode event - e.g. triggered by undo */
        private function fixElastic(event:Event):void {
            if (selectedWay == null) return;
            var node:Node
            if (editEnd) {
              node = selectedWay.getNode(selectedWay.length-1);
            } else {
              node = selectedWay.getNode(0);
            }
            if (node) { //maybe selectedWay doesn't have any nodes left
              elastic.start = new Point(node.lon, node.latp);
            }
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 13:					return stopDrawing();
				case 27:					return stopDrawing();
				case Keyboard.DELETE:		return backspaceNode(MainUndoStack.getGlobalStack().addAction);
				case Keyboard.BACKSPACE:	return backspaceNode(MainUndoStack.getGlobalStack().addAction);
				case 82:					repeatTags(selectedWay); return this;
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		protected function stopDrawing():ControllerState {
			if ( hoverEntity ) {
				controller.map.setHighlightOnNodes(hoverEntity as Way, { hoverway: false });
				hoverEntity = null;
			}

			if ( false ) {
				controller.map.setHighlightOnNodes(selectedWay, { selectedway: false });
				selectedWay.remove(MainUndoStack.getGlobalStack().addAction);
				// delete controller.map.ways[selectedWay.id];
				return new NoSelection();
			} else if ( leaveNodeSelected ) {
			    return new SelectedWayNode(selectedWay, editEnd ? selectedWay.length - 1 : 0);
			} else {
			    return new SelectedWay(selectedWay);
			}
			return this;
		}

		public function createAndAddNode(event:MouseEvent):Node {
		    var undo:CompositeUndoableAction = new CompositeUndoableAction("Add node");
		    
			var lat:Number = controller.map.coord2lat(event.localY);
			var lon:Number = controller.map.coord2lon(event.localX);
			var node:Node = controller.connection.createNode({}, lat, lon, undo.push);
			appendNode(node, undo.push);
			
			MainUndoStack.getGlobalStack().addAction(undo);
			controller.map.setHighlight(node, { selectedway: true });
			controller.map.setPurgable(node, false);
			return node;
		}
		
		protected function appendNode(node:Node, performAction:Function):void {
			if ( editEnd )
				selectedWay.appendNode(node, performAction);
			else
				selectedWay.insertNode(0, node, performAction);
		}
		
		protected function backspaceNode(performAction:Function):ControllerState {
			var node:Node;
			var undo:CompositeUndoableAction = new CompositeUndoableAction("Remove node");
			var newDraw:int;
            var state:ControllerState;

			if (editEnd) {
				node=selectedWay.getNode(selectedWay.length-1);
				selectedWay.removeNodeByIndex(selectedWay.length-1, undo.push);
				newDraw=selectedWay.length-2;
			} else {
				node=selectedWay.getNode(0);
				selectedWay.removeNodeByIndex(0, undo.push);
				newDraw=0;
			}
			if (node.numParentWays==1 && selectedWay.hasOnceOnly(node)) {
				controller.map.setPurgable(node, true);
				controller.connection.unregisterPOI(node);
				node.remove(undo.push);
			}

			if (newDraw>=0 && newDraw<=selectedWay.length-2) {
				var mouse:Point = new Point(selectedWay.getNode(newDraw).lon, selectedWay.getNode(newDraw).latp);
				elastic.start = mouse;
				state = this;
			} else {
                selectedWay.remove(undo.push);
                state = new NoSelection();
			}

            performAction(undo);
            return state;
		}
		
		override public function enterState():void {
			super.enterState();
			
			var node:Node = selectedWay.getNode(editEnd ? selectedWay.length - 1 : 0);
			var start:Point = new Point(node.lon, node.latp);
			elastic = new Elastic(controller.map, start, start);
			controller.setCursor(controller.pen);
			Globals.vars.root.addDebug("**** -> "+this);
		}
		override public function exitState(newState:ControllerState):void {
			super.exitState(newState);
			controller.setCursor(null);
			elastic.removeSprites();
			elastic = null;
			Globals.vars.root.addDebug("**** <- "+this);
		}
		override public function toString():String {
			return "DrawWay";
		}
	}
}
