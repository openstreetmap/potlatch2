package {

	import net.systemeD.halcyon.*;
	import net.systemeD.halcyon.connection.*;
	import flash.system.Security;
	import flash.net.*;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.display.*;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.external.*;
//	import bustin.dev.Inspector;

	public class halcyon_viewer extends Sprite {

		public var theMap:Map;

		function halcyon_viewer():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			this.loaderInfo.addEventListener(Event.COMPLETE, startInit);
		}
	
		private function startInit(e:Event):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, startApp);
			loader.load(new URLRequest("FontLibrary.swf"));
		}

		private function startApp(event:Event):void {
			// Initialise font
			var FontLibrary:Class = event.target.applicationDomain.getDefinition("FontLibrary") as Class;
			Font.registerFont(FontLibrary.DejaVu);

			// Get parameters
			var params:Object={}; var k:String;
			for (k in this.loaderInfo.parameters) params[k]=this.loaderInfo.parameters[k];
			Globals.vars.flashvars = loaderInfo.parameters;	// ** FIXME - not sure we should use flashvars anywhere in Halcyon/P2

			// Initialise map
			theMap = new Map();
            theMap.updateSize(stage.stageWidth, stage.stageHeight);
			addChild(theMap);

			// Add connection
			// ** FIXME - should get the stylesheet from parameters
			var conn:Connection = new XMLConnection("Main", params['api'], params['policy'], params);
			theMap.addLayer(conn, params['style'], false, true);
			theMap.init(params['lat'], params['lon'], params['zoom']);

			Globals.vars.root=theMap;	// ** FIXME - should no longer be necessary
			Globals.vars.nocache = loaderInfo.parameters['nocache'] == 'true';

			stage.addEventListener(MouseEvent.MOUSE_UP, theMap.mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, theMap.mouseMoveHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, theMap.mouseDownHandler);
//			Inspector.getInstance().init(stage);

			// Zoom buttons
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
			theMap.editableLayer.setStyle(str);
		}		
		private function onJumpTo(lat:Number,lon:Number):void {
			theMap.init(lat,lon);
		}

		private function zoomInHandler(e:MouseEvent):void  { e.stopPropagation(); theMap.zoomIn(); }
		private function zoomOutHandler(e:MouseEvent):void { e.stopPropagation(); theMap.zoomOut(); }


	}
}
