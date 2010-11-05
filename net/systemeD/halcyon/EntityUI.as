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
		protected var styleList:StyleList;				// current StyleList for this entity
		protected var sprites:Array=new Array();		// instances in display list
		protected var listenSprite:Sprite=new Sprite();	// clickable sprite to receive events
		protected var hitzone:Sprite;					// hitzone for above
		protected var stateClasses:Object=new Object();	// special context-sensitive classes, e.g. :hover
		protected var layer:int=0;						// map layer
		protected var suspended:Boolean=false;			// suspend redrawing?
		protected var redrawDue:Boolean=false;			// redraw called while suspended?
		public var paint:MapPaint;						// reference to parent MapPaint
		public var ruleset:RuleSet;						// reference to ruleset in operation
		public var interactive:Boolean=true;			// does object respond to clicks?
		public var purgable:Boolean=true;				// can it be deleted when offscreen?

		protected const FILLSPRITE:uint=0;
		protected const CASINGSPRITE:uint=1;
		protected const STROKESPRITE:uint=2;
		protected const NAMESPRITE:uint=3;
		protected const WAYCLICKSPRITE:uint=0;
		protected const NODECLICKSPRITE:uint=1;

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

		protected function removeGenericEventListeners():void {
            entity.removeEventListener(Connection.TAG_CHANGED, tagChanged);
			entity.removeEventListener(Connection.ADDED_TO_RELATION, relationAdded);
			entity.removeEventListener(Connection.REMOVED_FROM_RELATION, relationRemoved);
			entity.removeEventListener(Connection.SUSPEND_REDRAW, suspendRedraw);
			entity.removeEventListener(Connection.RESUME_REDRAW, resumeRedraw);
			listenSprite.removeEventListener(MouseEvent.CLICK, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.DOUBLE_CLICK, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.ROLL_OVER, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.MOUSE_OUT, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.MOUSE_UP, mouseEvent);
			listenSprite.removeEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
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
			invalidateStyleList();
		    redraw();
		}
		
		protected function relationRemoved(event:RelationMemberEvent):void {
		    event.relation.removeEventListener(Connection.TAG_CHANGED, relationTagChanged);
			invalidateStyleList();
		    redraw();
		}
		
        protected function tagChanged(event:TagEvent):void {
			invalidateStyleList();
            redraw();
        }

        protected function relationTagChanged(event:TagEvent):void {
			invalidateStyleList();
            redraw();
        }
		
        protected function mouseEvent(event:MouseEvent):void {
			paint.map.entityMouseEvent(event, entity);
        }


		// -----------------------------------------------------------------

		// Add object (stroke/fill/roadname) to layer sprite
		
		protected function addToLayer(s:DisplayObject,t:uint,sublayer:int=-1):void {
			var l:Sprite, o:Sprite;
			if (sublayer!=-1) {
				o=paint.sublayer(layer,sublayer);
			} else {
				l=paint.getPaintSpriteAt(layer);
				o=l.getChildAt(t) as Sprite;
			}
			o.addChild(s);
			if (sprites.indexOf(s)==-1) { sprites.push(s); }
            if ( s is Sprite ) {
                Sprite(s).mouseChildren = false;
                Sprite(s).mouseEnabled = false;
            }
		}

		protected function setListenSprite():void {
			var l:Sprite=paint.getHitSpriteAt(layer);
			var s:Sprite;
			if (entity is Way) { s=l.getChildAt(0) as Sprite; }
			              else { s=l.getChildAt(1) as Sprite; }
			
			if (hitzone) {
				if (!listenSprite.parent) { s.addChild(listenSprite); if (sprites.indexOf(listenSprite)==-1) { sprites.push(listenSprite); } }
				if (!hitzone.parent)      { s.addChild(hitzone     ); if (sprites.indexOf(hitzone     )==-1) { sprites.push(hitzone     ); } }
				listenSprite.hitArea = hitzone;
				listenSprite.buttonMode = true;
				listenSprite.mouseChildren = true;
				listenSprite.mouseEnabled = true;
			} else if (listenSprite.parent) { 
				listenSprite.parent.removeChild(listenSprite);
			}
		}

		public function removeSprites():void {
			while (sprites.length>0) {
				var d:DisplayObject=sprites.pop();
				if (d.parent) { d.parent.removeChild(d); }
			}
			listenSprite.hitArea=null;
			hitzone=null;
		}

		protected function offsetSprites(x:Number, y:Number):void {
			for each (var d:DisplayObject in sprites) {
				d.x=x; d.y=y;
			}
		}

        public function setHighlight(settings:Object):void {
			var changed:Boolean=false;
			for (var stateType:String in settings) {
				if (setStateClass(stateType, settings[stateType])) { changed=true; }
			}
			if (changed) redraw();
        }

        public function setStateClass(stateType:String, isOn:*):Boolean {
            if ( isOn && stateClasses[stateType] != isOn ) {
                stateClasses[stateType] = isOn;
				invalidateStyleList();
				return true;
            } else if ( !isOn && stateClasses[stateType] != null ) {
                delete stateClasses[stateType];
				invalidateStyleList();
				return true;
            }
			return false;
        }

		public function applyStateClasses(tags:Object):Object {
            for (var stateKey:String in stateClasses) {
                tags[":"+stateKey] = 'yes';
            }
			return tags;
		}
		
		public function toString():String {
			return "[EntityUI "+entity+"]";
		}

		// Redraw control
		
		public function redraw():Boolean {
			if (suspended) { redrawDue=true; return false; }
			return doRedraw();
		}
		
		public function doRedraw():Boolean {
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
				doRedraw();
				redrawDue=false;
			}
		}
		
		public function invalidateStyleList():void {
			styleList=null;
		}

	}

}
