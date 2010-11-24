package net.systemeD.potlatch2.tools {
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.CompositeUndoableAction;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.MainUndoStack;

	public class Simplify {

		private static const TOLERANCE:Number=0.00005;

		public static function simplify(way:Way, map:Map, keepOffscreen:Boolean):void {
			if (way.length<3 || way.isArea()) { return; }

			var action:CompositeUndoableAction = new CompositeUndoableAction("Simplify");
			
			var xa:Number, xb:Number;
			var ya:Number, yb:Number;
			var l:Number, d:Number, i:uint;
			var furthest:uint, furthdist:Number, float:Number;
			var n:Node;
			
			var tokeep:Object={};
			var stack:Array=[way.length-1];
			var anchor:uint=0;
			var todelete:Array=[];
		
			// Douglas-Peucker
			while (stack.length) {
				float=stack[stack.length-1];
				furthest=0; furthdist=0;
				xa=way.getNode(anchor).lon ; xb=way.getNode(float).lon ;
				ya=way.getNode(anchor).latp; yb=way.getNode(float).latp;
				l=Math.sqrt((xb-xa)*(xb-xa)+(yb-ya)*(yb-ya));
	
				// find furthest-out point
				for (i=anchor+1; i<float; i+=1) {
					d=getDistance(xa,ya,xb,yb,l,way.getNode(i).lon,way.getNode(i).latp);
					if (d>furthdist && d>TOLERANCE) { furthest=i; furthdist=d; }
				}
			
				if (furthest==0) {
					anchor=stack.pop();
					tokeep[way.getNode(float).id]=true;
				} else {
					stack.push(furthest);
				}
			}
			
			// Delete unwanted nodes, unless they're tagged or junction nodes
			for (i=1; i<way.length; i++) {
				n=way.getNode(i)
				if (tokeep[n.id] || n.hasTags() || n.parentWays.length>1 ||
				    (keepOffscreen && (n.lon<map.edge_l || n.lon>map.edge_r || n.lat<map.edge_b || n.lat>map.edge_t )) ) {
					// keep it
				} else {
					// delete it
					todelete.push(n);
				}
			}
			for each (n in todelete) { n.remove(action.push); }
			MainUndoStack.getGlobalStack().addAction(action);
		}
		
		private static function getDistance(ax:Number,ay:Number,bx:Number,by:Number,l:Number,cx:Number,cy:Number):Number {
			// l=length of line
			// r=proportion along AB line (0-1) of nearest point
			var r:Number;
                        if (l > 0) {
                                r=((cx-ax)*(bx-ax)+(cy-ay)*(by-ay))/(l*l);
                        } else {
                                r=0;
                        }
			// now find the length from cx,cy to ax+r*(bx-ax),ay+r*(by-ay)
			var px:Number=(ax+r*(bx-ax)-cx);
			var py:Number=(ay+r*(by-ay)-cy);
			return Math.sqrt(px*px+py*py);
		}

	}
}
