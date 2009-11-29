package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.geom.*;
    import net.systemeD.potlatch2.EditController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Elastic;
	import net.systemeD.halcyon.Globals;

    public class CreateWay extends ControllerState {
        private var start:Point;
        private var mouse:Point;
        private var elastic:Elastic;
        
        public function CreateWay(event:MouseEvent) {
            start = new Point(event.localX, event.localY);
            mouse = new Point(event.localX, event.localY);
        }
        
        override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
            var focus:Entity = NoSelection.getTopLevelFocusEntity(entity);
            if ( event.type == MouseEvent.MOUSE_UP ) {
                if ( focus == null ) {
                    var lat:Number = controller.map.coord2lat(event.localY);
                    var lon:Number = controller.map.coord2lon(event.localX);
                    var endNode:Node = controller.connection.createNode({}, lat, lon);
                    
                    lat = Node.latp2lat(start.y);
                    lon = start.x;
                    var startNode:Node = controller.connection.createNode({}, lat, lon);
                    
                    var way:Way = controller.connection.createWay({}, [startNode, endNode]);
                    return new DrawWay(way, true);
                }
            } else if ( event.type == MouseEvent.MOUSE_MOVE ) {
                mouse = new Point(
                          controller.map.coord2lon(event.localX),
                          controller.map.coord2latp(event.localY));
                elastic.end = mouse;
            }

            return this;
        }

        override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
            if ( event.keyCode == 27 )
                return new NoSelection();
            return this;
        }

        override public function enterState():void {
            // transform points
            start.x = controller.map.coord2lon(start.x);
            start.y = controller.map.coord2latp(start.y);
            mouse.x = controller.map.coord2lon(mouse.x);
            mouse.y = controller.map.coord2latp(mouse.y);
            
            elastic = new Elastic(controller.map, start, mouse);
			Globals.vars.root.addDebug("**** -> "+this);
        }
        
        override public function exitState():void {
            elastic.removeSprites();
            elastic = null;
			Globals.vars.root.addDebug("**** <- "+this);
        }

        override public function toString():String {
            return "CreateWay";
        }
    }
}
