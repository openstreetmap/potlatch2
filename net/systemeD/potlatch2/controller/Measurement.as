package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.Point;
	import net.systemeD.potlatch2.EditController;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Elastic;
	import net.systemeD.halcyon.AttentionEvent;

	public class Measurement extends ControllerState {

		private var elastic:Elastic;
		protected var previousState:ControllerState;
        
		public function Measurement(previousState:ControllerState) {
			this.previousState = previousState;
		}
 
		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {

			if (event.type==MouseEvent.MOUSE_UP && !elastic) {
				// click to start
				var start:Point = new Point(controller.map.coord2lon(event.localX),
				                            controller.map.coord2latp(event.localY));
				elastic = new Elastic(controller.map, start, start);
				return this;

			} else if (event.type==MouseEvent.MOUSE_UP) {
				// click to exit
				controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Distance "+Math.round(getDistance()*10)/10+"m"));
				elastic.removeSprites();
				elastic = null;
				return previousState;

			} else if (event.type==MouseEvent.MOUSE_MOVE && elastic) {
				// update elastic line
				var point:Point = new Point(controller.map.coord2lon(event.localX),
				                            controller.map.coord2latp(event.localY));
				elastic.end = point;
				return this;

			}
			// event not handled
			return this;
		}

		private function getDistance():Number {
			return Trace.greatCircle(controller.map.latp2lat(elastic.start.y), elastic.start.x,
				                     controller.map.latp2lat(elastic.end.y  ), elastic.end.x);
		}

		override public function toString():String {
			return "Measurement";
		}
	}
}
