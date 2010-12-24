package net.systemeD.potlatch2.tools {
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.CompositeUndoableAction;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.MainUndoStack;

	/** Tool to transform a closed way of at least 3 distinct points into a circular shape, inserting more nodes as necessary. Call only the static function circularise(). */
	public class Circularise {

		/** Carries out the circularisation of a way.
		 * @param way The way to be made round: must be closed, must have at least 3 distinct points.
		 * @param map The map that the way belongs to.
		 * @param performAction A function that will be passed a CompositeUndoableAction representing the transformation. In other words, a function that will push the result onto an undo stack.
		 * */ 
		public static function circularise(way:Way,map:Map,performAction:Function):void {
			if (way.length<4) { return; }

			var a:Node=way.getNode(0);
			var b:Node=way.getNode(way.length-1);
			if (a!=b) { return; }

            new Circularise(way, map, performAction).run();
        }
        
        private var way:Way;
        private var map:Map;
		private var performAction:Function;
        
        // centre
        private var cx:Number=0;
        private var cy:Number=0;
        
        // distance to centre
		private var d:Number=0;
        
        // our undoable
        private var action:CompositeUndoableAction = new CompositeUndoableAction("Circularise");

        // recording the node lats lons so we're not relying on instant update
        private var lats:Array = [];
		private var lons:Array = [];

        function Circularise(way:Way, map:Map, performAction:Function) {
            this.way = way;
            this.map = map;
			this.performAction = performAction;
        }
        
        private function run():void {
            calculateCentre();
            calculateCentreDistance();

            var i:uint;
            var j:uint;
            var n:Node;
            
			// Move each node
			for (i=0; i<way.length-1; i++) {
				n=way.getNode(i);
				var c:Number=Math.sqrt(Math.pow(n.lon-cx,2)+Math.pow(n.latp-cy,2));
				var lat:Number = cy+(n.latp-cy)/c*d;
				var lon:Number = cx+(n.lon -cx)/c*d;
				n.setLonLatp(lon, lat, action.push);
				
				// record the lat lons we're using as the node won't update
				// till later
				lats.push(lat);
				lons.push(lon);
			}

			// Insert extra nodes to make circle
			// clockwise: angles decrease, wrapping round from -170 to 170
			i=0;
			var clockwise:Boolean=way.clockwise;
			var diff:Number, ang:Number;
			while (i<lons.length) {
				j=(i+1) % lons.length;
				var a1:Number=Math.atan2(lons[i]-cx, lats[i]-cy)*(180/Math.PI);
				var a2:Number=Math.atan2(lons[j]-cx, lats[j]-cy)*(180/Math.PI);

				if (clockwise) {
					if (a2>a1) { a2=a2-360; }
					diff=a1-a2;
					if (diff>20) {
						for (ang=a1-20; ang>a2+10; ang-=20) {
						    insertNode(ang, i+1);
							j++; i++;
						}
					}
				} else {
					if (a1>a2) { a1=a1-360; }
					diff=a2-a1;
					if (diff>20) {
						for (ang=a1+20; ang<a2-10; ang+=20) {
						    insertNode(ang, i+1);
							j++; i++;
						}
					}
				}
				i++;
			}

			performAction(action);
		}

        private function calculateCentre():void {
			// Find centre-point
			// ** should be refactored to be within Way.as, so we can share with WayUI.as
			var b:Node=way.getNode(way.length-1);
			var patharea:Number=0;
			var lx:Number=b.lon;
			var ly:Number=b.latp;
			var i:uint, n:Node;
			for (i=0; i<way.length; i++) {
				n=way.getNode(i);
				var sc:Number = (lx*n.latp-n.lon*ly);
				cx += (lx+n.lon )*sc;
				cy += (ly+n.latp)*sc;
				patharea += sc;
				lx=n.lon; ly=n.latp;
			}
			patharea/=2;
			cx/=patharea*6;
			cy/=patharea*6;
        }

        private function calculateCentreDistance():void {
			// Average distance to centre
			// (first + last are the same node, don't use twice)
			for (var i:uint = 0; i < way.length - 1; i++) {
				d+=Math.sqrt(Math.pow(way.getNode(i).lon -cx,2)+
							 Math.pow(way.getNode(i).latp-cy,2));
			}
			d /= way.length - 1;
	    }

		private function insertNode(ang:Number, index:int):void {
			var lat:Number = cy+Math.cos(ang*Math.PI/180)*d;
			var lon:Number = cx+Math.sin(ang*Math.PI/180)*d;
			lats.splice(index, 0, lat);
			lons.splice(index, 0, lon);
			var newNode:Node = map.connection.createNode({}, map.latp2lat(lat), lon, action.push);
			way.insertNode(index, newNode, action.push);
		}
	}
}
