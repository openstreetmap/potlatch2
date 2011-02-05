package net.systemeD.halcyon {

	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.*;
	import net.systemeD.halcyon.styleparser.*;
    import net.systemeD.halcyon.connection.*;

	/** The elastic is a visual indication of a way that the user is currently in the process of drawing. */
	public class Elastic {

		public var map:Map;							// reference to parent map
		public var sprites:Array=new Array();		// instances in display list
        private var _start:Point;
        private var _end:Point;

		/** Create and draw the elastic. */
		public function Elastic(map:Map, start:Point, end:Point) {
			this.map = map;
			this._start = start;
			this._end = end;
			redraw();
		}
		
		public function set start(start:Point):void {
		    this._start = start;
		    redraw();
		}

		public function set end(end:Point):void {
		    this._end = end;
		    redraw();
		}
		
		public function get start():Point {
		    return _start;
		}
		
		public function get end():Point {
		    return _end;
		}
		
		/** Remove all currently existing sprites */
		public function removeSprites():void {
			
			while (sprites.length>0) {
				var d:DisplayObject=sprites.pop(); d.parent.removeChild(d);
			}
        }
        
		/** Draws the elastic - a dashed line on the highest paint layer. */
		public function redraw():void {
		    removeSprites();

			// Create stroke object
			var stroke:Shape = new Shape();
            stroke.graphics.lineStyle(1, 0xff0000, 1, false, "normal", CapsStyle.ROUND, JointStyle.ROUND);

			var l:DisplayObject=map.paint.getPaintSpriteAt(map.paint.maxlayer);
			var o:DisplayObject=Sprite(l).getChildAt(3);	// names layer
			(o as Sprite).addChild(stroke);
			sprites.push(stroke);

			dashedLine(stroke.graphics, [2,2]);


		}
		
		// ------------------------------------------------------------------------------------------
		// Drawing support functions

		// Draw dashed polyline
		
		private function dashedLine(g:Graphics,dashes:Array):void {
			var draw:Boolean=false, dashleft:Number=0, dc:Array=new Array();
			var a:Number, xc:Number, yc:Number;
			var curx:Number, cury:Number;
			var dx:Number, dy:Number, segleft:Number=0;
 			var i:int=0;

            var p0:Point = start;
            var p1:Point = end;
 			g.moveTo(map.lon2coord(p0.x), map.latp2coord(p0.y));
			while (i < 1 || segleft>0) {
				if (dashleft<=0) {	// should be ==0
					if (dc.length==0) { dc=dashes.slice(0); }
					dashleft=dc.shift();
					draw=!draw;
				}
				if (segleft<=0) {	// should be ==0
					curx=map.lon2coord(p0.x);
                    dx=map.lon2coord(p1.x)-curx;
					cury=map.latp2coord(p0.y);
                    dy=map.latp2coord(p1.y)-cury;
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

	}
}
