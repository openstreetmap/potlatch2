package net.systemeD.potlatch2.controller {
	import flash.events.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

    public class SelectedWayNode extends SelectedWay {
        protected var selectedNode:Node;
        protected var initNode:Node;
        
        public function SelectedWayNode(way:Way,node:Node) {
			super (way);
            initNode = node;
        }
 
        protected function selectNode(way:Way,node:Node):void {
            if ( way == selectedWay && node == selectedNode )
                return;

            clearSelection();
            controller.setTagViewer(node);
            controller.map.setHighlight(way, { showNodes: true, nodeSelected: node.id });
            selectedWay = way;   initWay  = way;
            selectedNode = node; initNode = node;
        }
                
        override protected function clearSelection():void {
            if ( selectedNode != null ) {
            	controller.map.setHighlight(selectedWay, { selected: false, showNodes: false, nodeSelected: null });
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
                    var way:Way = controller.connection.createWay({}, [entity]);
                    return new DrawWay(way, true);
				} else if ( entity is Node ) {
					// select node within way
					return new SelectedWayNode(selectedWay,Node(entity));
                } else if ( entity is Way ) {
					// select way
					return new SelectedWay(Way(entity));
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

		override public function enterState():void {
            selectNode(initWay,initNode);
			Globals.vars.root.addDebug("**** -> "+this);
        }
		override public function exitState():void {
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedWayNode";
        }

    }
}
