package net.systemeD.halcyon.connection.bboxes {
	
	public class FetchSet {

		private var existing:Array;

		function FetchSet(max:int):void {
			existing=[];
		}

		public function getBoxes(bbox:Box,maxBoxes:uint):Array {
			var bits:Array=Box.merge(bbox.subtractAll(existing));
			var toFetch:Array=optimalPart(maxBoxes,bits);
			return toFetch;
		}
		
		public function add(bbox:Box):void {
			existing.push(bbox);
		}

		private function partitions(set:Array, yield:Function):void {
			if (set.length==0) { yield([]); return; }
			var z:Number=Math.pow(2,set.length)/2;
			for (var i:uint=0; i<z; i++) {
				var parts:Array= [ [], [] ];
				var c:uint=i;
				for each (var item:Box in set) {
					parts[c & 1].push(item);
					c>>=1;
				}
				partitions(parts[1],function(b:Array):void {
					var result:Array;
					if (b.length) { result=[parts[0]].concat(b); } else { result=[parts[0]]; }
					yield(result);
				});
			}
		}
		
		// select only the partitions of the set which have a certain size, or smaller

		private function partsOfSize(n:int, set:Array):Array {
			var rv:Array=[];
			partitions(set, function(x:Array):void {
				if (x.length<=n) rv.push(x);
			});
			return rv;
		}

		// find the optimal partition - the one which requests the smallest amount of extra space - 
		// given the set p of partitions

		private function optimalPart(n:int, set:Array):Array {
			var p:Array=partsOfSize(n,set);
			var q:Array=p.sort(function(a:Array,b:Array):Number {
				var aw:Number = wasteSize(a, set);
				var bw:Number = wasteSize(b, set);
				if (aw < bw) return -1;
				else if (aw > bw) return 1;
				else return 0;
			});
			return unionPartitions(q[0]);
		}

		private function wasteSize(boxes:Array, set:Array):Number {
			var waste:Number = 0;
			unionPartitions(boxes).forEach(function(b:Box,index:int,array:Array):void {
				var included:Number = 0;
				set.forEach(function(s:Box,index:int,array:Array):void {
					s = s.intersection(b);
					if (s.valid) included += s.size;
				});
				waste += b.size - included;
			});
			return waste;
		}

		private function unionPartitions(a:Array):Array {
			return a.map(function(bs:Array,index:int,array:Array):Box {
				var box:Box = bs[0];
				bs.forEach(function(b:Box,index:int,array:Array):void {
					box=box.union(b);
				});
				return box;
			});
		}

	}
}
