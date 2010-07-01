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
		private var iconname:String='';				// name of icon
		private var heading:Number=0;				// heading within way
		private var rotation:Number=0;				// rotation applied to this POI
		private static const NO_LAYER:int=-99999;

		public function NodeUI(node:Node, paint:MapPaint, heading:Number=0, layer:int=NO_LAYER, sl:StyleList=null) {
			super(node,paint);
			if (layer==NO_LAYER) { this.layer=paint.maxlayer; } else { this.layer=layer; }
			this.heading = heading;
            entity.addEventListener(Connection.TAG_CHANGED, tagChanged);
			entity.addEventListener(Connection.NODE_MOVED, nodeMoved);
			entity.addEventListener(Connection.NODE_DELETED, nodeDeleted);
            attachRelationListeners();
			redraw(sl);
		}
		
		public function nodeMoved(event:Event):void {
		    updatePosition();
		}

		public function nodeDeleted(event:Event):void {
			removeSprites();
		}
		
		override public function doRedraw(sl:StyleList):Boolean {
			if (!paint.ready) { return false; }
			if (entity.deleted) { return false; }

			var tags:Object = entity.getTagsCopy();
			tags=applyStateClasses(tags);
			if (!entity.hasParentWays) { tags[':poi']='yes'; }
			if (!sl) { sl=paint.ruleset.getStyles(entity,tags,paint.map.scale); }

			var inWay:Boolean=entity.hasParentWays;
			var hasStyles:Boolean=sl.hasStyles();
			
			removeSprites(); iconname='';
			return renderFromStyle(sl,tags);
		}

		private function renderFromStyle(sl:StyleList,tags:Object):Boolean {
			var r:Boolean=false;			// ** rendered
			var maxwidth:Number=4;			// biggest width
			var w:Number;
			var icon:Sprite;
			interactive=false;
			for each (var sublayer:Number in sl.sublayers) {

				if (sl.pointStyles[sublayer]) {
					var s:PointStyle=sl.pointStyles[sublayer];
					interactive||=s.interactive;
					r=true;
					if (s.rotation) { rotation=s.rotation; }

					if (s.icon_image!=iconname) {
						if (s.icon_image=='square') {
							// draw square
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sl,sublayer);
							icon.graphics.drawRect(0,0,w,w);
							if (s.interactive) { maxwidth=Math.max(w,maxwidth); }
							iconname='_square';

						} else if (s.icon_image=='circle') {
							// draw circle
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sl,sublayer);
							icon.graphics.drawCircle(w,w,w);
							if (s.interactive) { maxwidth=Math.max(w,maxwidth); }
							iconname='_circle';

						} else if (paint.ruleset.images[s.icon_image]) {
							// 'load' icon (actually just from library)
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void { 
								loadedIcon(e,sublayer); } );
							loader.loadBytes(paint.ruleset.images[s.icon_image]);
							iconname=s.icon_image;
						}
					}
				}

				// name sprite
				var a:String='', t:TextStyle;
				if (sl.textStyles[sublayer]) {
					t=sl.textStyles[sublayer];
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


		private function styleIcon(icon:Sprite, sl:StyleList, sublayer:uint):Number {
			loaded=true;

			// get colours
			if (sl.shapeStyles[sublayer]) {
				var s:ShapeStyle=sl.shapeStyles[sublayer];
				if (s.color) { icon.graphics.beginFill(s.color); 
					}
				if (s.casing_width || !isNaN(s.casing_color)) {
					icon.graphics.lineStyle(s.casing_width ? s.casing_width : 1,
											s.casing_color ? s.casing_color : 0,
											s.casing_opacity ? s.casing_opacity : 1);
				}
			}

			// return width
			return sl.pointStyles[sublayer].icon_width;
		}

		private function addHitSprite(w:uint):void {
            var hitzone:Sprite = new Sprite();
            hitzone.graphics.lineStyle(4, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
			hitzone.graphics.beginFill(0);
			hitzone.graphics.drawRect(0,0,w,w);
            addToLayer(hitzone, NODECLICKSPRITE);
            hitzone.visible = false;
			setListenSprite(NODECLICKSPRITE, hitzone);
		}

		private function loadedIcon(event:Event,sublayer:uint):void {
			var icon:Sprite=new Sprite();
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
