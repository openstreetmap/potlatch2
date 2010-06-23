package net.systemeD.halcyon.styleparser {

	import net.systemeD.halcyon.connection.Entity;
	import net.systemeD.halcyon.Globals;

	public class StyleChooser {

		/*
			A StyleChooser object is equivalent to one CSS selector+declaration.

			Its ruleChains property is an array of all the selectors, which would
			traditionally be comma-separated. For example:
				h1, h2, h3 em
			is three ruleChains.
			
			Each ruleChain is itself an array of nested selectors. So the above 
			example would roughly be encoded as:
				[[h1],[h2],[h3,em]]
				  ^^   ^^   ^^ ^^   each of these is a Rule

			The styles property is an array of all the style objects to be drawn
			if any of the ruleChains evaluate to true.

		*/

		public var ruleChains:Array=[[]];		// array of array of Rules
		public var styles:Array=[];				// array of ShapeStyle/ShieldStyle/TextStyle/PointStyle

		private var rcpos:uint=0;
		private var stylepos:uint=0;

		// Update the current StyleList from this StyleChooser

		public function updateStyles(obj:Entity, tags:Object, sl:StyleList, imageWidths:Object):void {
			// Are any of the ruleChains fulfilled?
			// ** needs to cope with min/max zoom
			var w:Number;
			var fulfilled:Boolean=false;
			for each (var c:Array in ruleChains) {
				if (testChain(c,-1,obj,tags)) {
					fulfilled=true; break;
				}
			}
			if (!fulfilled) { return; }

			// Update StyleList
			for each (var r:Style in styles) {
				var a:*;
				if (r is ShapeStyle) {
					a=sl.shapeStyles;
					if (ShapeStyle(r).width>sl.maxwidth && !r.evals['width']) { sl.maxwidth=ShapeStyle(r).width; }
				} else if (r is ShieldStyle) {
					a=sl.shieldStyles;
				} else if (r is TextStyle) { 
					a=sl.textStyles;
				} else if (r is PointStyle) { 
					a=sl.pointStyles;
					w=0;
					if (PointStyle(r).icon_width && !PointStyle(r).evals['icon_width']) {
						w=PointStyle(r).icon_width;
					} else if (PointStyle(r).icon_image && imageWidths[PointStyle(r).icon_image]) {
						w=imageWidths[PointStyle(r).icon_image];
					}
					if (w>sl.maxwidth) { sl.maxwidth=w; }
				} else if (r is InstructionStyle) {
					if (InstructionStyle(r).breaker) { return; }
					if (InstructionStyle(r).set_tags) {
						for (var k:String in InstructionStyle(r).set_tags) { tags[k]=InstructionStyle(r).set_tags[k]; }
					}
					continue;
				}
				if (r.drawn) { tags[':drawn']='yes'; }
				tags['_width']=sl.maxwidth;
				
				r.runEvals(tags);
				if (a[r.sublayer]) {
					// If there's already a style on this sublayer, then merge them
					// (making a deep copy if necessary to avoid altering the root style)
					if (!a[r.sublayer].merged) { a[r.sublayer]=a[r.sublayer].deepCopy(); }
					a[r.sublayer].mergeWith(r);
				} else {
					// Otherwise, just assign it
					a[r.sublayer]=r;
				}
			}
		}


		// Test a ruleChain
		// - run a set of tests in the chain
		//		works backwards from at position "pos" in array, or -1  for the last
		//		separate tags object is required in case they've been dynamically retagged
		// - if they fail, return false
		// - if they succeed, and it's the last in the chain, return happily
		// - if they succeed, and there's more in the chain, rerun this for each parent until success
		
		private function testChain(chain:Array,pos:int,obj:Entity,tags:Object):Boolean {
			if (pos==-1) { pos=chain.length-1; }

			var r:Rule=chain[pos];
			if (!r.test(obj, tags)) { return false; }
			if (pos==0) { return true; }
			
			var o:Array=obj.parentObjects;
			for each (var p:Entity in o) {
				if (testChain(chain, pos-1, p, p.getTagsHash() )) { return true; }
			}
			return false;
		}
		
		
		// ---------------------------------------------------------------------------------------------
		// Methods to add properties (used by parsers such as MapCSS)
		
		// newGroup		<- starts a new ruleChain in this.ruleChains
		public function newGroup():void {
			if (ruleChains[rcpos].length>0) {
				ruleChains[++rcpos]=[];
			}
		}

		// newObject	<- adds into the current ruleChain (starting a new Rule)
		public function newObject(e:String=''):void {
			ruleChains[rcpos].push(new Rule(e));
		}

		// addZoom		<- adds into the current ruleChain (existing Rule)
		public function addZoom(z1:uint,z2:uint):void {
			ruleChains[rcpos][ruleChains[rcpos].length-1].minZoom=z1;
			ruleChains[rcpos][ruleChains[rcpos].length-1].maxZoom=z2;
		}
		
		// addCondition	<- adds into the current ruleChain (existing Rule)
		public function addCondition(c:Condition):void {
			ruleChains[rcpos][ruleChains[rcpos].length-1].conditions.push(c);
		}

		// addStyles	<- adds to this.styles
		public function addStyles(a:Array):void {
			styles=styles.concat(a);
		}
		
	}
}
