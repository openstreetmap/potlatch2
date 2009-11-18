package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedWay extends ControllerState {
        protected var selectedWay:Way;
        protected var selectedNode:Node;
        protected var initWay:Way;
        
        public function SelectedWay(way:Way) {
            initWay = way;
        }
 
        protected function selectWay(way:Way):void {
            if ( way == selectedWay )
                return;

            clearSelection();
            controller.setTagViewer(way);
            controller.map.setHighlight(way, "selected", true);
            controller.map.setHighlight(way, "showNodes", true);
            selectedWay = way;
            initWay = way;
        }

        protected function selectNode(node:Node):void {
            if ( node == selectedNode )
                return;
            
            clearSelectedNode();
            controller.setTagViewer(node);
            controller.map.setHighlight(node, "selected", true);
            selectedNode = node;
        }
                
        protected function clearSelectedNode():void {
            if ( selectedNode != null ) {
                controller.map.setHighlight(selectedNode, "selected", false);
                controller.setTagViewer(selectedWay);
                selectedNode = null;
            }
        }
        protected function clearSelection():void {
            if ( selectedWay != null ) {
                controller.map.setHighlight(selectedWay, "selected", false);
                controller.map.setHighlight(selectedWay, "showNodes", false);
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
					Globals.vars.root.addDebug("- start new way");
                    var way:Way = controller.connection.createWay({}, [entity, entity]);
                    return new DrawWay(way, true);
				} else if ( entity is Node && entity.hasParent(selectedWay) ) {
					// select node within way
					Globals.vars.root.addDebug("- clicked on place within way");
                    return clickOnWay(event, entity);
                } else if ( focus is Way ) {
					// select way
					Globals.vars.root.addDebug("- selected way");
                    selectWay(focus as Way);
                } else if ( focus is Node ) {
					// *** select node
					Globals.vars.root.addDebug("- selected POI");
                    trace("select poi");
                } else if ( focus == null && map.dragstate!=map.DRAGGING ) {
                    return new NoSelection();
				}
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Way && focus==selectedWay && event.shiftKey) {
					// insert node within way (shift-click)
                    var d:DragWayNode=new DragWayNode(selectedWay, addNode(event), event);
					d.forceDragStart();
					return d;
				} else if ( entity is Node && entity.hasParent(selectedWay) ) {
                    return new DragWayNode(selectedWay, Node(entity), event);
				}
            }

            return this;
        }

        public function clickOnWay(event:MouseEvent, entity:Entity):ControllerState {
            if ( entity is Node ) {
                if ( selectedNode == entity ) {
                    var i:uint = selectedWay.indexOfNode(selectedNode);
                    if ( i == 0 )
                        return new DrawWay(selectedWay, false);
                    else if ( i == selectedWay.length - 1 )
                        return new DrawWay(selectedWay, true);
                } else {
                    selectNode(entity as Node);
                }
            }
            
            return this;
        }
        
        private function addNode(event:MouseEvent):Node {
            trace("add node");
            var lat:Number = controller.map.coord2lat(event.localY);
            var lon:Number = controller.map.coord2lon(event.localX);
            var node:Node = controller.connection.createNode({}, lat, lon);
            selectedWay.insertNodeAtClosestPosition(node, true);
			return node;
        }
        
        override public function enterState():void {
            selectWay(initWay);
        }
        override public function exitState():void {
            clearSelection();
        }

        override public function toString():String {
            return "SelectedWay";
        }

    }
}
