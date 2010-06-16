package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.StyleList;
	import net.systemeD.halcyon.styleparser.RuleSet;
    import net.systemeD.halcyon.connection.EntityEvent;

	public class EntityUI {

		protected var sprites:Array=new Array();		// instances in display list
        protected var listenSprite:Sprite=new Sprite();	// clickable sprite to receive events
		protected var stateClasses:Object=new Object();	// special context-sensitive classes, e.g. :hover
		protected var layer:int=0;						// map layer
		protected var interactive:Boolean=true;			// does it respond to connection events?
		protected var suspended:Boolean=false;			// suspend redrawing?
		protected var redrawDue:Boolean=false;			// redraw called while suspended?
		protected var redrawStyleList:StyleList;		// stylelist to be used when redrawing?
		public var paint:MapPaint;						// reference to parent MapPaint
		public var ruleset:RuleSet;						// reference to ruleset in operation

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
			listenSprite.addEventListener(MouseEvent.CLICK, mouseEvent);
			listenSprite.addEventListener(MouseEvent.DOUBLE_CLICK, mouseEvent);
			listenSprite.addEventListener(MouseEvent.ROLL_OVER, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_OUT, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_UP, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
		}

		// Add object (stroke/fill/roadname) to layer sprite
		
		protected function addToLayer(s:DisplayObject,t:uint,sublayer:int=-1):void {
			var l:DisplayObject, o:Sprite;
			if (sublayer!=-1) {
				o=paint.sublayer(layer,sublayer);
			} else {
				l=paint.getChildAt(layer-paint.minlayer);
				o=(l as Sprite).getChildAt(t) as Sprite;
			}
			o.addChild(s);
			sprites.push(s);
            if ( s is Sprite ) {
                Sprite(s).mouseChildren = false;
                Sprite(s).mouseEnabled = false;
            }
		}


		public function removeSprites():void {
			while (sprites.length>0) {
				var d:DisplayObject=sprites.pop();
				if (d.parent) { d.parent.removeChild(d); }
			}
			listenSprite.hitArea=null;
		}

		protected function offsetSprites(x:Number, y:Number):void {
			for each (var d:DisplayObject in sprites) {
				d.x=x; d.y=y;
			}
		}

		protected function setListenSprite(hitzone:Sprite):void {
			if (!listenSprite.parent) { addToLayer(listenSprite, CLICKSPRITE); }
            listenSprite.hitArea = hitzone;
            listenSprite.buttonMode = true;
            listenSprite.mouseChildren = true;
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
		
		// Redraw control
		
		public function redraw(sl:StyleList=null):Boolean {
			if (suspended) { redrawStyleList=sl; redrawDue=true; return false; }
			return doRedraw(sl);
		}
		
		public function doRedraw(sl:StyleList):Boolean {
			// to be overwritten
			return false;
		}
		
		public function suspendRedraw(event:EntityEvent):void {
			suspended=true;
			redrawDue=false;
		}
		
		public function resumeRedraw(event:EntityEvent):void {
			suspended=false;
			if (redrawDue) { 
				doRedraw(redrawStyleList);
				redrawDue=false;
				redrawStyleList=null; 
			}
		}

	}

}
