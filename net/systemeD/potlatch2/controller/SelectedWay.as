package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.potlatch2.tools.Quadrilateralise;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedWay extends ControllerState {
        protected var selectedWay:Way;
        protected var initWay:Way;
        
        public function SelectedWay(way:Way) {
            initWay = way;
        }
 
        protected function selectWay(way:Way):void {
            if ( way == selectedWay )
                return;

            clearSelection();
            controller.setTagViewer(way);
            controller.map.setHighlight(way, { selected: true, showNodes: true, hover: false });
            selectedWay = way;
            initWay = way;
        }

        protected function clearSelection():void {
            if ( selectedWay != null ) {
            	controller.map.setHighlight(selectedWay, { selected: false, showNodes: false, hover: false });
                controller.setTagViewer(null);
                selectedWay = null;
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.MOUSE_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity is Node && event.shiftKey ) {
					// start new way
                    var way:Way = controller.connection.createWay({}, [entity]);
                    return new DrawWay(way, true, false);
				} else if ( entity is Way && event.ctrlKey ) {
					// merge way
					mergeWith(entity as Way);
				} else if ( entity is Way ) {
					// select way
                    selectWay(entity as Way);
                } else if ( focus == null && map.dragstate!=map.DRAGGING ) {
                    return new NoSelection();
				}
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Way && focus==selectedWay && event.shiftKey) {
					// insert node within way (shift-click)
                    var d:DragWayNode=new DragWayNode(selectedWay, addNode(event), event, true);
					d.forceDragStart();
					return d;
				} else if ( entity is Node && entity.hasParent(selectedWay) ) {
					// select node within this way
                    return new DragWayNode(selectedWay, Node(entity), event, false);
                } else if ( focus is Node ) {
					// select POI node
					return new DragPOINode(entity as Node,event,false);
                } else if ( entity is Node && focus is Way ) {
					// select way node
					return new DragWayNode(focus as Way,entity as Node,event,false);
				}
            }

            return this;
        }
        
	override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
	  if (event.keyCode == 81) { // 'q' or 'Q'
	    var success:Boolean = Quadrilateralise.quadrilateralise(selectedWay);
	    if (!success) {
	      trace("Quadrilateralise failed.");
	    }
	  }

	  return this;
	}

        protected function addNode(event:MouseEvent):Node {
            trace("add node");
            var lat:Number = controller.map.coord2lat(event.localY);
            var lon:Number = controller.map.coord2lon(event.localX);
            var node:Node = controller.connection.createNode({}, lat, lon);
            selectedWay.insertNodeAtClosestPosition(node, true);
			return node;
        }

		protected function mergeWith(way:Way):Boolean {
			Globals.vars.root.addDebug("merge with "+way.id);

			// ** needs to prefer positive to negative IDs
			// find common point
			if (way==selectedWay) { return false; }
			if      (selectedWay.getNode(0)   ==way.getNode(0)   ) { selectedWay.mergeWith(way,0,0); }
			else if (selectedWay.getNode(0)   ==way.getLastNode()) { selectedWay.mergeWith(way,0,way.length-1); }
			else if (selectedWay.getLastNode()==way.getNode(0)   ) { selectedWay.mergeWith(way,selectedWay.length-1,0); }
			else if (selectedWay.getLastNode()==way.getLastNode()) { selectedWay.mergeWith(way,selectedWay.length-1,way.length-1); }
			return true;
		}
        
        override public function enterState():void {
            selectWay(initWay);
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWay";
        }

    }
}
