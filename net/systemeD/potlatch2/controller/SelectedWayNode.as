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
                    return new DrawWay(way, true, false);
				} else if ( entity is Node && focus == selectedWay ) {
					// select node within way
					return selectOrEdit(selectedWay, Node(entity));
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
				} else if ( focus is Node ) {
					return new DragPOINode(entity as Node,event,false);
				}
            }

            return this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			switch (event.keyCode) {
				case 88:	return splitWay();
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

        public static function selectOrEdit(selectedWay:Way, entity:Node):ControllerState {
        	var isFirst:Boolean = false;
			var isLast:Boolean = false;
			isFirst = selectedWay.getNode(0) == entity;
			isLast = selectedWay.getNode(selectedWay.length - 1) == entity;
			if ( isFirst == isLast )    // both == looped, none == central node 
			    return new SelectedWayNode(selectedWay, entity);
			else
			    return new DrawWay(selectedWay, isLast, true);
        }

		public function splitWay():ControllerState {
			// abort if start or end
			if (selectedWay.getNode(0                   ) == selectedNode) { return this; }
			if (selectedWay.getNode(selectedWay.length-1) == selectedNode) { return this; }

			// create new way
			var newWay:Way = controller.connection.createWay(
				selectedWay.getTagsCopy(), 
				selectedWay.sliceNodes(selectedWay.indexOfNode(selectedNode),selectedWay.length));
			selectedWay.deleteNodesFrom(selectedWay.indexOfNode(selectedNode)+1);
			
			// copy relations
			for each (var r:Relation in selectedWay.parentRelations) {
				// ** needs to copy roles as well
				r.appendMember(new RelationMember(newWay, ''));
			}
			controller.map.ways[newWay.id].redraw();

			return new SelectedWay(selectedWay);
		}

    }
}
