package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.Stage;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Map;
	import net.systemeD.potlatch2.tools.Parallelise;
	import net.systemeD.halcyon.Globals;

    public class SelectedParallelWay extends SelectedWay {
		private var startlon:Number;
		private var startlatp:Number;
		private var parallelise:Parallelise;

        public function SelectedParallelWay(originalWay:Way) {
			parallelise = new Parallelise(originalWay);
			selectedWay=parallelise.parallelWay;
			super (selectedWay);
        }

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE) {
				var lon:Number =controller.map.coord2lon(controller.map.mouseX);
				var latp:Number=controller.map.coord2latp(controller.map.mouseY);
				var offset:Number=Math.sqrt(Math.pow(lon-startlon,2)+
				                            Math.pow(latp-startlatp,2));
				if (lon<startlon) { offset=-offset; }	// ** this should be smarter than just lon<startlon
				parallelise.draw(offset);
			} else if (event.type==MouseEvent.MOUSE_UP) {
				return new SelectedWay(selectedWay);
			}
			return this;
        }

		private function sgn(a:Number):Number {
			if (a==0) return 0;
			if (a<0) return -1;
			return 1;
		}

		override public function enterState():void {
			startlon =controller.map.coord2lon(controller.map.mouseX);
			startlatp=controller.map.coord2latp(controller.map.mouseY);
			Globals.vars.root.addDebug("**** -> "+this);
        }
		override public function exitState():void {
            clearSelection();
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "SelectedParallelWay";
        }
    }
}
