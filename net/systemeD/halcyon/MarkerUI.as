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
    import net.systemeD.halcyon.ImageBank;

    public class MarkerUI extends EntityUI {

        public var loaded:Boolean=false;
        private var iconnames:Object={};            // name of icon on each subpart
        private var heading:Number=0;               // heading within way
        private var rotation:Number=0;              // rotation applied to this POI
        private static const NO_LAYER:int=-99999;

        public function MarkerUI(marker:Marker, paint:MapPaint, heading:Number=0, layer:int=NO_LAYER, stateClasses:Object=null) {
            super(marker,paint);
            if (layer==NO_LAYER) { this.layer=paint.maxlayer; } else { this.layer=layer; }
            this.heading = heading;
            if (stateClasses) {
                for (var state:String in stateClasses) {
                    if (stateClasses[state]) { this.stateClasses[state]=stateClasses[state]; }
                }
            }
            entity.addEventListener(Connection.NODE_MOVED, markerMoved, false, 0, true);
            entity.addEventListener(Connection.NODE_ALTERED, markerAltered, false, 0, true);
            attachRelationListeners();
            redraw();
        }

        public function removeEventListeners():void {
            removeGenericEventListeners();
            entity.removeEventListener(Connection.NODE_MOVED, markerMoved);
            entity.removeEventListener(Connection.NODE_ALTERED, markerAltered);
        }

        public function markerMoved(event:Event):void {
            updatePosition();
        }

        private function markerAltered(event:Event):void {
            redraw();
        }

        override public function doRedraw():Boolean {
            if (!paint.ready) { return false; }
            if (entity.deleted) { return false; }

            var tags:Object = entity.getTagsCopy();
            setStateClass('poi', !entity.hasParentWays);
            setStateClass('hasTags', entity.hasInterestingTags());
            tags=applyStateClasses(tags);
            if (!styleList || !styleList.isValidAt(paint.map.scale)) {
                styleList=paint.ruleset.getStyles(entity,tags,paint.map.scale);
            }

            var suggestedLayer:Number=styleList.layerOverride();
            if (!isNaN(suggestedLayer)) { layer=suggestedLayer; }

            var inWay:Boolean=entity.hasParentWays;
            var hasStyles:Boolean=styleList.hasStyles();

            removeSprites(); iconnames={};
            return renderFromStyle(tags);
        }

        private function renderFromStyle(tags:Object):Boolean {
            var r:Boolean=false;            // ** rendered
            var maxwidth:Number=4;          // biggest width
            var w:Number;
            var icon:Sprite;
            interactive=false;
            for each (var subpart:String in styleList.subparts) {

                if (styleList.pointStyles[subpart]) {
                    var s:PointStyle=styleList.pointStyles[subpart];
                    interactive||=s.interactive;
                    r=true;
                    if (s.rotation) { rotation=s.rotation; }
                    if (s.icon_image!=iconnames[subpart]) {
						icon=new Sprite();
						iconnames[subpart]=s.icon_image;
						addToLayer(icon,STROKESPRITE,s.sublayer);
                        if (s.icon_image=='square') {
                            // draw square
                            w=styleIcon(icon,subpart);
                            icon.graphics.drawRect(0,0,w,w);
                            if (s.interactive) { maxwidth=Math.max(w,maxwidth); }

                        } else if (s.icon_image=='circle') {
                            // draw circle
                            w=styleIcon(icon,subpart);
                            icon.graphics.drawCircle(w,w,w);
                            if (s.interactive) { maxwidth=Math.max(w,maxwidth); }

						} else if (ImageBank.getInstance().hasImage(s.icon_image)) {
							// load icon from library
							icon.addChild(ImageBank.getInstance().getAsDisplayObject(s.icon_image));
//							addHitSprite(icon.width);			// ** check this - we're doing it below too
//							loaded=true; updatePosition();		// ** check this
							if (s.interactive) { maxwidth=Math.max(icon.width,maxwidth); }
						}
                    }
                }

                // name sprite
                var a:String='', t:TextStyle;
                if (styleList.textStyles[subpart]) {
                    t=styleList.textStyles[subpart];
                    interactive||=t.interactive;
                    a=tags[t.text];
                }

                if (a) {
                    var name:Sprite=new Sprite();
                    addToLayer(name,NAMESPRITE);
                    t.writeNameLabel(name,a,0,0);
                    loaded=true;
                }
            }
            if (!r) { return false; }
            if (interactive) { addHitSprite(maxwidth); }
            updatePosition();
            return true;
        }


        private function styleIcon(icon:Sprite, subpart:String):Number {
            loaded=true;

            // get colours
            if (styleList.shapeStyles[subpart]) {
                var s:ShapeStyle=styleList.shapeStyles[subpart];
                if (!isNaN(s.color)) { icon.graphics.beginFill(s.color);
                    }
                if (s.casing_width || !isNaN(s.casing_color)) {
                    icon.graphics.lineStyle(s.casing_width ? s.casing_width : 1,
                                            s.casing_color ? s.casing_color : 0,
                                            s.casing_opacity ? s.casing_opacity : 1);
                }
            }

            // return width
            return styleList.pointStyles[subpart].icon_width;
        }

        private function addHitSprite(w:uint):void {
            hitzone = new Sprite();
            hitzone.graphics.lineStyle(4, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
            hitzone.graphics.beginFill(0);
            hitzone.graphics.drawRect(0,0,w,w);
            hitzone.visible = false;
            setListenSprite();
        }

        private function updatePosition():void {
            if (!loaded) { return; }

            for (var i:uint=0; i<sprites.length; i++) {
                var d:DisplayObject=sprites[i];
                d.x=0; d.y=0; d.rotation=0;

                var m:Matrix=new Matrix();
                m.translate(-d.width/2,-d.height/2);
                m.rotate(rotation);
                m.translate(paint.map.lon2coord(Marker(entity).lon),paint.map.latp2coord(Marker(entity).latp));
                d.transform.matrix=m;
            }
        }
    }
}
