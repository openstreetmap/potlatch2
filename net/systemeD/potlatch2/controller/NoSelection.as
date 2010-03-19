package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.Globals;

	public class NoSelection extends ControllerState {

		public function NoSelection() {
		}
 
		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			var focus:Entity = getTopLevelFocusEntity(entity);

			if ( event.type == MouseEvent.MOUSE_DOWN ) {
				if ( entity is Way ) {
					return new SelectedWay(focus as Way);
                } else if ( focus is Node ) {
					return new DragPOINode(entity as Node,event,false);
                } else if ( entity is Node && focus is Way ) {
					return new DragWayNode(focus as Way,entity as Node,event,false);
				}
			} else if (event.type==MouseEvent.MOUSE_UP && focus==null && map.dragstate!=map.DRAGGING) {
				map.dragstate=map.NOT_DRAGGING;
				var startNode:Node = controller.connection.createNode(
					{}, 
					controller.map.coord2lat(event.localY),
					controller.map.coord2lon(event.localX));
				var way:Way = controller.connection.createWay({}, [startNode]);
				return new DrawWay(way, true, false);
			} else if ( event.type == MouseEvent.ROLL_OVER ) {
				controller.map.setHighlight(focus, { hover: true });
			} else if ( event.type == MouseEvent.MOUSE_OUT ) {
				controller.map.setHighlight(focus, { hover: false });
			} else if ( event.type == MouseEvent.MOUSE_DOWN ) {
			}
			return this;
		}
		
		public static function getTopLevelFocusEntity(entity:Entity):Entity {
			if ( entity is Node ) {
				for each (var parent:Entity in entity.parentWays) {
					return parent;
				}
				return entity;
			} else if ( entity is Way ) {
				return entity;
			} else {
				return null;
			}
		}

        override public function enterState():void {
			Globals.vars.root.addDebug("**** -> "+this);
        }
        override public function exitState():void {
			Globals.vars.root.addDebug("**** <- "+this);
        }
		override public function toString():String {
			return "NoSelection";
		}

	}
}
