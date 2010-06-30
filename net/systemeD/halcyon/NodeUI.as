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

		public function NodeUI(node:Node, paint:MapPaint, heading:Number=0, interactive:Boolean=true, sl:StyleList=null) {
			super(node,paint,interactive);
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
			var r:Boolean=false;	// ** rendered
			var w:Number;
			var icon:Sprite;
			layer=paint.maxlayer;
			for each (var sublayer:Number in sl.sublayers) {

				if (sl.pointStyles[sublayer]) {
					var s:PointStyle=sl.pointStyles[sublayer];
					r=true;
					if (s.rotation) { rotation=s.rotation; }

					if (s.icon_image!=iconname) {
						if (s.icon_image=='square') {
							// draw square
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sl,sublayer);
							icon.graphics.drawRect(0,0,w,w);
							addHitSprite(w);
							updatePosition();
							iconname='_square';

						} else if (s.icon_image=='circle') {
							// draw circle
							icon=new Sprite();
							addToLayer(icon,STROKESPRITE,sublayer);
							w=styleIcon(icon,sl,sublayer);
							icon.graphics.drawCircle(w,w,w);
							addHitSprite(w);
							updatePosition();
							iconname='_circle';

						} else if (paint.ruleset.images[s.icon_image]) {
							// 'load' icon (actually just from library)
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void { 
								loadedIcon(e,sublayer); } );
							loader.loadBytes(paint.ruleset.images[s.icon_image]);
							iconname=s.icon_image;
						}
					} else {
						// already loaded, so just reposition
						updatePosition();
					}
				}

				// name sprite
				var a:String='', t:TextStyle;
				if (sl.textStyles[sublayer]) {
					t=sl.textStyles[sublayer];
					a=tags[t.text];
				}

				if (a) { 
					var name:Sprite=new Sprite();
					addToLayer(name,NAMESPRITE);
					t.writeNameLabel(name,a,0,0);
				}
			}
			return r;
		}


		private function styleIcon(icon:Sprite, sl:StyleList, sublayer:uint):Number {
			loaded=true;

			// get colours
			if (sl.shapeStyles[sublayer]) {
				var s:ShapeStyle=sl.shapeStyles[sublayer];
				if (s.color) { icon.graphics.beginFill(s.color); }
				if (s.casing_width || !isNaN(s.casing_color)) {
					icon.graphics.lineStyle(s.casing_width ? s.casing_width : 1,
											s.casing_color ? s.casing_color : 0,
											s.casing_opacity ? s.casing_opacity : 1);
				}
			}

			// return width
			return sl.pointStyles[sublayer].icon_width ? sl.pointStyles[sublayer].icon_width : 4;
		}

		private function addHitSprite(w:uint):void {
            var hitzone:Sprite = new Sprite();
            hitzone.graphics.lineStyle(4, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
			hitzone.graphics.beginFill(0);
			hitzone.graphics.drawRect(0,0,w,w);
            addToLayer(hitzone, CLICKSPRITE);
            hitzone.visible = false;
			setListenSprite(hitzone);
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
