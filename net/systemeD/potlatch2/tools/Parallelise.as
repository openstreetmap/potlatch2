package net.systemeD.potlatch2.tools {

    import net.systemeD.halcyon.connection.*;

	// FIXME:
	// ** needs to be properly undoable

	public class Parallelise {
		private var originalWay:Way;
		public var parallelWay:Way;
		private var connection:Connection;
		private var offsetx:Array=[];
		private var offsety:Array=[];
		private var df:Array=[];
		private var nodes:Object={};
		
		public function Parallelise(way:Way) {
			var a:Number, b:Number, h:Number, i:uint;
			connection  = Connection.getConnection();
			originalWay = way;
			parallelWay = connection.createWay({}, [], MainUndoStack.getGlobalStack().addAction);

			for (i=0; i<originalWay.length-1; i++) {
				a=originalWay.getNode(i  ).latp - originalWay.getNode(i+1).latp;
				b=originalWay.getNode(i+1).lon  - originalWay.getNode(i  ).lon;
				h=Math.sqrt(a*a+b*b);
				if (h!=0) { a=a/h; b=b/h; }
					 else {	a=0; b=0; }
				offsetx[i]=a;
				offsety[i]=b;
			}

			for (i=1; i<originalWay.length-1; i++) {
				a=det(offsetx[i]-offsetx[i-1],
					  offsety[i]-offsety[i-1],
					  originalWay.getNode(i+1).lon  - originalWay.getNode(i  ).lon,
					  originalWay.getNode(i+1).latp - originalWay.getNode(i  ).latp);
				b=det(originalWay.getNode(i  ).lon  - originalWay.getNode(i-1).lon,
					  originalWay.getNode(i  ).latp - originalWay.getNode(i-1).latp,
					  originalWay.getNode(i+1).lon  - originalWay.getNode(i  ).lon,
					  originalWay.getNode(i+1).latp - originalWay.getNode(i  ).latp);
				if (b!=0) { df[i]=a/b; } else { df[i]=0; }
			}

		}

		public function draw(offset:Number):void {
			var x:Number, y:Number;
			var undo:CompositeUndoableAction = new CompositeUndoableAction("Draw parallel way");
			parallelWay.suspend();
			for (var i:int=0; i<originalWay.length; i++) {
				if (i==0) {
					x=originalWay.getNode(0).lon + offset * offsetx[0];
					y=originalWay.getNode(0).latp+ offset * offsety[0];
				} else if (i==originalWay.length-1) {
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
			if (originalWay.isArea()) { parallelWay.appendNode(nodes[0],undo.push); }
			parallelWay.resume();
			MainUndoStack.getGlobalStack().addAction(undo);
		}
		
		private function det(a:Number,b:Number,c:Number,d:Number):Number { return a*d-b*c; }

	}
}
