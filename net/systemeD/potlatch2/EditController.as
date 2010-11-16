package net.systemeD.potlatch2 {
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapController;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.controller.*;
	import mx.managers.CursorManager;
	import flash.events.*;
	import flash.geom.*;

    public class EditController implements MapController {

        private var _map:Map;
        public var tagViewer:TagViewer;
		private var toolbox:Toolbox;
        
        public var state:ControllerState;
        private var _connection:Connection;
        
		private var keys:Object={};
		public var clipboards:Object={};
		public var imagery:Array=[];
		public var imagerySelected:Object={};
		public var stylesheets:Array=[];
		public var cursorsEnabled:Boolean=true;

		[Embed(source="../../../embedded/pen.png")] 		public var pen:Class;
		[Embed(source="../../../embedded/pen_x.png")] 		public var pen_x:Class;
		[Embed(source="../../../embedded/pen_o.png")] 		public var pen_o:Class;
		[Embed(source="../../../embedded/pen_so.png")] 		public var pen_so:Class;
		[Embed(source="../../../embedded/pen_plus.png")] 	public var pen_plus:Class;
		
        public function EditController(map:Map, tagViewer:TagViewer, toolbox:Toolbox) {
            this._map = map;
            setState(new NoSelection());
            this.tagViewer = tagViewer;
			this.toolbox = toolbox;
			this.toolbox.init(this);

            
            map.parent.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_UP, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_DOWN, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_WHEEL, mapMouseEvent);
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
        
		public function updateSelectionUI():void {
			tagViewer.setEntity(state.selection);
			toolbox.updateSelectionUI();
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
            if (event.type!=MouseEvent.ROLL_OVER) map.stage.focus = map.parent;
            if (event.type==MouseEvent.MOUSE_UP && map.dragstate==map.DRAGGING) { return; }
            
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, null);
            setState(newState);
        }
        
        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if (event.type!=MouseEvent.ROLL_OVER) map.stage.focus = map.parent;
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
                state.exitState(newState);
            newState.setController(this);
            newState.setPreviousState(state);
            state = newState;
            state.enterState();
        }

		public function findStateForSelection(sel:Array):ControllerState {
			if (sel.length==0) { return new NoSelection(); }
			else if (sel.length>1) { return new SelectedMultiple(sel); }
			else if (sel[0] is Way) { return new SelectedWay(sel[0]); }
			else if (sel[0] is Node && Node(sel[0]).hasParentWays) {
				var way:Way=sel[0].parentWays[0] as Way;
				return new SelectedWayNode(way, way.indexOfNode(sel[0] as Node));
			} else {
				return new SelectedPOINode(sel[0] as Node);
			}
		}

		public function setCursor(cursor:Class):void {
			CursorManager.removeAllCursors();
			if (cursor && cursorsEnabled) { CursorManager.setCursor(cursor,2,-4,0); }
		}

    }

    
}

