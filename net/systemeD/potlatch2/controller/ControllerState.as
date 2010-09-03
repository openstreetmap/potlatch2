package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.*;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.potlatch2.save.SaveManager;

    public class ControllerState {

        protected var controller:EditController;
        protected var previousState:ControllerState;

        protected var selectedNode:Node;
        public var selectedWay:Way;

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

        public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            return this;
        }
        
        public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
            return this;
        }

		public function get map():Map {
			return controller.map;
		}

        public function enterState():void {}
        public function exitState(newState:ControllerState):void {}

		public function toString():String {
			return "(No state)";
		}
		
		protected function sharedKeyboardEvents(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 67:	controller.connection.closeChangeset(); break;							// C - close changeset
				case 68:	controller.map.paint.alpha=1.3-controller.map.paint.alpha; return null;	// D - dim
				case 83:	SaveManager.saveChanges(); break;										// S - save
				case 84:	controller.tagViewer.togglePanel(); return null;						// T - toggle tags panel
				case 87:	if (selectedWay) { return new SelectedWay(selectedWay); }; return null;	// W - select way
				case 90:	MainUndoStack.getGlobalStack().undo(); return null;						// Z - undo
				case 187:	controller.tagViewer.addNewTag(); return null;							// + - add tag
			}
			return null;
		}
		
		protected function sharedMouseEvents(event:MouseEvent, entity:Entity):ControllerState {
			var paint:MapPaint = getMapPaint(DisplayObject(event.target));
            var focus:Entity = getTopLevelFocusEntity(entity);

			if ( paint && paint.isBackground ) {
				if ( event.type == MouseEvent.MOUSE_DOWN && ((event.shiftKey && event.ctrlKey) || event.altKey) ) {
					// alt-click to pull data out of vector background layer
					var newEntity:Entity=paint.findSource().pullThrough(entity,controller.connection);
					if (entity is Way) { return new SelectedWay(newEntity as Way); }
					else if (entity is Node) { return new SelectedPOINode(newEntity as Node); }
				} else if ( event.type == MouseEvent.MOUSE_UP ) { 
					return (this is NoSelection) ? null : new NoSelection();
				} else { return null; }
			}

			if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Way ) {
					// click way
					return new DragWay(focus as Way, event);
				} else if ( focus is Node ) {
					// select POI node
					return new DragPOINode(entity as Node,event,false);
				} else if ( entity is Node && selectedWay && entity.hasParent(selectedWay) ) {
					// select node within this way
                	return new DragWayNode(selectedWay,  getNodeIndex(selectedWay,entity as Node),  event, false);
				} else if ( entity is Node && focus is Way ) {
					// select way node
					return new DragWayNode(focus as Way, getNodeIndex(focus as Way,entity as Node), event, false);
				} else if ( controller.keyDown(32) ) {
					// drag map
					return new DragBackground(event);
				}
			} else if ( event.type == MouseEvent.MOUSE_UP && focus == null && map.dragstate!=map.DRAGGING) {
				return (this is NoSelection) ? null : new NoSelection();
			} else if ( event.type == MouseEvent.MOUSE_UP && focus && map.dragstate!=map.NOT_DRAGGING) {
				map.mouseUpHandler();	// in case the end-drag is over an EntityUI
			} else if ( event.type == MouseEvent.ROLL_OVER ) {
				controller.map.setHighlight(focus, { hover: true });
			} else if ( event.type == MouseEvent.MOUSE_OUT ) {
				controller.map.setHighlight(focus, { hover: false });
			}
			return null;
		}

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
		
		protected function repeatTags(object:Entity):void {
			if (!controller.clipboards[object.getType()]) { return; }
			object.suspend();

		    var undo:CompositeUndoableAction = new CompositeUndoableAction("Repeat tags");
			for (var k:String in controller.clipboards[object.getType()]) {
				object.setTag(k, controller.clipboards[object.getType()][k], undo.push)
			}
			MainUndoStack.getGlobalStack().addAction(undo);

			object.resume();
		}
    }
}
