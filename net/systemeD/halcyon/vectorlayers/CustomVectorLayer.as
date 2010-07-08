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

		public function CustomVectorLayer(name:String,map:Map,style:String) {
			super(name,map);
			this.style=style;
			redrawFromCSS(style);
		}
		
		public function redrawFromCSS(style:String):void {
			paint.ruleset=new RuleSet(map.MINSCALE,map.MAXSCALE,paint.redraw);
			paint.ruleset.loadFromCSS(style);
		}
	}
}
