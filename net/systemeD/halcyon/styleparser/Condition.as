package net.systemeD.halcyon.styleparser {

	/**	A single tag test that forms part of a MapCSS selector.
		For example, "highway==primary" or "population>1000".
		Conditions are grouped in Rules.
		
		@see net.systemeD.halcyon.styleparser.Rule */

	public class Condition {
		public var type:String;
		public var params:Array;

		/** Create a new Condition.														<p>
		  
			Valid types:															</p><p>
			eq,'highway','trunk'		- simple equality test						</p><p>
			ne,'highway','trunk'		- not equals								</p><p>
			regex,'highway','trunk.+'	- regular expression						</p><p>
			true,'bridge'				- value is true/yes/1						</p><p>
			untrue,'bridge'				- value is not true/yes/1					</p><p>
			set,'highway'				- tag exists and is not ''					</p><p>
			unset,'highway'				- tag does not exist, or is ''				</p><p>
			<,'population','5000'		- numeric comparison (also <=, >, >=)		</p>
		 */
		
		public function Condition(type:String='', ...params) {
			this.type=type; this.params=params;
		}
		
		/** Test a tag hash against the Condition. */

		public function test(tags:Object):Boolean {
			switch (type) {
				case 'eq':		return (tags[params[0]]==params[1]); break;
				case 'ne':		return (tags[params[0]]!=params[1]); break;
				case 'regex':	var r:RegExp=new RegExp(params[1],"i");
								return (r.test(tags[params[0]])); break;
				case 'true':	return (tags[params[0]]=='true' || tags[params[0]]=='yes' || tags[params[0]]=='1'); break;
				case 'untrue':	return (tags[params[0]]!='true' && tags[params[0]]!='yes' && tags[params[0]]!='1'); break;
				case 'set':		return (tags[params[0]]!=undefined && tags[params[0]]!=''); break;
				case 'unset':	return (tags[params[0]]==undefined || tags[params[0]]==''); break;
				case '<':		return (Number(tags[params[0]])< Number(params[1])); break;
				case '<=':		return (Number(tags[params[0]])<=Number(params[1])); break;
				case '>':		return (Number(tags[params[0]])> Number(params[1])); break;
				case '>=':		return (Number(tags[params[0]])>=Number(params[1])); break;
			}
			return false;
		}

        public function toString():String {
            return "Condition("+type+":"+params+")";
        }


	}

}
