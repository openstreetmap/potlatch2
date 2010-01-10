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

        private var way:Way;
		public var pathlength:Number;				// length of path
		public var patharea:Number;					// area of path
		public var centroid_x:Number;				// centroid
		public var centroid_y:Number;				//  |
		public var heading:Array=new Array();		// angle at each node
        private var hitzone:Sprite;
		public var nameformat:TextFormat;

		private const NODESIZE:uint=6;

		public function WayUI(way:Way, map:Map) {
			super();
			this.way = way;
			this.map = map;
            init();
            way.addEventListener(Connection.TAG_CHANGE, wayTagChanged);
            way.addEventListener(Connection.WAY_NODE_ADDED, wayNodeAdded);
            way.addEventListener(Connection.WAY_NODE_REMOVED, wayNodeRemoved);
			way.addEventListener(Connection.WAY_DELETED, wayDeleted);
            attachNodeListeners();
		}
		
		private function attachNodeListeners():void {
            for (var i:uint = 0; i < way.length; i++ ) {
                way.getNode(i).addEventListener(Connection.NODE_MOVED, nodeMoved);
            }
		}
		
		private function wayNodeAdded(event:WayNodeEvent):void {
		    event.node.addEventListener(Connection.NODE_MOVED, nodeMoved);
		    redraw();
		}
		    
		private function wayNodeRemoved(event:WayNodeEvent):void {
		    event.node.removeEventListener(Connection.NODE_MOVED, nodeMoved);
		    redraw();
		}
		    
        private function wayTagChanged(event:TagEvent):void {
            redraw();
        }
        private function nodeMoved(event:NodeMovedEvent):void {
            redraw();
        }
		private function wayDeleted(event:EntityEvent):void {
			Globals.vars.root.addDebug("waydeleted fired on "+way.length+":"+event.entity);
			redraw();
		}

		private function init():void {
			recalculate();
			redraw();
			// updateBbox(lon, lat);
			// ** various other stuff
		}

		// ------------------------------------------------------------------------------------------
		// Calculate length etc.
		// ** this could be made scale-independent - would speed up redraw
		
		public function recalculate():void {
			var lx:Number, ly:Number, sc:Number;
			var node:Node, latp:Number, lon:Number;
			var cx:Number=0, cy:Number=0;
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
				sc = (lx*latp-lon*ly)*map.scalefactor;
				cx += (lx+lon)*sc;
				cy += (ly+latp)*sc;
				patharea += sc;
				
				// heading
				if (i>0) { heading[i-1]=Math.atan2((lon-lx),(latp-ly)); }

				lx=lon; ly=latp;
			}
			heading[way.length-1]=heading[way.length-2];

			pathlength*=map.scalefactor;
			patharea/=2;
			if (patharea!=0 && way.isArea()) {
				centroid_x=map.lon2coord(cx/patharea/6);
				centroid_y=map.latp2coord(cy/patharea/6);
			} else if (pathlength>0) {
				var c:Array=pointAt(0.5);
				centroid_x=c[0];
				centroid_y=c[1];
			}
		}

		// ------------------------------------------------------------------------------------------
		// Redraw

		override public function redraw(sl:StyleList=null):Boolean {
			removeSprites();
			if (way.length==0) { return false; }

            // Copy tags object, and add states
            var tags:Object = way.getTagsCopy();
			tags=applyStateClasses(tags);
			if (way.isArea()) { tags[':area']='yes'; }

			// Which layer?
			layer=5;
			if ( tags['layer'] )
                layer=Math.min(Math.max(tags['layer']+5,-5),5)+5;

			// Iterate through each sublayer, drawing any styles on that layer
			if (!sl) { sl=map.ruleset.getStyles(this.way, tags); }
			var drawn:Boolean;
			for (var sublayer:int=10; sublayer>=0; sublayer--) {
				if (sl.shapeStyles[sublayer]) {
					var s:ShapeStyle=sl.shapeStyles[sublayer];
					var stroke:Shape, fill:Shape, casing:Shape, roadname:Sprite;
					var x0:Number=map.lon2coord(way.getNode(0).lon);
					var y0:Number=map.latp2coord(way.getNode(0).latp);

					// Stroke
					if (s.width)  {
						stroke=new Shape(); addToLayer(stroke,STROKESPRITE,sublayer);
						stroke.graphics.moveTo(x0,y0);
						s.applyStrokeStyle(stroke.graphics);
						if (s.dashes && s.dashes.length>0) { dashedLine(stroke.graphics,s.dashes); }
													  else { solidLine(stroke.graphics); }
						drawn=true;
					}

					// Fill
					if (s.fill_color || s.fill_image) {
						fill=new Shape(); addToLayer(fill,FILLSPRITE);
						fill.graphics.moveTo(x0,y0);
						if (s.fill_image) { new WayBitmapFiller(this,fill.graphics,s); }
									 else { s.applyFill(fill.graphics); }
						solidLine(fill.graphics);
						fill.graphics.endFill();
						drawn=true;
					}

					// Casing
					if (s.casing_width) { 
						casing=new Shape(); addToLayer(casing,CASINGSPRITE);
						casing.graphics.moveTo(x0,y0);
						s.applyCasingStyle(casing.graphics);
						if (s.casing_dashes && s.casing_dashes.length>0) { dashedLine(casing.graphics,s.casing_dashes); }
																	else { solidLine(casing.graphics); }
						drawn=true;
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
			for (var i:uint = 0; i < way.length; i++) {
                var node:Node = way.getNode(i);
				nodetags=node.getTagsCopy();
				if (i==0) { nodetags['_heading']= heading[i]; }
				     else { nodetags['_heading']=(heading[i]+heading[i-1])/2; }
				if (stateClasses["showNodes"]) { nodetags[':selectedway']='yes'; }
				if (stateClasses["showNodesHover"]) { nodetags[':hoverway']='yes'; }
				if (node.id==nodeSelected) { nodetags[':selected']='yes'; }
				sl=map.ruleset.getStyles(node,nodetags);
				if (sl.hasStyles()) {
					if (!map.pois[node.id]) { map.pois[node.id]=new NodeUI(node,map,r); }
					map.pois[node.id].redraw(sl);
					// ** this should be done via the registerPOI/event listener mechanism,
					//    but that needs a bit of reworking so we can pass in a styleList
					//    (otherwise we end up computing the styles twice which is expensive)
				} else if (map.pois[node.id]) {
					map.pois[node.id].removeSprites();
				}
			}
			if (!drawn) { return false; }
			
            // create a generic "way" hitzone sprite
            hitzone = new Sprite();
            hitzone.graphics.lineStyle(4, 0x000000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);
            solidLine(hitzone.graphics);
            addToLayer(hitzone, CLICKSPRITE);
            hitzone.visible = false;
			createListenSprite(hitzone);

			return true;
		}
		
		// ------------------------------------------------------------------------------------------
		// Drawing support functions

		// Draw solid polyline
		
		public function solidLine(g:Graphics):void {
            var node:Node = way.getNode(0);
 			g.moveTo(map.lon2coord(node.lon), map.latp2coord(node.latp));
			for (var i:uint = 1; i < way.length; i++) {
                node = way.getNode(i);
				g.lineTo(map.lon2coord(node.lon), map.latp2coord(node.latp));
			}
		}

		// Draw dashed polyline
		
		private function dashedLine(g:Graphics,dashes:Array):void {
			var draw:Boolean=false, dashleft:Number=0, dc:Array=new Array();
			var a:Number, xc:Number, yc:Number;
			var curx:Number, cury:Number;
			var dx:Number, dy:Number, segleft:Number=0;
 			var i:int=0;

            var node:Node = way.getNode(0);
            var nextNode:Node = way.getNode(0);
 			g.moveTo(map.lon2coord(node.lon), map.latp2coord(node.latp));
			while (i < way.length-1 || segleft>0) {
				if (dashleft<=0) {	// should be ==0
					if (dc.length==0) { dc=dashes.slice(0); }
					dashleft=dc.shift();
					draw=!draw;
				}
				if (segleft<=0) {	// should be ==0
                    node = way.getNode(i);
                    nextNode = way.getNode(i+1);
					curx=map.lon2coord(node.lon);
                    dx=map.lon2coord(nextNode.lon)-curx;
					cury=map.latp2coord(node.latp);
                    dy=map.latp2coord(nextNode.latp)-cury;
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
		}

		private function moveLine(g:Graphics,x:Number,y:Number,draw:Boolean):void {
			if (draw) { g.lineTo(x,y); }
				 else { g.moveTo(x,y); }
		}

		
		// Find point partway (0-1) along a path
		// returns (x,y,angle)
		// inspired by senocular's Path.as
		
		private function pointAt(t:Number):Array {
			var totallen:Number = t*pathlength;
			var curlen:Number = 0;
			var dx:Number, dy:Number, seglen:Number;
			for (var i:int = 1; i < way.length; i++){
				dx=map.lon2coord(way.getNode(i).lon)-map.lon2coord(way.getNode(i-1).lon);
				dy=map.latp2coord(way.getNode(i).latp)-map.latp2coord(way.getNode(i-1).latp);
				seglen=Math.sqrt(dx*dx+dy*dy);
				if (totallen > curlen+seglen) { curlen+=seglen; continue; }
				return new Array(map.lon2coord(way.getNode(i-1).lon)+(totallen-curlen)/seglen*dx,
								 map.latp2coord(way.getNode(i-1).latp)+(totallen-curlen)/seglen*dy,
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
			for (var i:uint = 0; i < way.length; i++) {
                var node:Node = way.getNode(i);
                var nodeX:Number = map.lon2coord(node.lon);
                var nodeY:Number = map.latp2coord(node.latp);
                if ( nodeX >= x-NODESIZE && nodeX <= x+NODESIZE &&
                     nodeY >= y-NODESIZE && nodeY <= y+NODESIZE )
                    return node;
            }
            return null;
		}

        override protected function mouseEvent(event:MouseEvent):void {
			map.entityMouseEvent(event, way);
        }

	}
}
