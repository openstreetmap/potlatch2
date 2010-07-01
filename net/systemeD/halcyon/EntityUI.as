package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.StyleList;
	import net.systemeD.halcyon.styleparser.RuleSet;
    import net.systemeD.halcyon.connection.*;

	public class EntityUI {

		protected var entity:Entity;
		protected var sprites:Array=new Array();		// instances in display list
        protected var listenSprite:Sprite=new Sprite();	// clickable sprite to receive events
		protected var stateClasses:Object=new Object();	// special context-sensitive classes, e.g. :hover
		protected var layer:int=0;						// map layer
		protected var suspended:Boolean=false;			// suspend redrawing?
		protected var redrawDue:Boolean=false;			// redraw called while suspended?
		protected var redrawStyleList:StyleList;		// stylelist to be used when redrawing?
		public var paint:MapPaint;						// reference to parent MapPaint
		public var ruleset:RuleSet;						// reference to ruleset in operation
		public var interactive:Boolean=true;			// does object respond to clicks?

		protected const FILLSPRITE:uint=0;
		protected const CASINGSPRITE:uint=1;
		protected const STROKESPRITE:uint=2;
		protected const NAMESPRITE:uint=3;
		protected const WAYCLICKSPRITE:uint=4;
		protected const NODECLICKSPRITE:uint=5;

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};

		public function EntityUI(entity:Entity, paint:MapPaint) {
			this.entity=entity;
			this.paint=paint;
            entity.addEventListener(Connection.TAG_CHANGED, tagChanged);
			entity.addEventListener(Connection.ADDED_TO_RELATION, relationAdded);
			entity.addEventListener(Connection.REMOVED_FROM_RELATION, relationRemoved);
			entity.addEventListener(Connection.SUSPEND_REDRAW, suspendRedraw);
			entity.addEventListener(Connection.RESUME_REDRAW, resumeRedraw);
			listenSprite.addEventListener(MouseEvent.CLICK, mouseEvent);
			listenSprite.addEventListener(MouseEvent.DOUBLE_CLICK, mouseEvent);
			listenSprite.addEventListener(MouseEvent.ROLL_OVER, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_OUT, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_UP, mouseEvent);
			listenSprite.addEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
		}


		// -----------------------------------------------------------------
		// Event listeners
		
		protected function attachRelationListeners():void {
		    var relations:Array = entity.parentRelations;
            for each(var relation:Relation in relations ) {
                relation.addEventListener(Connection.TAG_CHANGED, relationTagChanged);
            }
		}

		protected function relationAdded(event:RelationMemberEvent):void {
		    event.relation.addEventListener(Connection.TAG_CHANGED, relationTagChanged);
		    redraw();
		}
		
		protected function relationRemoved(event:RelationMemberEvent):void {
		    event.relation.removeEventListener(Connection.TAG_CHANGED, relationTagChanged);
		    redraw();
		}
		
        protected function tagChanged(event:TagEvent):void {
            redraw();
        }

        protected function relationTagChanged(event:TagEvent):void {
            redraw();
        }
		
        protected function mouseEvent(event:MouseEvent):void {
			paint.map.entityMouseEvent(event, entity);
        }


		// -----------------------------------------------------------------

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

		protected function setListenSprite(spriteContainer:uint, hitzone:Sprite):void {
			if (hitzone) {
				if (!listenSprite.parent) { addToLayer(listenSprite, spriteContainer); }
	            listenSprite.hitArea = hitzone;
	            listenSprite.buttonMode = true;
	            listenSprite.mouseChildren = true;
	            listenSprite.mouseEnabled = true;
			} else {
				if (listenSprite.parent) { listenSprite.parent.removeChild(listenSprite); }
			}
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
		
		public function toString():String {
			return "[EntityUI "+entity+"]";
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
