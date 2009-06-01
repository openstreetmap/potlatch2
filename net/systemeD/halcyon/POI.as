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
		public var icon:Bitmap;						// instance in display list
		public var name:Sprite;						//  |
		private var iconname:String='';				// name of icon

		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
		public static var DejaVu:Class;
		public var nameformat:TextFormat;

		public function POI(node:Node, map:Map) {
			this.map = map;
			this.node = node;
			redraw();
		}
		
		public function redraw():void {
			var tags:Object = node.getTagsCopy();
			var styles:Array=map.ruleset.getStyle(true,tags,map.scale);
			var ps:PointStyle=styles[1];

			if (ps && ps.icon && ps.icon!='') {
				if (ps.icon!=iconname) {
					// 'load' icon (actually just from library)
					if (map.ruleset.images[ps.icon]) {
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedIcon);
						loader.loadBytes(map.ruleset.images[ps.icon]);
						iconname=ps.icon;
					}
				} else {
					// already loaded, so just reposition
					updatePosition();
					iconname=ps.icon;
				}
			} else if (iconname!='') {
				// not rendered any more, so remove
				var l:DisplayObject=map.getChildAt(11);
				Sprite(l).removeChild(icon);
				iconname='';
			}
		}

		private function loadedIcon(event:Event):void {
			icon = Bitmap(event.target.content);
			var l:DisplayObject=map.getChildAt(11);
			Sprite(l).addChild(icon);
			updatePosition();
		}

		private function updatePosition():void {
			icon.x=map.lon2coord(node.lon);
			icon.y=map.latp2coord(node.latp);
		}
	}
}
