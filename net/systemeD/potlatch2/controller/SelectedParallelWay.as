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
		private var originalWay:Way;

        public function SelectedParallelWay(originalWay:Way) {
			this.originalWay = originalWay;
			parallelise = new Parallelise(originalWay);
			selectedWay=parallelise.parallelWay;
			super (selectedWay);
        }

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE) {
				var lon:Number =controller.map.coord2lon(controller.map.mouseX);
				var latp:Number=controller.map.coord2latp(controller.map.mouseY);
				parallelise.draw(distanceFromWay(lon,latp));
			} else if (event.type==MouseEvent.MOUSE_UP) {
				return new SelectedWay(selectedWay);
			}
			return this;
        }

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==27) {			// Escape
				selectedWay.remove(MainUndoStack.getGlobalStack().addAction);
				return new NoSelection();
			}
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}

		private function sgn(a:Number):Number {
			if (a==0) return 0;
			if (a<0) return -1;
			return 1;
		}
		
		private function distanceFromWay(lon:Number,latp:Number):Number {
			var i:uint, ax:Number, ay:Number, bx:Number, by:Number, l:Number;
			var ad:Number, bd:Number;
			var r:Number, px:Number, py:Number;
			var furthdist:Number=-1; var furthsgn:int=1;
			for (i=0; i<originalWay.length-1; i++) {
				ax=originalWay.getNode(i).lon;
				ay=originalWay.getNode(i).latp;
				bx=originalWay.getNode(i+1).lon;
				by=originalWay.getNode(i+1).latp;

				ad=Math.sqrt(Math.pow(lon-ax,2)+Math.pow(latp-ay,2));	// distance to ax,ay
				bd=Math.sqrt(Math.pow(bx-lon,2)+Math.pow(by-latp,2));	// distance to bx,by
				l =Math.sqrt(Math.pow(bx-ax ,2)+Math.pow(by-ay  ,2));	// length of segment
				r =ad/(ad+bd);											// proportion along segment
				px=ax+r*(bx-ax); py=ay+r*(by-ay);						// nearest point on line
				r=Math.sqrt(Math.pow(px-lon,2)+Math.pow(py-latp,2));	// distance from px,py to lon,latp

				if (furthdist<0 || furthdist>r) {
					furthdist=r; 
					furthsgn=sgn((bx-ax)*(latp-ay)-(by-ay)*(lon-ax));
				}
			}
			return furthdist*furthsgn;
		}

		override public function enterState():void {
			controller.map.paint.createWayUI(selectedWay);
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
