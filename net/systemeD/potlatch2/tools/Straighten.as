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
		 * */
		public static function straighten(way:Way,map:Map,performAction:Function):void {
			if (way.length<3) { return; }

			var a:Node=way.getNode(0);
			var b:Node=way.getNode(way.length-1);
			if (way.isArea()) { return; }
			
			// ** could potentially do the 'too bendy?' check here as per Potlatch 1
			
			var action:CompositeUndoableAction = new CompositeUndoableAction("Straighten");
			
			var todelete:Array=[];
			var n:Node;
		
			for (var i:uint=1; i<way.length-1; i++) {
				n=way.getNode(i);
				if (n.parentWays.length>1 || n.hasTags() ||
				    n.lon<map.edge_l || n.lon>map.edge_r ||
				    n.lat<map.edge_b || n.lat>map.edge_t) {

					// junction node, tagged, or off-screen - so retain and move
					var u:Number=((n.lon -a.lon )*(b.lon -a.lon )+
					              (n.latp-a.latp)*(b.latp-a.latp))/
					             (Math.pow(b.lon-a.lon,2)+Math.pow(b.latp-a.latp,2));
					n.setLonLatp(a.lon +u*(b.lon -a.lon ),
					             a.latp+u*(b.latp-a.latp), action.push);
					
				} else {
					// safe to delete
					if (todelete.indexOf(n)==-1) { todelete.push(n); }
				}
			}
			for each (n in todelete) { n.remove(action.push); }
			
			performAction(action);
		}
	}
}
