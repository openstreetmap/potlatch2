package net.systemeD.halcyon.styleparser {

    import net.systemeD.halcyon.connection.*;

	/**	A MapCSS selector. Contains a list of Conditions; the entity type to which the selector applies; 
		and the zoom levels at which it is true. way[waterway=river][boat=yes] would be parsed into one Rule. <p>
		
		The selectors and declaration together form a StyleChooser.											  </p>
		
		@see net.systemeD.halcyon.styleparser.Condition
		@see net.systemeD.halcyon.styleparser.StyleChooser */

	public class Rule {

		/** The Conditions to be evaluated for the Rule to be fulfilled. */
		public var conditions:Array = [];
		/** Do all Conditions need to be true for the Rule to be fulfilled? (Always =true for MapCSS.) */
		public var isAnd:Boolean = true;
		/** Minimum zoom level at which the Rule is fulfilled. */
		public var minZoom:uint = 0;
		/** Maximum zoom level at which the Rule is fulfilled. */
		public var maxZoom:uint = 255;
		/** Entity type to which the Rule applies. Can be 'way', 'node', 'relation', 'area' (closed way) or 'line' (unclosed way). */
		public var subject:String='';
		
		public function Rule(subject:String=''):void {
			this.subject=subject;
		}
		
		/** Evaluate the Rule on the given entity, tags and zoom level.
		 	@return True if the Rule passes, false if the conditions aren't fulfilled. */

		public function test(entity:Entity,tags:Object,zoom:uint):Boolean {
			if (subject!='' && !entity.isType(subject)) { return false; }
			if (zoom<minZoom || zoom>maxZoom) { return false; }
			
			var v:Boolean=true; var i:uint=0;
			for each (var condition:Condition in conditions) {
				var r:Boolean=condition.test(tags);
				if (i==0) { v=r; }
				else if (isAnd) { v=v && r; }
				else { v = v || r;}
				i++;
			}
			return v;
		}

		public function toString():String {
			return subject+" z"+minZoom+"-"+maxZoom+": "+conditions;
		}
	}
}