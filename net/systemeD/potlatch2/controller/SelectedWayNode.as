package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedWayNode extends SelectedWay {
        protected var selectedNode:Node;
        protected var initNode:Node;
        
        public function SelectedWayNode(way:Way,node:Node) {
			Globals.vars.root.addDebug("- SelectedWayNode: constructor");
			super (way);
            initNode = node;
        }
 
        protected function selectNode(way:Way,node:Node):void {
			Globals.vars.root.addDebug("- SelectedWayNode: selectNode");
            if ( way == selectedWay && node == selectedNode )
                return;

            clearSelection();
            controller.setTagViewer(node);
            controller.map.setHighlight(node, { selected: true });
            controller.map.setHighlight(way, { showNodes: true });
            selectedWay = way;   initWay  = way;
            selectedNode = node; initNode = node;
        }
                
        override protected function clearSelection():void {
            if ( selectedNode != null ) {
                controller.map.setHighlight(selectedNode, { selected: false });
            	controller.map.setHighlight(selectedWay, { selected: false, showNodes: false });
                controller.setTagViewer(null);
                selectedNode = null;
				selectedWay = null;
            }
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.MOUSE_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
            var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);

            if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity is Node && event.shiftKey ) {
					// start new way
					Globals.vars.root.addDebug("- SelectedWayNode: start new way");
                    var way:Way = controller.connection.createWay({}, [entity, entity]);
                    return new DrawWay(way, true);
				} else if ( entity is Node ) {
					// select node within way
					Globals.vars.root.addDebug("- SelectedWayNode: select other node");
					return new SelectedWayNode(selectedWay,Node(entity));
                } else if ( entity is Way ) {
					// select way
					Globals.vars.root.addDebug("- SelectedWayNode: select way");
					return new SelectedWay(selectedWay);
                } else if ( focus == null && map.dragstate!=map.DRAGGING ) {
					Globals.vars.root.addDebug("- SelectedWayNode: deselect");
                    return new NoSelection();
				}
            } else if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Way && focus==selectedWay && event.shiftKey) {
					// insert node within way (shift-click)
              		var d:DragWayNode=new DragWayNode(selectedWay, addNode(event), event);
					d.forceDragStart();
					return d;
				} else if ( entity is Node && entity.hasParent(selectedWay) ) {
					Globals.vars.root.addDebug("- SelectedWayNode: dragwaynode");
                    return new DragWayNode(selectedWay, Node(entity), event);
				}
            }

            return this;
        }

		override public function enterState():void {
            selectNode(initWay,initNode);
        }

        override public function toString():String {
            return "SelectedWayNode";
        }

    }
}
