package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedPOINode extends ControllerState {
        protected var selectedNode:Node;
        protected var initNode:Node;
        
        public function SelectedPOINode(node:Node) {
            initNode = node;
        }
 
        protected function selectNode(node:Node):void {
            if ( node == selectedNode )
                return;

            clearSelection();
            controller.setTagViewer(node);
            controller.map.setHighlight(node, { selected: true });
            selectedNode = node;
            initNode = node;
        }
                
        protected function clearSelection():void {
            if ( selectedNode != null ) {
                controller.map.setHighlight(selectedNode, { selected: false });
                controller.setTagViewer(null);
                selectedNode = null;
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.MOUSE_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity is Way ) {
                    return new SelectedWay(entity as Way);
				// ** do we need 'entity is Node && focus is Way' for POIs in ways?
                } else if ( focus == null && map.dragstate!=map.DRAGGING ) {
                    return new NoSelection();
				}
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
//				if ( entity is Way && focus==selectedWay && event.shiftKey) {
//					// insert node within way (shift-click)
//                  var d:DragWayNode=new DragWayNode(selectedWay, addNode(event), event);
//					d.forceDragStart();
//					return d;
//				} else
                if ( focus is Node ) {
					return new DragPOINode(entity as Node,event,false);
                } else if ( entity is Node && focus is Way ) {
					return new DragWayNode(focus as Way,entity as Node,event,false);
				}
            }

            return this;
        }

        override public function enterState():void {
            selectNode(initNode);
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedPOINode";
        }

    }
}
