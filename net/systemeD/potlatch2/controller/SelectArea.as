package net.systemeD.potlatch2.controller {

	import flash.display.*;
	import flash.events.*;
	import net.systemeD.halcyon.connection.*;

    public class SelectArea extends ControllerState {

		private var startX:Number;
		private var startY:Number;
		private var endX:Number;
		private var endY:Number;
		private var box:Shape;
		private const TOLERANCE:uint=4;

		public function SelectArea(x:Number,y:Number) {
			startX=endX=x;
			startY=endY=y;
		}

        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            if (event.type==MouseEvent.MOUSE_MOVE) { 
				// ** FIXME: weird things happen if you mouse-over the drag-and-drop panel
				endX=event.localX;
				endY=event.localY;
				drawSelectionBox();
			} else if (event.type==MouseEvent.MOUSE_UP) { 
				// select everything within boundary
				var a:Number;
				if (startX>endX) { a=startX; startX=endX; endX=a; }
				if (startY>endY) { a=startY; startY=endY; endY=a; }
				if (endX-startX<TOLERANCE && endY-startY<TOLERANCE) { return new NoSelection(); }
				var left:Number=controller.map.coord2lon(startX);
				var right:Number=controller.map.coord2lon(endX);
				var top:Number=controller.map.coord2lat(startY);
				var bottom:Number=controller.map.coord2lat(endY);
				var entities:Object=layer.connection.getObjectsByBbox(left,right,top,bottom);
				for each (var way:Way  in entities.waysInside) { if (way.intersects(left,right,top,bottom)) toggleSelection(way); }
				for each (var poi:Node in entities.poisInside) { toggleSelection(poi); }
				return controller.findStateForSelection(selection);
			}
            return this;
        }

		private function drawSelectionBox():void {
			box.graphics.clear();
			box.graphics.beginFill(0xDDDDFF,0.5);
			box.graphics.lineStyle(1,0xFF0000);
			box.graphics.drawRect(startX,startY,endX-startX,endY-startY);
		}
		
		override public function enterState():void {
			box=new Shape();
			var l:DisplayObject=layer.getPaintSpriteAt(layer.maxlayer);
			var o:DisplayObject=Sprite(l).getChildAt(3);
			(o as Sprite).addChild(box);
			controller.map.draggable=false;
		}
		override public function exitState(newState:ControllerState):void {
			box.parent.removeChild(box);
			controller.map.draggable=true;
			if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
		}
		override public function toString():String {
			return "SelectArea";
		}
	}

}
