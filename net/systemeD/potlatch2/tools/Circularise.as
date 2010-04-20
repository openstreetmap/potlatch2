package net.systemeD.potlatch2.tools {
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.CompositeUndoableAction;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.MainUndoStack;

	public class Circularise {

		public static function circularise(way:Way,map:Map):void {
			if (way.length<4) { return; }

			var a:Node=way.getNode(0);
			var b:Node=way.getNode(way.length-1);
			if (a!=b) { return; }

			// Find centre-point
			// ** should be refactored to be within Way.as, so we can share with WayUI.as
			var patharea:Number=0;
			var cx:Number=0; var lx:Number=b.lon;
			var cy:Number=0; var ly:Number=b.latp;
			var i:uint,j:uint,n:Node;
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

			// Average distance to centre
			var d:Number=0; var angles:Array=[];
			for (i=0; i<way.length; i++) {
				d+=Math.sqrt(Math.pow(way.getNode(i).lon -cx,2)+
							 Math.pow(way.getNode(i).latp-cy,2));
			}
			d=d/way.length;
			

			var action:CompositeUndoableAction = new CompositeUndoableAction("Straighten");

			// Move each node
			for (i=0; i<way.length-1; i++) {
				n=way.getNode(i);
				var c:Number=Math.sqrt(Math.pow(n.lon-cx,2)+Math.pow(n.latp-cy,2));
				n.setLonLatp(cx+(n.lon -cx)/c*d,
				             cy+(n.latp-cy)/c*d, action.push);
			}

			// Insert extra nodes to make circle
			// clockwise: angles decrease, wrapping round from -170 to 170
			i=0;
			var clockwise:Boolean=way.clockwise;
			var diff:Number, ang:Number;
			while (i<way.length-1) {
				j=(i+1) % way.length;
				var a1:Number=Math.atan2(way.getNode(i).lon-cx,way.getNode(i).latp-cy)*(180/Math.PI);
				var a2:Number=Math.atan2(way.getNode(j).lon-cx,way.getNode(j).latp-cy)*(180/Math.PI);

				if (clockwise) {
					if (a2>a1) { a2=a2-360; }
					diff=a1-a2;
					if (diff>20) {
						for (ang=a1-20; ang>a2+10; ang-=20) {
							way.insertNode(j,map.connection.createNode({},
								map.latp2lat(cy+Math.cos(ang*Math.PI/180)*d),
								cx+Math.sin(ang*Math.PI/180)*d));
							j++; i++;
						}
					}
				} else {
					if (a1>a2) { a1=a1-360; }
					diff=a2-a1;
					if (diff>20) {
						for (ang=a1+20; ang<a2-10; ang+=20) {
							way.insertNode(j,map.connection.createNode({},
								map.latp2lat(cy+Math.cos(ang*Math.PI/180)*d),
								cx+Math.sin(ang*Math.PI/180)*d));
							j++; i++;
						}
					}
				}
				i++;
			}
		}
	}
}
