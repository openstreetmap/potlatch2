package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.styleparser.StyleList;
	import net.systemeD.halcyon.styleparser.RuleSet;
    import net.systemeD.halcyon.connection.*;

	/** Parent class of representations of map Entities, with properties about how they should be drawn. */ 
	public class EntityUI {

		/** The entity represented by this class. */
		protected var entity:Entity;
		/** Current StyleList for this entity. */
		protected var styleList:StyleList;
		/** Instances in display list */
		protected var sprites:Array=new Array();
		/** The clickable sprite that will receive events. */
		protected var listenSprite:Sprite=new Sprite();
		/** Hitzone for the sprite - must be set by subclass-specific code. */
		protected var hitzone:Sprite;
		/** Special context-sensitive classes such as :hover. */
		protected var stateClasses:Object=new Object();
		/** Map layer */
		protected var layer:Number=0;
		/** Is drawing suspended? */
		protected var suspended:Boolean=false;	
		/** Redraw called while suspended? */
		protected var redrawDue:Boolean=false;
		/** Sprite to clear back to */
		protected var clearLimit:uint=0;
		/** Reference to parent MapPaint */
		public var paint:MapPaint;	
		/** Reference to ruleset (MapCSS) in operation */
		public var ruleset:RuleSet;
		/** Does object respond to clicks? */
		public var interactive:Boolean=true;
		/** Can it be deleted when offscreen? */
		public var purgable:Boolean=true;

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

		/** Constructor function, adds a bunch of event listeners. */
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

		/** Remove the default event listeners. */
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

		/** Add object (stroke/fill/roadname) to layer sprite*/
		
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

		// What does this do, could someone please document?
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

		/** Remove all sprites associated with this entity, and clear hitzone. */
		public function removeSprites():void {
			while (sprites.length>clearLimit) {
				var d:DisplayObject=sprites.pop();
				if (d.parent) { d.parent.removeChild(d); }
			}
			if (clearLimit==0) {
				listenSprite.hitArea=null;
				hitzone=null;
			}
		}
		
		public function protectSprites():void { clearLimit=sprites.length; }
		public function unprotectSprites():void { clearLimit=0; }

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

        /**
        * Sets a state class (eg :hover, :dupe) for this entityUI. If the state class has changed it will
        * invalidate the style list to force the style to be recalculated during redraw.
        */
        public function setStateClass(stateType:String, isOn:*):Boolean {
			if ( isOn == true ) { isOn='yes'; }
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

        /**
        * applies the state classes (eg :hover, :area) for this entityUI to the given list of 'real' tags.
        * This then gives you a modified list of tags used for styling the entityUI.
        */
		public function applyStateClasses(tags:Object):Object {
            for (var stateKey:String in stateClasses) {
                tags[":"+stateKey] = 'yes';
            }
			return tags;
		}
		
		public function toString():String {
			return "[EntityUI "+entity+"]";
		}

		/** Request redraw */
		
		public function redraw():Boolean {
			if (suspended) { redrawDue=true; return false; }
			return doRedraw();
		}
		
		/** Actually do the redraw. To be overwritten. */
		public function doRedraw():Boolean {
			return false;
		}
		
		/** Temporarily suspend redrawing of object. */
		public function suspendRedraw(event:EntityEvent):void {
			suspended=true;
			redrawDue=false;
		}
		
		/** Resume redrawing. */
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
