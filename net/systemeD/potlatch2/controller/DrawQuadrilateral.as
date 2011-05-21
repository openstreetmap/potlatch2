package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.Stage;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.tools.Parallelise;

    public class DrawQuadrilateral extends ControllerState {
		private var sourceNode:Node;
		private var way:Way;
		private var centrelon:Number;
		private var centrelatp:Number;
		private var radius:Number;
		private var startX:Number;
		private var startY:Number;

        public function DrawQuadrilateral(node:Node) {
			sourceNode = node;
        }

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE) {
				// redraw the rectangle sprite
				var undo:CompositeUndoableAction = new CompositeUndoableAction("Draw quadrilateral");

				var dx:Number=controller.map.mouseX-startX;
				var dy:Number=controller.map.mouseY-startY;
				var angle:Number=(dy % 360) * Math.PI/180;

				way.getNode(1).setLonLatp(centrelon +radius*Math.sin(angle),
					                      centrelatp+radius*Math.cos(angle),
					                      undo.push);
				way.getNode(3).setLonLatp(centrelon -radius*Math.sin(angle),
				                          centrelatp-radius*Math.cos(angle),
				                          undo.push);
				undo.doAction();
			} else if (event.type==MouseEvent.CLICK || event.type==MouseEvent.MOUSE_UP) {
				// select the new rectangle
				return new SelectedWay(way);
			} else {
				trace(event.type);
			}
			return this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==27) {			// Escape
				// make sure the rectangle sprite is cleared
				return new NoSelection();
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		override public function enterState():void {
			controller.map.draggable=false;
			var conn:Connection=controller.connection;
			var undo:CompositeUndoableAction = new CompositeUndoableAction("Draw quadrilateral");
			var cornerlon:Number =controller.map.coord2lon(controller.map.mouseX);
			var cornerlat:Number =controller.map.coord2lat(controller.map.mouseY);
			var cornerlatp:Number=controller.map.coord2latp(controller.map.mouseY);
			
			var xradius:Number=(cornerlon-sourceNode.lon)/2;
			var yradius:Number=(cornerlatp-sourceNode.latp)/2;
			centrelon =sourceNode.lon +xradius;
			centrelatp=sourceNode.latp+yradius;
			radius=Math.sqrt(xradius*xradius+yradius*yradius);

			startX=controller.map.mouseX;
			startY=controller.map.mouseY;
			var node1:Node=conn.createNode({}, cornerlat     , sourceNode.lon, undo.push);
			var node2:Node=conn.createNode({}, cornerlat     , cornerlon     , undo.push);
			var node3:Node=conn.createNode({}, sourceNode.lat, cornerlon     , undo.push);
			way = conn.createWay(sourceNode.getTagsCopy(), [sourceNode,node1,node2,node3,sourceNode], undo.push);
			for (var k:String in sourceNode.getTagsCopy()) sourceNode.setTag(k, null, undo.push);

			MainUndoStack.getGlobalStack().addAction(undo);
        }
		override public function exitState(newState:ControllerState):void {
			controller.map.draggable=true;
        }

        override public function toString():String {
            return "DrawQuadrilateral";
        }
    }
}
