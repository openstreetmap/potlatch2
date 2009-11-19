package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

	/* **** this is largely unfinished **** */

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

            if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity is Way ) {
                    return new SelectedWay(Way(entity));
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
				if ( entity is Node && entity.hasParent(selectedWay) ) {
                    return new DragWayNode(selectedWay, Node(entity), event);
				}
            }

            return this;
        }

/*      public function clickOnWay(event:MouseEvent, entity:Entity):ControllerState {
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
*/      
        override public function enterState():void {
            selectNode(initNode);
        }
        override public function exitState():void {
            clearSelection();
        }

        override public function toString():String {
            return "SelectedNode";
        }

    }
}
