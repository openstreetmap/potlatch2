package net.systemeD.potlatch2 {
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.controller.*;
	import flash.events.*;
	import flash.geom.*;

    public class EditController implements MapController {

        private var _map:Map;
        private var tagViewer:TagViewer;
		private var toolbox:Toolbox;
        
        public var state:ControllerState;
        private var _connection:Connection;
        
		private var keys:Object={};

        public function EditController(map:Map, tagViewer:TagViewer, toolbox:Toolbox) {
            this._map = map;
            this.tagViewer = tagViewer;
			this.toolbox = toolbox;
			this.toolbox.init(this);
            setState(new NoSelection());
            
            map.parent.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_UP, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_DOWN, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.CLICK, mapMouseEvent);
            map.parent.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            map.parent.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
        }

        public function setActive():void {
            map.setController(this);
            _connection = map.connection;
        }

        public function get map():Map {
            return _map;
        }
        
        public function get connection():Connection {
            return _connection;
        }
        
        public function setSelectedEntity(entity:Entity):void {
            tagViewer.setEntity(entity);
			toolbox.setEntity(entity);
        }
        
        private function keyDownHandler(event:KeyboardEvent):void {
			keys[event.keyCode]=true;
		}

        private function keyUpHandler(event:KeyboardEvent):void {
            trace("key code "+event.keyCode);
			if (keys[event.keyCode]) { delete keys[event.keyCode]; }
            var newState:ControllerState = state.processKeyboardEvent(event);
            setState(newState);            
		}

		public function keyDown(key:Number):Boolean {
			return Boolean(keys[key]);
		}

        private function mapMouseEvent(event:MouseEvent):void {
            map.stage.focus = map.parent;
            
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, null);
            setState(newState);
        }
        
        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            map.stage.focus = map.parent;
            //if ( event.type == MouseEvent.MOUSE_DOWN )
            event.stopPropagation();
                
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, entity);
            setState(newState);
        }
        
        public function setState(newState:ControllerState):void {
            if ( newState == state )
                return;
                
            if ( state != null )
                state.exitState();
            newState.setController(this);
            newState.setPreviousState(state);
            state = newState;
            state.enterState();
        }

    }

    
}

