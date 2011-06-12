package net.systemeD.halcyon.styleparser {

	import net.systemeD.halcyon.connection.Entity;

	public class StyleChooser {

		/*
			A StyleChooser object is equivalent to one CSS selector+declaration.

			Its ruleChains property is an array of all the selectors, which would
			traditionally be comma-separated. For example:
				h1, h2, h3 em
			is three RuleChains.
			
			Each RuleChain is itself an array of nested selectors. So the above 
			example would roughly be encoded as:
				[[h1],[h2],[h3,em]]
				  ^^   ^^   ^^ ^^   each of these is a Rule
				 ^^^^ ^^^^ ^^^^^^^  each of these is a RuleChain
				
			The styles property is an array of all the style objects to be drawn
			if any of the ruleChains evaluate to true.

		*/

		public var ruleChains:Array;				// array of RuleChains (each one an array of Rules)
		public var styles:Array=[];					// array of ShapeStyle/ShieldStyle/TextStyle/PointStyle
		public var zoomSpecific:Boolean=false;		// are any of the rules zoom-specific?

		private var rcpos:uint;
		private var stylepos:uint=0;

		public function StyleChooser():void {
			ruleChains=[new RuleChain()];
			rcpos=0;
		}

		public function get currentChain():RuleChain {
			return ruleChains[rcpos];
		}

		// Update the current StyleList from this StyleChooser

		public function updateStyles(obj:Entity, tags:Object, sl:StyleList, imageWidths:Object, zoom:uint):void {
			if (zoomSpecific) { sl.validAt=zoom; }

			// Are any of the ruleChains fulfilled?
			var w:Number;
			var fulfilled:Boolean=false;
			for each (var c:RuleChain in ruleChains) {
				if (c.test(-1,obj,tags,zoom)) {
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
				sl.addSublayer(r.sublayer);
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
		
		
		// ---------------------------------------------------------------------------------------------
		// Methods to add properties (used by parsers such as MapCSS)
		
		// newRuleChain		<- starts a new ruleChain in this.ruleChains
		public function newRuleChain():void {
			if (ruleChains[rcpos].length>0) {
				ruleChains[++rcpos]=new RuleChain();
			}
		}

		// addStyles	<- adds to this.styles
		public function addStyles(a:Array):void {
			styles=styles.concat(a);
		}
		
	}
}
