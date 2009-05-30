package net.systemeD.halcyon {

	public class POI extends Object {

		import flash.display.*;
		import flash.events.*;
		import flash.text.TextField;
		import flash.text.TextFormat;
		import net.systemeD.halcyon.styleparser.*;

		public var id:int;
		public var tags:Object;
		public var clean:Boolean=true;				// altered since last upload?
		public var uploading:Boolean=false;			// currently uploading?
		public var locked:Boolean=false;			// locked against upload?
		public var version:uint=0;					// version number?
		public var map:Map;							// reference to parent map
		public var icon:Sprite;						// instance in display list
		public var name:Sprite;						//  |

		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
		public static var DejaVu:Class;
		public var nameformat:TextFormat;

		public function POI(id:int,version:int,lon:Number,lat:Number,tags:Object,map:Map) {
			this.id=id;
			this.version=version;
			this.map=map;
			if (tags==null) { tags=new Object(); }
			this.tags=tags;
map.addDebug("POI "+id);
			if (map.nodes[id]) {
				// ** already exists - do stuff if it's moved, or in a way
			} else {
				map.nodes[id]=new Node(id,lon,map.lat2latp(lat),tags,version);
			}

			// place icon on map
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
			bitmap.x=map.lon2coord(map.nodes[id].lon);
			bitmap.y=map.latp2coord(map.nodes[id].latp);
			Sprite(l).addChild(bitmap);
		}
		
		// redraw
	}
}
