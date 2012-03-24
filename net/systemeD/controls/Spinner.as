package net.systemeD.controls {
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.utils.Timer;
	import flash.filters.GlowFilter;
	
	// Adapted from http://www.stevensacks.net/2008/10/01/as3-apple-style-preloader/

	public class Spinner extends Sprite {
		private var timer:Timer;
		private var slices:int;
		private var radius:int;

		public function Spinner(slices:int = 12, radius:int = 6) {
			super();
			this.slices = slices;
			this.radius = radius;
			draw();

			var filter:GlowFilter=new GlowFilter(0xFFFFFF,1,4,4,6);
			this.filters = [filter];
		}

		public function start():void {
			visible=true;
			if (timer) return;
			timer = new Timer(65);
			timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
			timer.start();
		}

		public function stop():void {
			visible=false;
			if (!timer) return;
			timer.reset();
			timer.removeEventListener(TimerEvent.TIMER, onTimer);
			timer = null;
		}

		private function onTimer(event:TimerEvent):void {
			rotation = (rotation + (360 / slices)) % 360;
		}
		
		private function draw():void {
			var i:int = slices;
			var degrees:int = 360 / slices;
			while (i--) {
				var slice:Shape = getSlice();
				slice.alpha = Math.max(0.2, 1 - (0.1 * i));
				var radianAngle:Number = (degrees * i) * Math.PI / 180;
				slice.rotation = -degrees * i;
				slice.x = Math.sin(radianAngle) * radius;
				slice.y = Math.cos(radianAngle) * radius;
				addChild(slice);
			}
		}

		private function getSlice():Shape {
			var slice:Shape = new Shape();
			slice.graphics.beginFill(0x666666);
			slice.graphics.drawRoundRect(-1, 0, 2, 6, 12, 12);
			slice.graphics.endFill();
			return slice;
		}
	}
}
