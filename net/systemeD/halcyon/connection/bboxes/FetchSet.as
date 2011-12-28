package net.systemeD.halcyon.connection.bboxes {
	
	public class FetchSet {

		private var existing:Array;
		private static const MAX_PARTITION_TRIALS:uint = 100;

		function FetchSet():void {
			existing=[];
		}

		public function getBoxes(bbox:Box,maxBoxes:uint):Array {
			var bits:Array=Box.merge(bbox.subtractAll(existing));
			var toFetch:Array=optimalPart(maxBoxes,bits);
			return toFetch;
		}
		
		public function add(bbox:Box):void {
			existing.push(bbox);
			existing=existing.filter(function(item:Box,i:uint,arr:Array):Boolean {
				return !bbox.encloses(item);
			});
		}

		public function get size():int {
			return existing.length;
		}

		private function rgString(prefix:Array, numSets:int, numElts:int, numTries:int):Array {
			if (numElts==0) return [prefix];
			var maxDigit:Number=Math.min(maxValue(prefix)+1,numSets-1);
			var result:Array=[];
			for (var digit:uint=0; digit<=maxDigit; digit++) {
				if (numTries>0) {
					var rv:Array=rgString(prefix.concat([digit]),numSets,numElts-1,numTries);
					numTries-=rv.length;
					result=result.concat(rv);
				}
			}
			return result;
		}

		// select only the partitions of the set which have a certain size, or smaller

		private function partsOfSize(n:int,set:Array):Array {
			if (set.length==0) { return []; }
			return (rgString([0], n, set.length-1, MAX_PARTITION_TRIALS).map(
				function(rgs:Array,index:uint,array:Array):* {
					var ary:Array=[];
					for (var j:uint=0; j<=maxValue(rgs); j++) ary.push([]);
					for (var i:uint=0; i<rgs.length; i++) ary[rgs[i]].push(set[i]);
					return ary;
				}));
		}
		
		private function maxValue(a:Array):Number {
			var m:Number=Number.NEGATIVE_INFINITY;
			for each (var n:Number in a) m=Math.max(m,n);
			return m;
		}

		// find the optimal partition - the one which requests the smallest amount of extra space - 
		// given the set p of partitions

		private function optimalPart(n:int, set:Array):Array {
			var p:Array=partsOfSize(n,set);
			if (p.length==0) return [];
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
		
		public function toString():String {
			return "["+existing.join(",")+"]";
		}

	}
}
