package net.systemeD.halcyon {

	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.*;
	import net.systemeD.halcyon.styleparser.*;
    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.Globals;

	public class WayUI extends EntityUI {

		public var pathlength:Number;				// length of path
		public var patharea:Number;					// area of path
		public var centroid_x:Number;				// centroid
		public var centroid_y:Number;				//  |
		public var heading:Array=new Array();		// angle at each node
        private var hitzone:Sprite;
		public var nameformat:TextFormat;
		private var recalculateDue:Boolean=false;

		private const NODESIZE:uint=6;

		public function WayUI(way:Way, paint:MapPaint, interactive:Boolean=true) {
			super(way,paint,interactive);
            entity.addEventListener(Connection.WAY_NODE_ADDED, wayNodeAdded);
            entity.addEventListener(Connection.WAY_NODE_REMOVED, wayNodeRemoved);
            entity.addEventListener(Connection.WAY_REORDERED, wayReordered);
			entity.addEventListener(Connection.WAY_DELETED, wayDeleted);
            entity.addEventListener(Connection.WAY_DRAGGED, wayDragged);
            attachNodeListeners();
            attachRelationListeners();
            recalculate();
			redraw();
		}
		
		private function attachNodeListeners():void {
			var way:Way=entity as Way;
            for (var i:uint = 0; i < way.length; i++ ) {
                way.getNode(i).addEventListener(Connection.NODE_MOVED, nodeMoved);
            }
		}
		
		private function wayNodeAdded(event:WayNodeEvent):void {
		    event.node.addEventListener(Connection.NODE_MOVED, nodeMoved);
		    redraw();
			redrawMultis();
		}
		    
		private function wayNodeRemoved(event:WayNodeEvent):void {
		    event.node.removeEventListener(Connection.NODE_MOVED, nodeMoved);
			if (paint.nodeuis[event.node.id]) {
				paint.nodeuis[event.node.id].redraw();
			}
		    redraw();
			redrawMultis();
		}
		    
        private function nodeMoved(event:NodeMovedEvent):void {
			recalculate();
            redraw();
			redrawMultis();
        }
		private function wayDeleted(event:EntityEvent):void {
			redraw();
			redrawMultis();
		}
        private function wayReordered(event:EntityEvent):void {
            redraw();
			redrawMultis();
        }
		private function wayDragged(event:WayDraggedEvent):void {
			offsetSprites(event.xDelta,event.yDelta);
		}

		override protected function relationAdded(event:RelationMemberEvent):void {
			super.relationAdded(event);
			redrawMultis();
		}
		override protected function relationRemoved(event:RelationMemberEvent):void {
			super.relationRemoved(event);
			redrawMultis();
		}
		override protected function relationTagChanged(event:TagEvent):void {
			super.relationTagChanged(event);
			redrawMultis();
		}

		override public function suspendRedraw(event:EntityEvent):void {
			super.suspendRedraw(event);
			recalculateDue=false;
		}
		
		override public function resumeRedraw(event:EntityEvent):void {
			suspended=false;
			if (recalculateDue) { recalculate(); }
			super.resumeRedraw(event);
		}

		private function redrawMultis():void {
			var multis:Array=entity.findParentRelationsOfType('multipolygon','inner');
			for each (var m:Relation in multis) {
				var outers:Array=m.findMembersByRole('outer');
				for each (var e:Entity in outers) { 
					if (e is Way && paint.wayuis[e.id]) {
						paint.wayuis[e.id].redraw();
					}
				}
			}
		}

		// ------------------------------------------------------------------------------------------
		// Calculate length etc.
		// ** this could be made scale-independent - would speed up redraw
		
		public function recalculate():void {
			if (suspended) { recalculateDue=true; return; }
			
			var lx:Number, ly:Number, sc:Number;
			var node:Node, latp:Number, lon:Number;
			var cx:Number=0, cy:Number=0;
			var way:Way=entity as Way;
			
			pathlength=0;
			patharea=0;
			if (way.length==0) { return; }
			
			lx = way.getNode(way.length-1).lon;
			ly = way.getNode(way.length-1).latp;
			for ( var i:uint = 0; i < way.length; i++ ) {
                node = way.getNode(i);
                latp = node.latp;
                lon  = node.lon;

				// length and area
				if ( i>0 ) { pathlength += Math.sqrt( Math.pow(lon-lx,2)+Math.pow(latp-ly,2) ); }
				sc = (lx*latp-lon*ly)*paint.map.scalefactor;
				cx += (lx+lon)*sc;
				cy += (ly+latp)*sc;
				patharea += sc;
				
				// heading
				if (i>0) { heading[i-1]=Math.atan2((lon-lx),(latp-ly)); }

				lx=lon; ly=latp;
			}
			heading[way.length-1]=heading[way.length-2];

			pathlength*=paint.map.scalefactor;
			patharea/=2;
			if (patharea!=0 && way.isArea()) {
				centroid_x=paint.map.lon2coord(cx/patharea/6);
				centroid_y=paint.map.latp2coord(cy/patharea/6);
			} else if (pathlength>0) {
				var c:Array=pointAt(0.5);
				centroid_x=c[0];
				centroid_y=c[1];
			}
		}

		// ------------------------------------------------------------------------------------------
		// Redraw

		override public function doRedraw(sl:StyleList):Boolean {
			removeSprites();
			if (Way(entity).length==0) { return false; }
			if (!paint.ready) { return false; }

            // Copy tags object, and add states
            var tags:Object = entity.getTagsCopy();
			tags=applyStateClasses(tags);
			if (Way(entity).isArea()) { tags[':area']='yes'; }

			// Which layer?
			layer=0;
			if (tags['layer']) { layer=Math.min(Math.max(tags['layer'],paint.minlayer),paint.maxlayer); }

			// Keep track of maximum stroke width for hitzone
			var maxwidth:Number=4;

			// Iterate through each sublayer, drawing any styles on that layer
			if (!sl) { sl=paint.ruleset.getStyles(entity, tags, paint.map.scale); }
			var drawn:Boolean;
			var multis:Array=entity.findParentRelationsOfType('multipolygon','outer');
			var inners:Array=[];
			for each (var m:Relation in multis) {
				inners=inners.concat(m.findMembersByRole('inner'));
			}
			for each (var sublayer:Number in sl.sublayers) {
				if (sl.shapeStyles[sublayer]) {
					var s:ShapeStyle=sl.shapeStyles[sublayer];
					var stroke:Shape, fill:Shape, casing:Shape, roadname:Sprite;
					var x0:Number=paint.map.lon2coord(Way(entity).getNode(0).lon);
					var y0:Number=paint.map.latp2coord(Way(entity).getNode(0).latp);

					// Stroke
					if (s.width)  {
						stroke=new Shape(); addToLayer(stroke,STROKESPRITE,sublayer);
						stroke.graphics.moveTo(x0,y0);
						s.applyStrokeStyle(stroke.graphics);
						if (s.dashes && s.dashes.length>0) {
							var segments:Array=dashedLine(stroke.graphics,s.dashes); 
							if (s.line_style) { lineDecoration(stroke.graphics,s,segments); }
						} else { solidLines(stroke.graphics,inners); }
						drawn=true;
						maxwidth=Math.max(maxwidth,s.width);
					}

					// Fill
					if ((s.fill_color || s.fill_image) && entity.findParentRelationsOfType('multipolygon','inner').length==0) {
						fill=new Shape(); addToLayer(fill,FILLSPRITE);
						fill.graphics.moveTo(x0,y0);
						if (s.fill_image) { new WayBitmapFiller(this,fill.graphics,s); }
									 else { s.applyFill(fill.graphics); }
						solidLines(fill.graphics,inners);
						fill.graphics.endFill();
						drawn=true;
					}

					// Casing
					if (s.casing_width) { 
						casing=new Shape(); addToLayer(casing,CASINGSPRITE);
						casing.graphics.moveTo(x0,y0);
						s.applyCasingStyle(casing.graphics);
						if (s.casing_dashes && s.casing_dashes.length>0) { dashedLine(casing.graphics,s.casing_dashes); }
																	else { solidLines(casing.graphics,inners); }
						drawn=true;
						maxwidth=Math.max(maxwidth,s.casing_width);
					}
				}
				
				if (sl.textStyles[sublayer]) {
					var t:TextStyle=sl.textStyles[sublayer];
					roadname=new Sprite(); addToLayer(roadname,NAMESPRITE);
					nameformat = t.getTextFormat();
					var a:String=tags[t.text];
					if (a) {
						if (t.font_caps) { a=a.toUpperCase(); }
						if (t.text_center && centroid_x) {
							t.writeNameLabel(roadname,a,centroid_x,centroid_y);
						} else {
							writeNameOnPath(roadname,a,t.text_offset ? t.text_offset : 0);
						}
						if (t.text_halo_radius>0) { roadname.filters=t.getHaloFilter(); }
					}
				}
				
				// ** ShieldStyle to do
			}

			// Draw icons
			// ** there should be huge potential to optimise this - at present we're
			//    running getStyles for every node in the way on every redraw
			// ** fix r/heading behaviour - that doesn't look right
			var r:Number;
			var nodetags:Object;
			var nodeSelected:int=stateClasses["nodeSelected"];
			for (var i:uint = 0; i < Way(entity).length; i++) {
                var node:Node = Way(entity).getNode(i);
				nodetags=node.getTagsCopy();
				if (i==0) { nodetags['_heading']= heading[i]; }
				     else { nodetags['_heading']=(heading[i]+heading[i-1])/2; }
				if (stateClasses["showNodes"]) { nodetags[':selectedway']='yes'; }
				if (stateClasses["showNodesHover"]) { nodetags[':hoverway']='yes'; }
				if (node.id==nodeSelected) { nodetags[':selected']='yes'; }
				if (node.numParentWays>1) { nodetags[':junction']='yes'; }
				sl=paint.ruleset.getStyles(node, nodetags, paint.map.scale);
				if (sl.hasStyles()) {
					if (paint.nodeuis[node.id]) {
						paint.nodeuis[node.id].redraw(sl);
					} else {
						paint.nodeuis[node.id]=new NodeUI(node,paint,r,true,sl);
					}
				} else if (paint.nodeuis[node.id]) {
					paint.nodeuis[node.id].removeSprites();
					delete paint.nodeuis[node.id];
				}
			}
			if (!drawn) { return false; }
			
            // create a generic "way" hitzone sprite
            hitzone = new Sprite();
            hitzone.graphics.lineStyle(maxwidth, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
            solidLines(hitzone.graphics,[]);
            addToLayer(hitzone, CLICKSPRITE);
            hitzone.visible = false;
			setListenSprite(hitzone);

			return true;
		}
		
		// ------------------------------------------------------------------------------------------
		// Drawing support functions

		// Draw solid polyline
		
		public function solidLines(g:Graphics,inners:Array):void {
			solidLine(g,entity as Way);
			for each (var w:Way in inners) { solidLine(g,w); }
		}

		private function solidLine(g:Graphics,w:Way):void {
			if (w.length==0) { return; }
            var node:Node = w.getNode(0);
 			g.moveTo(paint.map.lon2coord(node.lon), paint.map.latp2coord(node.latp));
			for (var i:uint = 1; i < w.length; i++) {
                node = w.getNode(i);
				g.lineTo(paint.map.lon2coord(node.lon), paint.map.latp2coord(node.latp));
			}
		}

		// Draw dashed polyline
		
		private function dashedLine(g:Graphics,dashes:Array):Array {
			var way:Way=entity as Way;
			var segments:Array=[];
			var draw:Boolean=false, dashleft:Number=0, dc:Array=new Array();
			var a:Number, xc:Number, yc:Number;
			var curx:Number, cury:Number;
			var dx:Number, dy:Number, segleft:Number=0;
 			var i:int=0;

            var node:Node = way.getNode(0);
            var nextNode:Node = way.getNode(0);
 			g.moveTo(paint.map.lon2coord(node.lon), paint.map.latp2coord(node.latp));
			while (i < way.length-1 || segleft>0) {
				if (dashleft<=0) {	// should be ==0
					if (dc.length==0) { dc=dashes.slice(0); }
					dashleft=dc.shift();
					if (draw) { segments.push([curx,cury,dx,dy]); }
					draw=!draw;
				}
				if (segleft<=0) {	// should be ==0
                    node = way.getNode(i);
                    nextNode = way.getNode(i+1);
					curx=paint.map.lon2coord(node.lon);
                    dx=paint.map.lon2coord(nextNode.lon)-curx;
					cury=paint.map.latp2coord(node.latp);
                    dy=paint.map.latp2coord(nextNode.latp)-cury;
					a=Math.atan2(dy,dx); xc=Math.cos(a); yc=Math.sin(a);
					segleft=Math.sqrt(dx*dx+dy*dy);
					i++;
				}

				if (segleft<=dashleft) {
					// the path segment is shorter than the dash
		 			curx+=dx; cury+=dy;
					moveLine(g,curx,cury,draw);
					dashleft-=segleft; segleft=0;
				} else {
					// the path segment is longer than the dash
					curx+=dashleft*xc; dx-=dashleft*xc;
					cury+=dashleft*yc; dy-=dashleft*yc;
					moveLine(g,curx,cury,draw);
					segleft-=dashleft; dashleft=0;
				}
			}
			return segments;
		}

		private function moveLine(g:Graphics,x:Number,y:Number,draw:Boolean):void {
			if (draw) { g.lineTo(x,y); }
				 else { g.moveTo(x,y); }
		}

		// Draw decoration (arrows etc.)
		
		private function lineDecoration(g:Graphics,s:ShapeStyle,segments:Array):void {
			var c:int=s.color ? s.color : 0;
			switch (s.line_style.toLowerCase()) {

				case 'arrows':
					var w:Number=s.width*1.5;	// width of arrow
					var l:Number=s.width*2;		// length of arrow
					var angle0:Number, angle1:Number, angle2:Number;
					g.lineStyle(1,c);
					for each (var seg:Array in segments) {
						g.beginFill(c);
						angle0= Math.atan2(seg[3],seg[2]);
						angle1=-Math.atan2(seg[3],seg[2]);
						angle2=-Math.atan2(seg[3],seg[2])-Math.PI;
						g.moveTo(seg[0]+l*Math.cos(angle0),
						         seg[1]+l*Math.sin(angle0));
						g.lineTo(seg[0]+w*Math.sin(angle1),
						         seg[1]+w*Math.cos(angle1));
						g.lineTo(seg[0]+w*Math.sin(angle2),
						         seg[1]+w*Math.cos(angle2));
						g.endFill();
					}
					break;
				}
		}

		
		// Find point partway (0-1) along a path
		// returns (x,y,angle)
		// inspired by senocular's Path.as
		
		private function pointAt(t:Number):Array {
			var way:Way=entity as Way;
			var totallen:Number = t*pathlength;
			var curlen:Number = 0;
			var dx:Number, dy:Number, seglen:Number;
			for (var i:int = 1; i < way.length; i++){
				dx=paint.map.lon2coord(way.getNode(i).lon)-paint.map.lon2coord(way.getNode(i-1).lon);
				dy=paint.map.latp2coord(way.getNode(i).latp)-paint.map.latp2coord(way.getNode(i-1).latp);
				seglen=Math.sqrt(dx*dx+dy*dy);
				if (totallen > curlen+seglen) { curlen+=seglen; continue; }
				return new Array(paint.map.lon2coord(way.getNode(i-1).lon)+(totallen-curlen)/seglen*dx,
								 paint.map.latp2coord(way.getNode(i-1).latp)+(totallen-curlen)/seglen*dy,
								 Math.atan2(dy,dx));
			}
			return new Array(0, 0, 0);
		}

		// Draw name along path
		// based on code by Tom Carden
		
		private function writeNameOnPath(s:Sprite,a:String,textOffset:Number=0):void {

			// make a dummy textfield so we can measure its width
			var tf:TextField = new TextField();
			tf.defaultTextFormat = nameformat;
			tf.text = a;
			tf.width = tf.textWidth+4;
			tf.height = tf.textHeight+4;
			if (pathlength<tf.width) { return; }	// no room for text?

			var t1:Number = (pathlength/2 - tf.width/2) / pathlength; var p1:Array=pointAt(t1);
			var t2:Number = (pathlength/2 + tf.width/2) / pathlength; var p2:Array=pointAt(t2);

			var angleOffset:Number; // so we can do a 180º if we're running backwards
			var offsetSign:Number;  // -1 if we're starting at t2
			var tStart:Number;      // t1 or t2

			// make sure text doesn't run right->left or upside down
			if (p1[0] < p2[0] && 
				p1[2] < Math.PI/2 &&
				p1[2] > -Math.PI/2) {
				angleOffset = 0; offsetSign = 1; tStart = t1;
			} else {
				angleOffset = Math.PI; offsetSign = -1; tStart = t2;
			} 

			// make a textfield for each char, centered on the line,
			// using getCharBoundaries to rotate it around its center point
			var chars:Array = a.split('');
			for (var i:int = 0; i < chars.length; i++) {
				var rect:Rectangle = tf.getCharBoundaries(i);
				if (rect) {
					s.addChild(rotatedLetter(chars[i],
						 					 tStart + offsetSign*(rect.left+rect.width/2)/pathlength,
											 rect.width, tf.height, angleOffset, textOffset));
				}
			}
		}

		private function rotatedLetter(char:String, t:Number, w:Number, h:Number, a:Number, o:Number):TextField {
			var tf:TextField = new TextField();
            tf.mouseEnabled = false;
            tf.mouseWheelEnabled = false;
			tf.defaultTextFormat = nameformat;
			tf.embedFonts = true;
			tf.text = char;
			tf.width = tf.textWidth+4;
			tf.height = tf.textHeight+4;

			var p:Array=pointAt(t);
			var matrix:Matrix = new Matrix();
			matrix.translate(-w/2, -h/2-o);
			// ** add (say) -4 to the height to move it up by 4px
			matrix.rotate(p[2]+a);
			matrix.translate(p[0], p[1]);
			tf.transform.matrix = matrix;
			return tf;
		}
		
		public function getNodeAt(x:Number, y:Number):Node {
			var way:Way=entity as Way;
			for (var i:uint = 0; i < way.length; i++) {
                var node:Node = way.getNode(i);
                var nodeX:Number = paint.map.lon2coord(node.lon);
                var nodeY:Number = paint.map.latp2coord(node.latp);
                if ( nodeX >= x-NODESIZE && nodeX <= x+NODESIZE &&
                     nodeY >= y-NODESIZE && nodeY <= y+NODESIZE )
                    return node;
            }
            return null;
		}

		// ------------------------------------------------------------------------------------------
		// Interaction

		public function hitTest(x:Number, y:Number):Way {
			if (hitzone.hitTestPoint(x,y,true)) { return entity as Way; }
			return null;
		}
	}
}
