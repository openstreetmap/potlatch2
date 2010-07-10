package net.systemeD.halcyon {

	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import net.systemeD.halcyon.NodeUI;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.styleparser.RuleSet;
	import net.systemeD.halcyon.Globals;

    public class MapPaint extends Sprite {

		public var map:Map;
		public var minlayer:int;
		public var maxlayer:int;
		public var ruleset:RuleSet;						// rules
		public var wayuis:Object=new Object();			// sprites for ways and (POI/tagged) nodes
		public var nodeuis:Object=new Object();			//  |
		public var isBackground:Boolean = true;			// is it a background layer or the core paint object?
		public var sublayerIndex:Object={};				// hash of index->position

		private const VERYBIG:Number=Math.pow(2,16);

		// Set up layering
		// [layer][3]			- names
		// [layer][2][sublayer]	- stroke
		// [layer][1]			- casing
		// [layer][0]			- fill

		public function MapPaint(map:Map,minlayer:int,maxlayer:int) {
			this.map=map;
			this.minlayer=minlayer;
			this.maxlayer=maxlayer;
			sublayerIndex[1]=0;

			for (var l:int=minlayer; l<=maxlayer; l++) {	// each layer (10 is +5, 0 is -5)
				var s:Sprite = getHitSprite();      		//  |
				s.addChild(getPaintSprite());				//	| 0 fill
				s.addChild(getPaintSprite());				//	| 1 casing
				var t:Sprite = getPaintSprite();			//  | 2 stroke
				t.addChild(getPaintSprite());				//  |  | sublayer
				s.addChild(t);								//  |  |
				s.addChild(getPaintSprite());				//	| 3 names
				s.addChild(getHitSprite());					//	| 4 way hit tests
				s.addChild(getHitSprite());				    //	| 5 node hit tests
				addChild(s);								//  |
			}
			addChild(getPaintSprite());     				// name sprite
		}
		
		public function get ready():Boolean {
			if (!ruleset) { return false; }
			if (!ruleset.loaded) { return false; }
			return true;
		}

		public function sublayer(layer:int,sublayer:Number):Sprite {
			var l:DisplayObject;
			var o:DisplayObject;
			var index:String, ix:Number;
			if (!sublayerIndex.hasOwnProperty(sublayer)) {
				// work out which position to add at
				var lowestAbove:Number=VERYBIG;
				var lowestAbovePos:int=-1;
				var indexLength:uint=0;
				for (index in sublayerIndex) {
					ix=Number(index);
					if (ix>sublayer && ix<lowestAbove) {
						lowestAbove=ix;
						lowestAbovePos=sublayerIndex[index];
					}
					indexLength++;
				}
				if (lowestAbovePos==-1) { lowestAbovePos=indexLength; }
			
				// add sprites
				for (var i:int=minlayer; i<=maxlayer; i++) {
					l=getChildAt(i-minlayer);
					o=(l as Sprite).getChildAt(2);
					(o as Sprite).addChildAt(getPaintSprite(),lowestAbovePos);
				}
			
				// update index
				// (we do it in this rather indirect way because if you alter sublayerIndex directly
				//  within the loop, it confuses the iterator)
				var toUpdate:Array=[];
				for (index in sublayerIndex) {
					ix=Number(index);
					if (ix>sublayer) { toUpdate.push(index); }
				}
				for each (index in toUpdate) { sublayerIndex[index]++; }
				sublayerIndex[sublayer]=lowestAbovePos;
			}

			l=getChildAt(layer-minlayer);
			o=(l as Sprite).getChildAt(2);
			return ((o as Sprite).getChildAt(sublayerIndex[sublayer]) as Sprite);
		}

		public function updateEntityUIs(o:Object, redraw:Boolean, remove:Boolean):void {
			var way:Way, node:Node;

			for each (way in o.waysInside) {
				if (!wayuis[way.id]) { createWayUI(way); }
				else if (redraw) { wayuis[way.id].recalculate(); wayuis[way.id].redraw(); }
			}
			if (remove) {
				for each (way in o.waysOutside) { deleteWayUI(way); }
			}

			for each (node in o.poisInside) {
				if (!nodeuis[node.id]) { createNodeUI(node); }
				else if (redraw) { nodeuis[node.id].redraw(); }
			}
			if (remove) {
				for each (node in o.poisOutside) { deleteNodeUI(node); }
			}
		}

		public function createWayUI(way:Way):WayUI {
			if (!wayuis[way.id]) { wayuis[way.id]=new WayUI(way,this); }
			return wayuis[way.id];
		}

		public function createNodeUI(node:Node):NodeUI {
			if (!nodeuis[node.id]) { nodeuis[node.id]=new NodeUI(node,this,0); }
			return nodeuis[node.id];
		}

		public function deleteWayUI(way:Way):void {
			if (!wayuis[way.id]) { return; }
			wayuis[way.id].removeSprites();
			delete wayuis[way.id];
			for (var i:uint=0; i<way.length; i++) {
				deleteNodeUI(way.getNode(i));
			}
		}

		public function deleteNodeUI(node:Node):void {
			if (!nodeuis[node.id]) { return; }
			nodeuis[node.id].removeSprites();
			delete nodeuis[node.id];
		}
		
		public function renumberWayUI(way:Way,oldID:Number):void {
			if (!wayuis[oldID]) { return; }
			wayuis[way.id]=wayuis[oldID];
			delete wayuis[oldID];
		}

		public function renumberNodeUI(node:Node,oldID:Number):void {
			if (!nodeuis[oldID]) { return; }
			nodeuis[node.id]=nodeuis[oldID];
			delete nodeuis[oldID];
		}

        private function getPaintSprite():Sprite {
            var s:Sprite = new Sprite();
            s.mouseEnabled = false;
            s.mouseChildren = false;
            return s;
        }

        private function getHitSprite():Sprite {
            var s:Sprite = new Sprite();
            return s;
        }

		public function redraw():void {
			for each (var w:WayUI in wayuis) { w.recalculate(); w.redraw(); }
			for each (var p:NodeUI in nodeuis) { p.redraw(); }
		}

		public function redrawPOIs():void {
			for each (var p:NodeUI in nodeuis) { p.redraw(); }
		}
		
		public function findSource():VectorLayer {
			var v:VectorLayer;
			for each (v in map.vectorlayers) {
				if (v.paint==this) { return v; }
			}
			return null;
		}
	}
}
