package net.systemeD.halcyon.vectorlayers {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.NodeUI;
	import net.systemeD.halcyon.WayUI;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Entity;
	import net.systemeD.halcyon.styleparser.*;

	// A CustomVectorLayer can be fully styled with Halcyon rules.

	public class CustomVectorLayer extends VectorLayer {

		public function CustomVectorLayer(n:String,m:Map,style:String) {
			super(n,m);
			paint.ruleset=new RuleSet(m.MINSCALE,m.MAXSCALE,paint.redraw);
			paint.ruleset.loadFromCSS(style);
		}
	}
}
