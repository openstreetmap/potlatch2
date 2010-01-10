package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.StyleList;

	public class EntityUI {

		protected var sprites:Array=new Array();		// instances in display list
        protected var listenSprite:Sprite;				// clickable sprite to receive events
		protected var stateClasses:Object=new Object();	// special context-sensitive classes, e.g. :hover
		protected var layer:int=0;						// map layer
		public var map:Map;								// reference to parent map

		protected const FILLSPRITE:uint=0;
		protected const CASINGSPRITE:uint=1;
		protected const STROKESPRITE:uint=2;
		protected const NAMESPRITE:uint=3;
		protected const NODESPRITE:uint=4;
		protected const CLICKSPRITE:uint=5;

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};

		public function EntityUI() {
		}

		// Add object (stroke/fill/roadname) to layer sprite
		
		protected function addToLayer(s:DisplayObject,t:uint,sublayer:int=-1):void {
			var l:DisplayObject=Map(map).getChildAt(map.WAYSPRITE+layer);
			var o:DisplayObject=Sprite(l).getChildAt(t);
			if (sublayer!=-1) { o=Sprite(o).getChildAt(sublayer); }
			Sprite(o).addChild(s);
			sprites.push(s);
            if ( s is Sprite ) {
                Sprite(s).mouseEnabled = false;
                Sprite(s).mouseChildren = false;
            }
		}
		
		public function removeSprites():void {
			while (sprites.length>0) {
				var d:DisplayObject=sprites.pop();
				if (d.parent) { d.parent.removeChild(d); }
			}
			listenSprite=null;
		}

		protected function createListenSprite(hitzone:Sprite):void {
            if ( listenSprite == null ) {
                listenSprite = new Sprite();
                listenSprite.addEventListener(MouseEvent.CLICK, mouseEvent);
                listenSprite.addEventListener(MouseEvent.DOUBLE_CLICK, mouseEvent);
                listenSprite.addEventListener(MouseEvent.MOUSE_OVER, mouseEvent);
                listenSprite.addEventListener(MouseEvent.MOUSE_OUT, mouseEvent);
                listenSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
                listenSprite.addEventListener(MouseEvent.MOUSE_UP, mouseEvent);
                listenSprite.addEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
            }
            listenSprite.hitArea = hitzone;
            addToLayer(listenSprite, CLICKSPRITE);
            listenSprite.buttonMode = true;
            listenSprite.mouseEnabled = true;
		}

        protected function mouseEvent(event:MouseEvent):void {
        }

        public function setHighlight(stateType:String, isOn:*):void {
            if ( isOn && stateClasses[stateType] == null ) {
                stateClasses[stateType] = isOn;
            } else if ( !isOn && stateClasses[stateType] != null ) {
                delete stateClasses[stateType];
            }
        }

		protected function applyStateClasses(tags:Object):Object {
            for (var stateKey:String in stateClasses) {
                tags[":"+stateKey] = 'yes';
            }
			return tags;
		}
		
		public function redraw(sl:StyleList=null):Boolean {
			return false;
		}

	}

}
