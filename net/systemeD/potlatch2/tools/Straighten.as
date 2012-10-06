package net.systemeD.potlatch2.tools {
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.CompositeUndoableAction;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.MainUndoStack;

	/** Tool to transform a non-closed way into a straight line, by deleting any non-junction, untagged, on-screen nodes, and 
	 * moving the others to fit. Call only the static function <code>straighten()</code>*/
	public class Straighten {

		/** Carries out the straightening.
		 * @param way Way to be straightened.
		 * @param map Map that it belongs to.
		 * @performAction Function that will be passed a CompositeUndoableAction parameter representing the transformation.
		 * @return True if ok (or closed/short way), false if the way was too bendy to straighten.
		 * */
		public static function straighten(way:Way,map:Map,performAction:Function):Boolean {
			if (way.length<3) { return true; }

			var a:Node=way.getNode(0);
			var b:Node=way.getNode(way.length-1);
			if (way.isArea()) { return true; }
			
			// Check way isn't too bendy
			var latfactor:Number=Math.cos(map.centre_lat/(180/Math.PI));
			var n:Node;
			for (var i:uint=1; i<way.length-1; i++) {
				n=way.getNode(i);
				var u:Number=Straighten.positionAlongWay(n,a,b);
				var x1:Number=a.lon +u*(b.lon -a.lon );
				var y1:Number=a.latp+u*(b.latp-a.latp);
				var t:Number=Math.sqrt(Math.pow(x1-n.lon,2) + Math.pow(y1-n.latp,2));
				t=111200*latfactor*t;
				if (t>50) { return false; }
			}

			// Not too bendy, so straighten
			
			var action:CompositeUndoableAction = new CompositeUndoableAction("Straighten");
			
			var todelete:Array=[];
		
			for (i=1; i<way.length-1; i++) {
				n=way.getNode(i);
				if (n.parentWays.length>1 || n.hasTags() ||
				    n.lon<map.edge_l || n.lon>map.edge_r ||
				    n.lat<map.edge_b || n.lat>map.edge_t) {

					// junction node, tagged, or off-screen - so retain and move
					u=Straighten.positionAlongWay(n,a,b);
					n.setLonLatp(a.lon +u*(b.lon -a.lon ),
					             a.latp+u*(b.latp-a.latp), action.push);
					
				} else {
					// safe to delete
					if (todelete.indexOf(n)==-1) { todelete.push(n); }
				}
			}
			for each (n in todelete) { n.remove(action.push); }
			
			performAction(action);
			return true;
		}

		private static function positionAlongWay(n:Node, a:Node, b:Node):Number {
			return ((n.lon -a.lon )*(b.lon -a.lon )+
				    (n.latp-a.latp)*(b.latp-a.latp))/
				    (Math.pow(b.lon-a.lon,2)+Math.pow(b.latp-a.latp,2));
		}
	}
}
