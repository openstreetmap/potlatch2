package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.DisplayObject;
	import flash.ui.Keyboard;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.potlatch2.tools.Parallelise;
    import net.systemeD.potlatch2.tools.Quadrilateralise;
    import net.systemeD.potlatch2.tools.Simplify;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.Globals;

    public class SelectedWay extends ControllerState {
        protected var initWay:Way;
        
        public function SelectedWay(way:Way) {
            initWay = way;
        }
 
        protected function selectWay(way:Way):void {
            if ( way == selectedWay )
                return;

            clearSelection();
            controller.setSelectedEntity(way);
            controller.map.setHighlight(way, { selected: true, showNodes: true, hover: false });
            selectedWay = way;
            initWay = way;
        }

        protected function clearSelection():void {
            if ( selectedWay != null ) {
            	controller.map.setHighlight(selectedWay, { selected: false, showNodes: false, hover: false });
                controller.setSelectedEntity(null);
                selectedWay = null;
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP && entity is Node && event.shiftKey ) {
				// start new way
				var way:Way = controller.connection.createWay({}, [entity], MainUndoStack.getGlobalStack().addAction);
				return new DrawWay(way, true, false);
			} else if ( event.type == MouseEvent.MOUSE_DOWN && entity is Way && event.ctrlKey ) {
				// merge way
				return mergeWith(entity as Way);
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
				case 80:					return new SelectedParallelWay(selectedWay);
				case 81:					Quadrilateralise.quadrilateralise(selectedWay); return this;
				case 82:					repeatTags(selectedWay); return this;
                case 86:                    selectedWay.reverseNodes(MainUndoStack.getGlobalStack().addAction); return this;
                case 89:                    Simplify.simplify(selectedWay, controller.map, true); return this;         
				case Keyboard.BACKSPACE:	if (event.shiftKey) { return deleteWay(); } break;
				case Keyboard.DELETE:		if (event.shiftKey) { return deleteWay(); } break;
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

        protected function addNode(event:MouseEvent):int {
			// find which other ways are under the mouse
			var ways:Array=[]; var w:Way;
			for each (var wayui:WayUI in controller.map.paint.wayuis) {
				w=wayui.hitTest(event.stageX, event.stageY);
				if (w && w!=selectedWay) { ways.push(w); }
			}

            var lat:Number = controller.map.coord2lat(event.localY);
            var lon:Number = controller.map.coord2lon(event.localX);
            var undo:CompositeUndoableAction = new CompositeUndoableAction("Insert node");
            var node:Node = controller.connection.createNode({}, lat, lon, undo.push);
            var index:int = selectedWay.insertNodeAtClosestPosition(node, true, undo.push);
			for each (w in ways) { w.insertNodeAtClosestPosition(node, true, undo.push); }
            MainUndoStack.getGlobalStack().addAction(undo);
			return index;
        }

		protected function mergeWith(otherWay:Way):ControllerState {
			var way1:Way;
			var way2:Way;
			if ( selectedWay.id < otherWay.id && selectedWay.id >= 0 ) {
			    way1 = selectedWay;
			    way2 = otherWay;
			} else {
			    way1 = otherWay;
			    way2 = selectedWay;
			}
			
			var undo:Function = MainUndoStack.getGlobalStack().addAction;
			
			// find common point
			if (way1 == way2) { return this; }
			if      (way1.getNode(0)   ==way2.getNode(0)   ) { way1.mergeWith(way2,0,0,undo); }
			else if (way1.getNode(0)   ==way2.getLastNode()) { way1.mergeWith(way2,0,way2.length-1,undo); }
			else if (way1.getLastNode()==way2.getNode(0)   ) { way1.mergeWith(way2,way1.length-1,0,undo); }
			else if (way1.getLastNode()==way2.getLastNode()) { way1.mergeWith(way2,way1.length-1,way2.length-1,undo); }
			return new SelectedWay(way1);
		}
        
		public function deleteWay():ControllerState {
			selectedWay.remove(MainUndoStack.getGlobalStack().addAction);
			return new NoSelection();
		}

        override public function enterState():void {
            selectWay(initWay);
			Globals.vars.root.addDebug("**** -> "+this+" "+selectedWay.id);
        }
        override public function exitState():void {
			controller.clipboards['way']=selectedWay.getTagsCopy();
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWay";
        }

    }
}
