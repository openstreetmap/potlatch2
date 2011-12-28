package net.systemeD.potlatch2 {
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.MapController;
    import net.systemeD.halcyon.MapEvent;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.Globals;
    import net.systemeD.potlatch2.controller.*;
    import net.systemeD.potlatch2.FunctionKeyManager;
	import mx.managers.CursorManager;
    import flash.external.ExternalInterface;
    import flash.events.*;
	import flash.geom.*;
	import flash.display.*;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursorData;
	import flash.text.TextField;
    import mx.controls.TextArea;

    /** Controller for the main map editing window itself. The logic that responds to mouse and keyboard events is all 
    * buried in various ControllerState classes. */
    public class EditController extends EventDispatcher implements MapController {

        private var _map:Map;
        public var tagViewer:TagViewer;
		private var toolbox:Toolbox;

        /** The current ControllerState */
        public var state:ControllerState;
        
		private var keys:Object={};
		public var clipboards:Object={};
		public var cursorsEnabled:Boolean=true;
        private var maximised:Boolean=false;
        private var maximiseFunction:String;
        private var minimiseFunction:String;
        private var moveFunction:String;

		[Embed(source="../../../embedded/pen.png")] 		public var pen:Class;
		[Embed(source="../../../embedded/pen_x.png")] 		public var pen_x:Class;
		[Embed(source="../../../embedded/pen_o.png")] 		public var pen_o:Class;
		[Embed(source="../../../embedded/pen_so.png")] 		public var pen_so:Class;
		[Embed(source="../../../embedded/pen_plus.png")] 	public var pen_plus:Class;
		
        /** Constructor function: needs the map information, a panel to edit tags with, and the toolbox to manipulate ways with. */
        public function EditController(map:Map, tagViewer:TagViewer, toolbox:Toolbox) {
            this._map = map;
            setState(new NoSelection());
            this.tagViewer = tagViewer;
            this.tagViewer.controller = this;
			this.toolbox = toolbox;
			this.toolbox.init(this);
			this.toolbox.updateSelectionUI();
            this.maximiseFunction = Globals.vars.flashvars["maximise_function"];
            this.minimiseFunction = Globals.vars.flashvars["minimise_function"];
            this.moveFunction     = Globals.vars.flashvars["move_function"];

            map.parent.addEventListener(MouseEvent.MOUSE_MOVE, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_UP, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_DOWN, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.MOUSE_WHEEL, mapMouseEvent);
            map.parent.addEventListener(MouseEvent.CLICK, mapMouseEvent);
            map.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            map.stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);

            if (this.moveFunction) {
                map.addEventListener(MapEvent.MOVE, moveHandler);
            }

			createBitmapCursor("pen"     ,new pen());
			createBitmapCursor("pen_x"   ,new pen_x());
			createBitmapCursor("pen_o"   ,new pen_o());
			createBitmapCursor("pen_so"  ,new pen_so());
			createBitmapCursor("pen_plus",new pen_plus());
        }

        public function setActive():void {
            map.setController(this);
        }

        /** Accesses map object. */
        public function get map():Map {
            return _map;
        }
        
        /**
        * Updates the various user interfaces that change when the selection changes.
        * Currently this is the TagViewer and the Toolbox
        *
        * @param layer Optionally pass the layer of the currently selected entity, eg for BugLayers
        */
		public function updateSelectionUI(layer:MapPaint = null):void {
			tagViewer.setEntity(state.selection, layer);
			toolbox.updateSelectionUI();
		}

		public function updateSelectionUIWithoutTagChange():void {
			toolbox.updateSelectionUI();
		}
        
        private function keyDownHandler(event:KeyboardEvent):void {
			if ((event.target is TextField) || (event.target is TextArea)) return;
			keys[event.keyCode]=true;
		}

        private function keyUpHandler(event:KeyboardEvent):void {
            if (!keys[event.keyCode]) return;
            delete keys[event.keyCode];
            if ((event.target is TextField) || (event.target is TextArea)) return;				// not meant for us

			if (FunctionKeyManager.instance().handleKeypress(event.keyCode)) { return; }
            
            if (event.keyCode == 77) { toggleSize(); } // 'M'
            var newState:ControllerState = state.processKeyboardEvent(event);
            setState(newState);            
		}

		/** Is the given key currently pressed? */
		public function keyDown(key:Number):Boolean {
			return Boolean(keys[key]);
		}

        private function mapMouseEvent(event:MouseEvent):void {
            if (isInteractionEvent(event)) map.stage.focus = map.parent;
            if (event.type==MouseEvent.MOUSE_UP && map.dragstate==map.DRAGGING) { return; }
            
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, null);
            setState(newState);
        }
        
        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if (isInteractionEvent(event)) map.stage.focus = map.parent;
            event.stopPropagation();
                
            var mapLoc:Point = map.globalToLocal(new Point(event.stageX, event.stageY));
            event.localX = mapLoc.x;
            event.localY = mapLoc.y;

            var newState:ControllerState = state.processMouseEvent(event, entity);
            setState(newState);
        }

		private function isInteractionEvent(event:MouseEvent):Boolean {
			switch (event.type) {
				case MouseEvent.ROLL_OUT:	return false;
				case MouseEvent.ROLL_OVER:	return false;
				case MouseEvent.MOUSE_OUT:	return false;
				case MouseEvent.MOUSE_OVER:	return false;
				case MouseEvent.MOUSE_MOVE:	return false;
        	}
			return true;
		}

        /** Exit the current state and switch to a new one.
        *
        *   @param newState The ControllerState to switch to. */
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

		/** Given what is currently selected (or not), find the matching ControllerState. */
		public function findStateForSelection(sel:Array):ControllerState {
			if (sel.length==0) { return new NoSelection(); }
			var layer:MapPaint=_map.getLayerForEntity(sel[0]);
			
			if (sel.length>1) { return new SelectedMultiple(sel, layer); }
			else if (sel[0] is Way) { return new SelectedWay(sel[0], layer); }
			else if (sel[0] is Node && Node(sel[0]).hasParentWays) {
				var way:Way=sel[0].parentWays[0] as Way;
				return new SelectedWayNode(way, way.indexOfNode(sel[0] as Node));
			} else {
				return new SelectedPOINode(sel[0] as Node, layer);
			}
		}

		/** Set a mouse pointer. */
		public function setCursor(name:String=""):void {
			if (name && cursorsEnabled) { Mouse.cursor=name; }
			else { Mouse.cursor=flash.ui.MouseCursor.AUTO; }
		}

		private function createBitmapCursor(name:String, source:Bitmap, hotX:int=4, hotY:int=0):void {
			var bitmapVector:Vector.<BitmapData> = new Vector.<BitmapData>(1, true);
			bitmapVector[0] = source.bitmapData;
			var cursorData:MouseCursorData = new MouseCursorData();
			cursorData.hotSpot = new Point(hotX,hotY);
			cursorData.data = bitmapVector;
			Mouse.registerCursor(name, cursorData);
		}

        private function toggleSize():void {
            if (maximised) {
                if (minimiseFunction) {
                    ExternalInterface.call(minimiseFunction);
                }

                maximised = false;
            } else {
                if (maximiseFunction) {
                    ExternalInterface.call(maximiseFunction);
                }

                maximised = true;
            }
        }

		private function moveHandler(event:MapEvent):void {
			ExternalInterface.call(this.moveFunction,
                                   event.params.lon, event.params.lat, event.params.scale,
                                   event.params.minlon, event.params.minlat,
                                   event.params.maxlon, event.params.maxlat);
		}

    }
    
}
