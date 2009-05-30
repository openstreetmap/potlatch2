package net.systemeD.halcyon {

	import flash.net.*;
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import net.systemeD.halcyon.styleparser.*;

	public class Way extends Object {

		public var id:int;
		public var path:Array;
		public var pathlength:Number;				// length of path

		public var tags:Object;
		public var clean:Boolean=true;				// altered since last upload?
		public var uploading:Boolean=false;			// currently uploading?
		public var locked:Boolean=false;			// locked against upload?
		public var version:uint=0;					// version number?
		public var layer:int=0;						// map layer
		public var map:Map;							// reference to parent map
		public var stroke:Sprite;					// instance in display list
		public var fill:Sprite;						//  |
		public var roadname:Sprite;					//  |

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};
		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
		public static var DejaVu:Class;
		public var nameformat:TextFormat;

//		public var depth:int=-1;					// child id ('depth') of sprite: -1=undrawn
//		public var historic:Boolean=false;			// is this an undeleted, not-uploaded way?
//		public var checkconnections:Boolean=false;	// check shared nodes on reload
//		public var mergedways:Array;

		public function Way(id:int,version:int,map:Map) {
			this.id=id;
			this.version=version;
			this.map=map;
		}

		// ------------------------------------------------------------------------------------------
		// Load from server

		public function load(connection:AMFConnection):void {
			connection.getWay(id,new Responder(gotWay,null));
			// ** should be connectionError, not null
		}
		
		public function gotWay(r:Object):void {
			var lx:Number,ly:Number;
			var code:uint     =r.shift(); if (code) { map.connectionError(); return; }
			var message:String=r.shift();
			clean=true;
			locked=false;
			tags=r[2];
			version=r[3];
//			this.historic=false;
//			removeNodeIndex();
//			resetBbox();
			path=[];
			pathlength=0;
			
			for each (var p:Array in r[1]) {
//				updateBbox(p[0],p[1]);
				if (!isNaN(lx)) { pathlength+=Math.sqrt( Math.pow(p[0]-lx,2)+Math.pow(p[1]-ly,2) ) };
				lx=p[0]; ly=p[1];
				var n:uint=p[2];
				// ** what to do if node exists?
				map.nodes[n]=new Node(n, p[0], map.lat2latp(p[1]), p[3], p[4]);
				map.nodes[n].clean=true;
				path.push(map.nodes[n]);
//				map.nodes[id].addWay(this.id);
			}
			pathlength*=map.scalefactor;
			redraw();
			// ** various other stuff
		}

		// ------------------------------------------------------------------------------------------
		// Redraw

		public function redraw():void {

			// ** remove previous version from any layer
			layer=5;
			if (tags['layer']) { layer=Math.min(Math.max(tags['layer']+5,-5),5)+5; }

			// find/create sprites
			if (stroke) {
				fill.graphics.clear(); 
				stroke.graphics.clear(); 
				roadname.graphics.clear();
				while (roadname.numChildren) { roadname.removeChildAt(0); }
			} else {
				fill=new Sprite(); addToLayer(fill,0);
				stroke=new Sprite(); addToLayer(stroke,1); 
				roadname=new Sprite(); addToLayer(roadname,2); 
			}
			var g:Graphics=stroke.graphics;
			var f:Graphics=fill.graphics;

			// set style
			var styles:Array=map.ruleset.getStyle(false,tags,map.scale);

			// ShapeStyle
			// ** do line-caps/joints
			var doStroke:Boolean=false, doDashed:Boolean=false;
			var doFill:Boolean=false, fill_colour:uint, fill_opacity:Number;
			var doCasing:Boolean=false, doDashedCasing:Boolean=false;
			if (styles[0]) {
				var ss:ShapeStyle=styles[0];
				if (ss.isStroked) {	doStroke=true;
									doDashed=(ss.stroke_dashArray.length>0);
									g.lineStyle(ss.stroke_width, ss.stroke_colour, ss.stroke_opacity/100,
												false,"normal", ss.stroke_linecap,ss.stroke_linejoin); }
				if (ss.isCased)   { doCasing=true;
									doDashedCasing=(ss.casing_dashArray.length>0);
									f.lineStyle(ss.casing_width, ss.casing_colour, ss.casing_opacity/100,
												false,"normal", ss.stroke_linecap, ss.stroke_linejoin); }
				if (ss.isFilled)  { doFill=true;
									fill_colour = ss.fill_colour;
									fill_opacity= ss.fill_opacity/100; }
			}

			// draw line
			if (doFill            ) { f.beginFill(fill_colour,fill_opacity); }
			if (doStroke          ) { g.moveTo(map.lon2coord(path[0].lon),map.latp2coord(path[0].latp)); }
			if (doFill || doCasing) { f.moveTo(map.lon2coord(path[0].lon),map.latp2coord(path[0].latp)); }

			if (doDashed) { dashedLine(g,ss.stroke_dashArray); }
			else if (doStroke) { solidLine(g); }
			
			if (doDashedCasing) { dashedLine(f,ss.casing_dashArray); f.lineStyle(); }
			if (doFill) {
 				f.beginFill(fill_colour,fill_opacity); 
				solidLine(f);
				f.endFill(); 
			} else if (doCasing && !doDashedCasing) { solidLine(f); }

			// TextStyle
			// ** do pull-out
			if (styles[2] && styles[2].tag && tags[styles[2].tag]) {
				var ts:TextStyle=styles[2];
				nameformat = new TextFormat(ts.font_name   ? ts.font_name : "DejaVu",
											ts.text_size   ? ts.text_size : 8,
											ts.text_colour ? ts.text_colour: 0,
											ts.font_bold   ? ts.font_bold : false,
											ts.font_italic ? ts.font_italic: false);
				var a:String=tags[ts.tag]; if (ts.font_caps) { a=a.toUpperCase(); }
				writeName(roadname,a,ts.text_offset ? ts.text_offset : 0);
			}
			// ShieldStyle - 3
			// ** to do
		}
		
		// ------------------------------------------------------------------------------------------
		// Drawing support functions

		// Draw solid polyline
		
		private function solidLine(g:Graphics):void {
 			g.moveTo(map.lon2coord(path[0].lon),map.latp2coord(path[0].latp));
			for (var i:uint=1; i<path.length; i++) {
				g.lineTo(map.lon2coord(path[i].lon),map.latp2coord(path[i].latp));
			}
		}

		// Draw dashed polyline
		
		private function dashedLine(g:Graphics,dashes:Array):void {
			var draw:Boolean=false, dashleft:Number=0, dc:Array=new Array();
			var a:Number, xc:Number, yc:Number;
			var curx:Number, cury:Number;
			var dx:Number, dy:Number, segleft:Number=0;
 			var i:int=0;
 			g.moveTo(map.lon2coord(path[0].lon),map.latp2coord(path[0].latp));
			while (i<path.length-1 || segleft>0) {
				if (dashleft<=0) {	// should be ==0
					if (dc.length==0) { dc=dashes.slice(0); }
					dashleft=dc.shift();
					draw=!draw;
				}
				if (segleft<=0) {	// should be ==0
					curx=map.lon2coord(path[i].lon ); dx=map.lon2coord(path[i+1].lon )-curx;
					cury=map.latp2coord(path[i].latp); dy=map.latp2coord(path[i+1].latp)-cury;
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
			for (var i:int=1; i<path.length; i++){
				dx=map.lon2coord(path[i].lon )-map.lon2coord(path[i-1].lon );
				dy=map.latp2coord(path[i].latp)-map.latp2coord(path[i-1].latp);
				seglen=Math.sqrt(dx*dx+dy*dy);
				if (totallen > curlen+seglen) { curlen+=seglen; continue; }
				return new Array(map.lon2coord(path[i-1].lon )+(totallen-curlen)/seglen*dx,
								 map.latp2coord(path[i-1].latp)+(totallen-curlen)/seglen*dy,
								 Math.atan2(dy,dx));
			}
			return new Array(0, 0, 0);
		}

		// Draw name along path
		// based on code by Tom Carden
		// ** needs styling
		
		private function writeName(s:Sprite,a:String,textOffset:Number=0):void {

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
			tf.embedFonts = true;
			tf.defaultTextFormat = nameformat;
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
		
		// Add object (stroke/fill/roadname) to layer sprite
		
		private function addToLayer(s:Sprite,sublayer:uint):void {
			var l:DisplayObject=Map(map).getChildAt(layer);
			var o:DisplayObject=Sprite(l).getChildAt(sublayer);
			Sprite(o).addChild(s);
		}
	}
}
