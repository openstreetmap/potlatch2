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

			if ( event.type == MouseEvent.MOUSE_UP ) {
				if ( entity == null ) {
					node = createAndAddNode(event);
					resetElastic(node);
				} else if ( entity is Node ) {
					appendNode(entity as Node);
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
