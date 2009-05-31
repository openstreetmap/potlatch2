package net.systemeD.halcyon {

    import net.systemeD.halcyon.connection.Node;

	public class POI extends Object {

		import flash.display.*;
		import flash.events.*;
		import flash.text.TextField;
		import flash.text.TextFormat;
		import net.systemeD.halcyon.styleparser.*;

        private var node:Node;
		public var map:Map;							// reference to parent map
		public var icon:Sprite;						// instance in display list
		public var name:Sprite;						//  |

		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
		public static var DejaVu:Class;
		public var nameformat:TextFormat;

		public function POI(node:Node, map:Map) {
			this.map = map;
			this.node = node;

map.addDebug("POI "+node.id);

			// place icon on map
            var tags:Object = node.getTagsCopy();
			var styles:Array=map.ruleset.getStyle(true,tags,map.scale);
			var ps:PointStyle=styles[1];

			if (ps) {
map.addDebug("pointstyle found");
 				if (ps.icon && ps.icon!='') {
map.addDebug("placing "+ps.icon);
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedIcon);
					loader.loadBytes(map.ruleset.images[ps.icon]);
				}
			}
		}

		private function loadedIcon(event:Event):void {
map.addDebug("loadedIcon");
			var bitmap:Bitmap = Bitmap(event.target.content);
			var l:DisplayObject=map.getChildAt(11);
			bitmap.x=map.lon2coord(node.lon);
			bitmap.y=map.latp2coord(node.latp);
			Sprite(l).addChild(bitmap);
		}
		
		// redraw
	}
}
