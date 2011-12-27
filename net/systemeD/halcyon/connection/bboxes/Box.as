package net.systemeD.halcyon.connection.bboxes {
	
	public class Box {

		public var x:Interval;
		public var y:Interval;
		
		function Box():void {
		}
		
		public function get left():Number   { return x._min; }
		public function get right():Number  { return x._max; }
		public function get bottom():Number { return y._min; }
		public function get top():Number    { return y._max; }
		
		// Initialise from either a bbox or two Intervals

		public function fromIntervals(x:Interval,y:Interval):Box {
			this.x=x; this.y=y;
			return this;
		}
		public function fromBbox(minx:Number,miny:Number,maxx:Number,maxy:Number):Box {
			x=new Interval(minx,maxx);
			y=new Interval(miny,maxy);
			return this;
		}
		
		// If this box has any area, whether it contains a valid amount of space.

		public function get valid():Boolean {
			return (x.valid && y.valid);
		}

		// Whether this box intersects another.

		public function intersects(other:Box):Boolean {
			return (x.intersects(other.x) && y.intersects(other.y));
		}
		
		// Intersection. May return a box that isn't valid.
		public function intersection(other:Box):Box {
			return (new Box().fromIntervals(x.intersection(other.x), y.intersection(other.y)));
		}

		// Union. Return a Box covering this Box and the other.
		public function union(other:Box):Box {
			return (new Box().fromIntervals(x.union(other.x), y.union(other.y)));
		}

		// Inverse. Returns an array of 4 Boxes covering all space except for this box.
		public function get inverse():Array {
			return [
				new Box().fromBbox(-Infinity, y._max,    Infinity, Infinity),
				new Box().fromBbox(-Infinity, y._min,    x._min,   y._max  ),
				new Box().fromBbox(x._max,    y._min,    Infinity, y._max  ),
				new Box().fromBbox(-Infinity, -Infinity, Infinity, y._min  )
			];
		}

		// Subtraction. take the inverse of one bbox and intersect it with this one. returns an array of Boxes.
		public function subtract(other:Box):Array {
			var inverses:Array=other.inverse;
			var results:Array=[];
			var candidate:Box;
			for each (var i:Box in inverses) {
				candidate=intersection(i);
				if (candidate.valid) results.push(candidate);
			}
			return results;
		}

		// Subtract all Boxes in given array. Resulting set of boxes will be disjoint.
		public function subtractAll(others:Array):Array {
			var memo:Array=[this];
			for each (var other:Box in others) {
				var subtracted:Array=[];
				for each (var b:Box in memo) {
					subtracted=subtracted.concat(b.subtract(other));
				}
				memo=subtracted;
			}
			// do we need to flatten memo here?
			return memo;
		}

		// Is this box directly adjacent to the other, with no gap in between?

		public function adjacentTo(other:Box):Boolean {
			return (((x.equals(other.x)) && ((y._min == other.y._max) || (y._max == other.y._min))) ||
					((y.equals(other.y)) && ((x._min == other.x._max) || (x._max == other.x._min))));
		}

		// Merge as many boxes as possible without increasing the total area of the set of boxes. This is done by
		// identifying edges along which boxes are adjacent. Note that the input set must be disjoint.
		//
		// This is an O(n^2) algorithm, so it's going to be very slow on large numbers of boxes. There's 
		// almost certainly a better algorithm out there to do the same thing in better time. but it's nice
		// and simple.

		public static function merge(boxes:Array):Array {
			if (boxes.length==0) return [];
			var first:Box=boxes.shift();
			var kept:Array=[];
			for each (var box:Box in boxes) {
				if (first.adjacentTo(box)) { first=first.union(box); }
				else kept.push(box);
			}
			return [first].concat(Box.merge(kept));
		}

		public function equals(other:Box):Boolean {
			return (x.equals(other.x) && y.equals(other.y));
		}
		
		public function get size():Number {
			return (x.size*y.size);
		}

		public function toString():String {
			return ("Box["+x._min+","+y._min+","+x._max+","+y._max+"]");
		}
	}
}
