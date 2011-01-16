package net.systemeD.controls {

	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.Timer;

	public class FloatingAlert extends Sprite {

		private var textfield:TextField;
		private var h:int;
		private var w:int;
		private var timer:Timer;
		
		public function FloatingAlert(message:String) {
			super();

			textfield=new TextField();
			textfield.defaultTextFormat=new TextFormat("_sans", 15, 0xFFFFFF, true);
			textfield.autoSize=TextFieldAutoSize.LEFT;
			textfield.text=message;
			textfield.x=10;
			textfield.y=3;
			addChild(textfield);

			w=textfield.textWidth+20;
			h=textfield.textHeight+10;

			graphics.lineStyle(2,0);
            graphics.beginFill(0x6495ED,100); 
            graphics.drawRoundRect(0,0,w,h,10);
            graphics.endFill();

			textfield.alpha=alpha=0;
			addEventListener(Event.ADDED_TO_STAGE, start);
		}
		
		private function start(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, start);
			x=(stage.stageWidth-w)/2;
			y=stage.stageHeight;

			timer=new Timer(20,30);
			timer.addEventListener(TimerEvent.TIMER, floatUpwards);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, floatFinished);
			timer.start();
		}
		
		private function floatUpwards(event:TimerEvent):void {
			y-=2;
			alpha+=0.035;
			textfield.alpha=alpha;
		}
		
		private function floatFinished(event:TimerEvent):void {
			timer.removeEventListener(TimerEvent.TIMER, floatUpwards);
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, floatFinished);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, clear);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, clear);
		}
		
		private function clear(event:Event):void {
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, clear);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, clear);
			parent.removeChild(this);
		}
	}
}
