package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import net.systemeD.halcyon.styleparser.*;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;
	
	public class NodeUI extends EntityUI {
		
		public var loaded:Boolean=false;
		private var iconnames:Object={};			// name of icon on each sublayer
		private var heading:Number=0;				// heading within way
		private var rotation:Number=0;				// rotation applied to this POI
		private static const NO_LAYER:int=-99999;

		public function NodeUI(node:Node, paint:MapPaint, heading:Number=0, layer:int=NO_LAYER, stateClasses:Object=null) {
			super(node,paint);
			if (layer==NO_LAYER) { this.layer=paint.maxlayer; } else { this.layer=layer; }
			this.heading = heading;
			if (stateClasses) {
				for (var state:String in stateClasses) {
					if (stateClasses[state]) { this.stateClasses[state]=stateClasses[state]; }
				}
			}
			entity.addEventListener(Connection.NODE_MOVED, nodeMoved);
            attachRelationListeners();
			redraw();
		}
		
		public function removeEventListeners():void {
			removeGenericEventListeners();
			entity.removeEventListener(Connection.NODE_MOVED, nodeMoved);
		}

		public function nodeMoved(event:Event):void {
		    updatePosition();
		}

		override public function doRedraw():Boolean {
			if (!paint.ready) { return false; }
			if (entity.deleted) { return false; }

			var tags:Object = entity.getTagsCopy();
			tags=applyStateClasses(tags);
			if (!entity.hasParentWays) { tags[':poi']='yes'; }
            if (entity.hasInterestingTags()) { tags[':hasTags']='yes'; }
			if (!styleList || !styleList.isValidAt(paint.map.scale)) {
				styleList=paint.ruleset.getStyles(entity,tags,paint.map.scale); 
			}

			var inWay:Boolean=entity.hasParentWays;
			var hasStyles:Boolean=styleList.hasStyles();
			
			removeSprites(); iconnames={};
			return renderFromStyle(tags);
		}

		private function renderFromStyle(tags:Object):Boolean {
			var r:Boolean=false;			// ** rendered
			var maxwidth:Number=4;			// biggest width
			var w:Number;
			var icon:Sprite;
			interactive=false;
			for each (var sublayer:Number in styleList.sublayers) {

				if (styleList.pointStyles[sublayer]) {
					var s:PointStyle=styleList.pointStyles[sublayer];
					interactive||=s.interactive;
					r=true;
					if (s.rotation) { rotation=s.rotation; }
					if (s.icon_image!=iconnames[sublayer]) {
						if (s.icon_image=='square') {
							// draw square
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sublayer);
							icon.graphics.drawRect(0,0,w,w);
							if (s.interactive) { maxwidth=Math.max(w,maxwidth); }
							iconnames[sublayer]='_square';

						} else if (s.icon_image=='circle') {
							// draw circle
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sublayer);
							icon.graphics.drawCircle(w,w,w);
							if (s.interactive) { maxwidth=Math.max(w,maxwidth); }
							iconnames[sublayer]='_circle';

						} else if (paint.ruleset.images[s.icon_image]) {
							// 'load' icon (actually just from library)
							var loader:ExtendedLoader = new ExtendedLoader();
							loader.info['sublayer']=sublayer;
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedIcon);
							loader.loadBytes(paint.ruleset.images[s.icon_image]);
							iconnames[sublayer]=s.icon_image;
						}
					}
				}

				// name sprite
				var a:String='', t:TextStyle;
				if (styleList.textStyles[sublayer]) {
					t=styleList.textStyles[sublayer];
					interactive||=t.interactive;
					a=tags[t.text];
				}

				if (a) { 
					var name:Sprite=new Sprite();
					addToLayer(name,NAMESPRITE);
					t.writeNameLabel(name,a,0,0);
				}
			}
			if (!r) { return false; }
			if (interactive) { addHitSprite(maxwidth); }
			updatePosition();
			return true;
		}


		private function styleIcon(icon:Sprite, sublayer:Number):Number {
			loaded=true;

			// get colours
			if (styleList.shapeStyles[sublayer]) {
				var s:ShapeStyle=styleList.shapeStyles[sublayer];
				if (!isNaN(s.color)) { icon.graphics.beginFill(s.color);
					}
				if (s.casing_width || !isNaN(s.casing_color)) {
					icon.graphics.lineStyle(s.casing_width ? s.casing_width : 1,
											s.casing_color ? s.casing_color : 0,
											s.casing_opacity ? s.casing_opacity : 1);
				}
			}

			// return width
			return styleList.pointStyles[sublayer].icon_width;
		}

		private function addHitSprite(w:uint):void {
            hitzone = new Sprite();
            hitzone.graphics.lineStyle(4, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
			hitzone.graphics.beginFill(0);
			hitzone.graphics.drawRect(0,0,w,w);
			hitzone.visible = false;
			setListenSprite();
		}

		private function loadedIcon(event:Event):void {
			var icon:Sprite=new Sprite();
			var sublayer:Number=event.target.loader.info['sublayer'];
			addToLayer(icon,STROKESPRITE,sublayer);
			icon.addChild(Bitmap(event.target.content));
			addHitSprite(icon.width);
			loaded=true;
			updatePosition();
		}

		private function updatePosition():void {
			if (!loaded) { return; }

			for (var i:uint=0; i<sprites.length; i++) {
				var d:DisplayObject=sprites[i];
				d.x=0; d.y=0; d.rotation=0;

				var m:Matrix=new Matrix();
				m.translate(-d.width/2,-d.height/2);
				m.rotate(rotation);
				m.translate(paint.map.lon2coord(Node(entity).lon),paint.map.latp2coord(Node(entity).latp));
				d.transform.matrix=m;
			}
		}
	}
}
