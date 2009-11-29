package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
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
            controller.map.setHighlight(way, { selected: true, showNodes: true });
            selectedWay = way;
            initWay = way;
        }

        protected function clearSelection():void {
            if ( selectedWay != null ) {
            	controller.map.setHighlight(selectedWay, { selected: false, showNodes: false });
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
                    return new DrawWay(way, true);
				} else if ( entity is Way ) {
					// select way
                    selectWay(entity as Way);
                } else if ( entity is Node ) {
					// *** select node
					Globals.vars.root.addDebug("- selected POI from SelectedWay");
                    trace("select poi");
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
                    return new DragWayNode(selectedWay, Node(entity), event, false);
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
