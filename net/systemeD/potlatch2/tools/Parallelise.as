package net.systemeD.potlatch2.tools {

    import net.systemeD.halcyon.connection.*;

	  /** Tool to create a parallel copy of an existing way. First call the constructor Parallelise() passing it the 
	  * way that will be parallelised. This performs some initialisation. Then call draw(), passing it an offset,
	  * as many times as you like. Each time it recomputes the parallel way. There is no finalisation. 
	  * <p>This is intended to work with the SelectedParallelWay controller state.</p>*/
	public class Parallelise {
		private var originalWay:Way;
		public var parallelWay:Way;
		private var connection:Connection;
		private var offsetx:Array=[];
		private var offsety:Array=[];
		private var df:Array=[];
		private var nodes:Object={};
		
		/** Initialises parallelisation process, adding an entry to global undo stack.
		 * @param way The way to be duplicated. 
		 * */
		public function Parallelise(way:Way) {
			var a:Number, b:Number, h:Number, i:uint, j:uint, k:int;
			connection  = Connection.getConnection();
			originalWay = way;
			parallelWay = connection.createWay({}, [], MainUndoStack.getGlobalStack().addAction);

			for (i=0; i<originalWay.length; i++) {
				j=(i+1) % originalWay.length;
				a=originalWay.getNode(i).latp - originalWay.getNode(j).latp;
				b=originalWay.getNode(j).lon  - originalWay.getNode(i).lon;
				h=Math.sqrt(a*a+b*b);
				if (h!=0) { a=a/h; b=b/h; }
					 else {	a=0; b=0; }
				offsetx[i]=a;
				offsety[i]=b;
			}

			for (i=0; i<originalWay.length; i++) {
				j=(i+1) % originalWay.length;
				k=i-1; if (k==-1) { k=originalWay.length-2; }	// ** it's -2 because if this is an area, node[length-1] is the same as node[0]
				a=det(offsetx[i]-offsetx[k],
					  offsety[i]-offsety[k],
					  originalWay.getNode(j).lon  - originalWay.getNode(i).lon,
					  originalWay.getNode(j).latp - originalWay.getNode(i).latp);
				b=det(originalWay.getNode(i).lon  - originalWay.getNode(k).lon,
					  originalWay.getNode(i).latp - originalWay.getNode(k).latp,
					  originalWay.getNode(j).lon  - originalWay.getNode(i).lon,
					  originalWay.getNode(j).latp - originalWay.getNode(i).latp);
				if (b!=0) { df[i]=a/b; } else { df[i]=0; }
			}

		}

		/** Compute the shape of the parallel way, implicitly causing it to be drawn if onscreen. Closed ways are ok. 
		 * @param offset How far, in lon/latp units, should the parallel way be. Can be negative. */
		public function draw(offset:Number):void {
			var x:Number, y:Number;
			var undo:CompositeUndoableAction = new CompositeUndoableAction("Draw parallel way");
			parallelWay.suspend();
			for (var i:int=0; i<originalWay.length; i++) {
				if (i==0) {
					if (originalWay.isArea()) {
						x=originalWay.getNode(i).lon + offset * (offsetx[originalWay.length-2] + df[i] * (originalWay.getNode(i).lon - originalWay.getNode(originalWay.length-2).lon ));
						y=originalWay.getNode(i).latp+ offset * (offsety[originalWay.length-2] + df[i] * (originalWay.getNode(i).latp- originalWay.getNode(originalWay.length-2).latp));
					} else {
						x=originalWay.getNode(0).lon + offset * offsetx[0];
						y=originalWay.getNode(0).latp+ offset * offsety[0];
					}
				} else if (i==originalWay.length-1) {
					if (originalWay.isArea()) { continue; }		// node[length-1] is the same as node[0] if it's an area, so skip
					x=originalWay.getNode(i).lon + offset * offsetx[i-1];
					y=originalWay.getNode(i).latp+ offset * offsety[i-1];
				} else {
					x=originalWay.getNode(i).lon + offset * (offsetx[i-1] + df[i] * (originalWay.getNode(i).lon - originalWay.getNode(i-1).lon ));
					y=originalWay.getNode(i).latp+ offset * (offsety[i-1] + df[i] * (originalWay.getNode(i).latp- originalWay.getNode(i-1).latp));
				}
				if (nodes[i]) {
					nodes[i].setLonLatp(x,y,undo.push);
				} else {
					nodes[i] = connection.createNode({},Node.latp2lat(y),x,undo.push);
					parallelWay.appendNode(nodes[i], undo.push);
				}
			}

            if  ( originalWay.isArea() && parallelWay.getLastNode() != parallelWay.getNode(0) ) {
                parallelWay.appendNode(nodes[0],undo.push);
            }

			parallelWay.resume();
			undo.doAction();		// don't actually add it to the undo stack, just do it!
		}
		
		/** Compute determinant. */
		private function det(a:Number,b:Number,c:Number,d:Number):Number { return a*d-b*c; }

	}
}
