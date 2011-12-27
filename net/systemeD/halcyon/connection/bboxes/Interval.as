package net.systemeD.halcyon.connection.bboxes {
	
	public class Interval {

		public var _min:Number;
		public var _max:Number;
		
		function Interval(min:Number,max:Number):void {
			_min=min;
			_max=max;
		}

		public function contains(x:Number):Boolean { return (x>=_min && x<_max); }
		public function get valid():Boolean { return (_max>_min); }
		public function get size():Number { return (_max-_min); }

		public function intersects(other:Interval):Boolean { return (_max>other._min && _min<other._max); }
		public function equals(other:Interval):Boolean { return (_min==other._min && _max==other._max); }
		public function union(other:Interval):Interval { return new Interval(Math.min(_min,other._min), Math.max(_max,other._max)); }
		public function intersection(other:Interval):Interval { return new Interval(Math.max(_min,other._min), Math.min(_max,other._max)); }
		
		public function toString():String { return ("Interval["+_min+","+_max+"]"); }

		// Merge an array of possibly overlapping intervals into a set of disjoint intervals.
		public static function merge(intervals:Array):Array {
			intervals.sort(compareMinimum);
			var memo:Array=[];
			for each (var elem:Interval in intervals) {
				var last:Interval=memo.pop();
				if (!last) { 
					memo=[elem];
				} else if (last.intersects(elem)) {
					memo.push(last.union(elem));
				} else {
					memo.push(last);
					memo.push(elem);
				}
			}
			return memo;
		}

		// Returns the largest empty interval in the given set of intervals.
		
		public static function largestEmpty(intervals:Array):Interval {
			var gaps:Array=[];
			intervals=merge(intervals);
			for (var i:uint=0; i<=intervals.length-2; i++) {
				gaps.push(new Interval(intervals[i]._max, intervals[i+1]._min));
			}
			gaps.sort(compareSize);
			return gaps[gaps.length-1];
		}

		// Comparison methods for sorting

		private static function compareMinimum(a:Interval, b:Interval):int {
			if (a._min>b._min) { return 1; }
			if (a._min<b._min) { return -1; }
			return 0;
		}

		private static function compareSize(a:Interval, b:Interval):int {
			if (a.size>b.size) { return 1; }
			if (a.size<b.size) { return -1; }
			return 0;
		}
	}
}
