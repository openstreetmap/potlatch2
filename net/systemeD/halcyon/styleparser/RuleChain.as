package net.systemeD.halcyon.styleparser {

    import net.systemeD.halcyon.connection.*;

	/**	A descendant list of MapCSS selectors (Rules).
	
		For example,
			relation[type=route] way[highway=primary]
			^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^
			    first Rule           second Rule
			       |------------|---------|
			                    |
			             one RuleChain

	*/

	public class RuleChain {
		public var rules:Array=[];				// should eventually become a Vector of Rules
		public var subpart:String='default';	// subpart name, as in way[highway=primary]::centreline

		// Test a ruleChain
		// - run a set of tests in the chain
		//		works backwards from at position "pos" in array, or -1  for the last
		//		separate tags object is required in case they've been dynamically retagged
		// - if they fail, return false
		// - if they succeed, and it's the last in the chain, return happily
		// - if they succeed, and there's more in the chain, rerun this for each parent until success
		
		public function test(pos:int, obj:Entity, tags:Object, zoom:uint):Boolean {
			if (length==0) { return false; }
			if (pos==-1) { pos=rules.length-1; }
			
			var r:Rule=rules[pos];
			if (!r.test(obj, tags, zoom)) { return false; }
			if (pos==0) { return true; }
			
			var o:Array=obj.parentObjects;
			for each (var p:Entity in o) {
				if (test(pos-1, p, p.getTagsHash(), zoom)) { return true; }
			}
			return false;
		}
		
		public function get length():int {
			return rules.length;
		}
		
		public function setSubpart(s:String):void {
			subpart = s=='' ? 'default' : s;
		}

		// ---------------------------------------------------------------------------------------------
		// Methods to add properties (used by parsers such as MapCSS)

		public function addRule(e:String=''):void {
			rules.push(new Rule(e));
		}

		public function addConditionToLast(c:Condition):void {
			rules[rules.length-1].conditions.push(c);
		}

		public function addZoomToLast(z1:uint,z2:uint):void {
			rules[rules.length-1].minZoom=z1;
			rules[rules.length-1].maxZoom=z2;
		}

	}
}
