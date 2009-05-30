package net.systemeD.halcyon.styleparser {

	// valid conditions:
	// _type_	_params_
	// regex	key, regex
	// eq		key, value

	public class Condition {
		public var type:String;		// eq, regex, lt, gt etc.
		public var params:Array;	// e.g. ('highway','primary')
		
		// ------------------------------------------------------------------------------------------
		// Constructor function
		
		public function Condition(t:String='', ...a) {
			type=t; params=a;
		}
		
		// ------------------------------------------------------------------------------------------
		// Test a hash against this condition

		public function test(tags:Object):Boolean {
			switch (type) {
				case 'eq':		return (tags[params[0]]==params[1]); break;
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
	}

}
