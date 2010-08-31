package {

	import net.systemeD.halcyon.*;
	import net.systemeD.halcyon.connection.*;
	import flash.system.Security;
	import flash.net.*;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.display.*;
	import flash.text.TextField;
	import flash.external.*;
//	import bustin.dev.Inspector;

	public class halcyon_viewer extends Sprite {

		public var theMap:Map;

		function halcyon_viewer():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			this.loaderInfo.addEventListener(Event.COMPLETE, init);
		}
	
		private function init(e:Event):void {

			theMap = new Map(this.loaderInfo.parameters);
            theMap.updateSize(stage.stageWidth, stage.stageHeight);
			addChild(theMap);
			Globals.vars.root=theMap;
			Globals.vars.nocache = loaderInfo.parameters['nocache'] == 'true';

			// add debug field
			var t:TextField=new TextField();
			t.width=400; t.height=100; t.x=400; t.border=true;
			t.multiline=true;
			addChild(t);
			Globals.vars.debug=t;
            t.visible = loaderInfo.parameters["show_debug"] == 'true';

			stage.addEventListener(MouseEvent.MOUSE_UP, theMap.mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, theMap.mouseMoveHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, theMap.mouseDownHandler);
//			Inspector.getInstance().init(stage);

			var z1:Sprite=new Sprite();
			z1.graphics.beginFill(0x0000FF); z1.graphics.drawRoundRect(0,0,20,20,5); z1.graphics.endFill();
			z1.graphics.lineStyle(2,0xFFFFFF);
			z1.graphics.moveTo(5,10); z1.graphics.lineTo(15,10);
			z1.graphics.moveTo(10,5); z1.graphics.lineTo(10,15);
			z1.x=5; z1.y=5; z1.buttonMode=true;
			z1.addEventListener(MouseEvent.CLICK, zoomInHandler, false, 1);
			addChild(z1);

			var z2:Sprite=new Sprite();
			z2.graphics.beginFill(0x0000FF); z2.graphics.drawRoundRect(0,0,20,20,5); z2.graphics.endFill();
			z2.graphics.lineStyle(2,0xFFFFFF);
			z2.graphics.moveTo(5,10); z2.graphics.lineTo(15,10);
			z2.x=5; z2.y=30; z2.buttonMode=true;
			z2.addEventListener(MouseEvent.CLICK, zoomOutHandler, false, 1);
			addChild(z2);

			if (this.loaderInfo.parameters.hasOwnProperty('responder')) {
            	var controller:JSController = new JSController(theMap, loaderInfo.parameters['responder']);
				controller.setActive();
			}

			ExternalInterface.addCallback('refreshCSS', onRefreshCSS);
			ExternalInterface.addCallback('jumpTo', onJumpTo);
		}

		private function onRefreshCSS(str:String):void {
			theMap.setStyle(str);
		}		
		private function onJumpTo(lat:Number,lon:Number):void {
			theMap.init(lat,lon);
		}

		private function zoomInHandler(e:MouseEvent):void  { e.stopPropagation(); theMap.zoomIn(); }
		private function zoomOutHandler(e:MouseEvent):void { e.stopPropagation(); theMap.zoomOut(); }


	}
}
