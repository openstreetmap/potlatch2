package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.*;
	import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Elastic;
	import net.systemeD.halcyon.Globals;

	public class DrawWay extends SelectedWay {
		private var elastic:Elastic;
		private var editEnd:Boolean;
		
		public function DrawWay(way:Way, editEnd:Boolean) {
			super(way);
			this.editEnd = editEnd;
		}
		
		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			var mouse:Point;
			var node:Node;
			var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);

			if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity == null ) {
					node = createAndAddNode(event);
					resetElastic(node);
				} else if ( entity is Node ) {
					appendNode(entity as Node);
					controller.map.setHighlight(focus, { showNodesHover: false });
					controller.map.setHighlight(selectedWay, { showNodes: true });
					resetElastic(entity as Node);
				} else if ( entity is Way ) {
					node = createAndAddNode(event);
					Way(entity).insertNodeAtClosestPosition(node, true);
					resetElastic(node);
				}
			} else if ( event.type == MouseEvent.MOUSE_MOVE ) {
				mouse = new Point(
						  controller.map.coord2lon(event.localX),
						  controller.map.coord2latp(event.localY));
				elastic.end = mouse;
			} else if ( event.type == MouseEvent.MOUSE_OVER && focus!=selectedWay) {
				controller.map.setHighlight(focus, { showNodesHover: true });
			} else if ( event.type == MouseEvent.MOUSE_OUT  && focus!=selectedWay) {
				controller.map.setHighlight(focus, { showNodesHover: false });
				controller.map.setHighlight(selectedWay, { showNodes: true });
				// ** this call to setHighlight(selectedWay) is necessary in case the hovered way (blue nodes)
				// shares any nodes with the selected way (red nodes): if they do, they'll be wiped out by the
				// first call.
				// Ultimately we should fix this by referring to 'way :selected nodes' instead of 'nodes :selectedway'.
				// But this will do for now.
				// We could do with an optional way of calling WayUI.redraw to only do the nodes, which would be a
				// useful optimisation.
			}

			return this;
		}
		
		protected function resetElastic(node:Node):void {
			var mouse:Point = new Point(node.lon, node.latp);
			elastic.start = mouse;
			elastic.end = mouse;
		}

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if ( event.keyCode == 13 || event.keyCode == 27 )
				return new SelectedWay(selectedWay);
			return this;
		}

		public function createAndAddNode(event:MouseEvent):Node {
			var lat:Number = controller.map.coord2lat(event.localY);
			var lon:Number = controller.map.coord2lon(event.localX);
			var node:Node = controller.connection.createNode({}, lat, lon);
			appendNode(node);
			return node;
		}
		
		protected function appendNode(node:Node):void {
			if ( editEnd )
				selectedWay.appendNode(node);
			else
				selectedWay.insertNode(0, node);
		}
		
		override public function enterState():void {
			super.enterState();
			
			var node:Node = selectedWay.getNode(editEnd ? selectedWay.length - 1 : 0);
			var start:Point = new Point(node.lon, node.latp);
			elastic = new Elastic(controller.map, start, start);
			Globals.vars.root.addDebug("**** -> "+this);
		}
		override public function exitState():void {
			super.exitState();
			elastic.removeSprites();
			elastic = null;
			Globals.vars.root.addDebug("**** <- "+this);
		}
		override public function toString():String {
			return "DrawWay";
		}
	}
}
