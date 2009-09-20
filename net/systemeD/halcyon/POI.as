package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
    import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.styleparser.*;
	
	public class POI extends Object {
		
        private var node:Node;
		public var map:Map;							// reference to parent map
		public var icon:Bitmap;						// instance in display list
		public var name:Sprite;						//  |
		private var iconname:String='';				// name of icon

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
//			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};
//		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
//		public static var DejaVu:Class;

		public function POI(node:Node, map:Map) {
			this.map = map;
			this.node = node;
			redraw();
		}
		
		public function redraw():void {
			var tags:Object = node.getTagsCopy();
			// ** apply :hover etc.
			var sl:StyleList=map.ruleset.getStyles(this.node,tags);
			var r:Boolean=false;	// ** rendered
			var l:DisplayObject;
			for (var sublayer:uint=0; sublayer<10; sublayer++) {

				if (sl.pointStyles[sublayer]) {
					var s:PointStyle=sl.pointStyles[sublayer];
//					if ((s is PointStyle) && s.icon && s.icon!="") 
					r=true;
					if (s.icon_image!=iconname) {
						// 'load' icon (actually just from library)
						if (map.ruleset.images[s.icon_image]) {
//							l=map.getChildAt(map.POISPRITE);
//							Sprite(l).addChild(map.ruleset.images[s.icon_image]);
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedIcon);
							loader.loadBytes(map.ruleset.images[s.icon_image]);
							iconname=s.icon_image;
						}
					} else {
						// already loaded, so just reposition
						updatePosition();
						iconname=s.icon_image;
					}
				}

				if (sl.textStyles[sublayer]) {
					var t:TextStyle=sl.textStyles[sublayer];
//					if ((s is TextStyle) && s.tag && tags[s.tag])
					// create name sprite
					if (!name) {
						name=new Sprite();
						var c:DisplayObject=map.getChildAt(map.NAMESPRITE);
						Sprite(c).addChild(name);
					}
					t.writeNameLabel(name,tags[t.text],map.lon2coord(node.lon),map.latp2coord(node.latp));
				}
			}
			if (!r && iconname!='') {
				// not rendered any more, so remove
				l=map.getChildAt(map.POISPRITE);
				Sprite(l).removeChild(icon);
				iconname='';
			}
		}

		private function loadedIcon(event:Event):void {
			icon = Bitmap(event.target.content);
			var l:DisplayObject=map.getChildAt(map.POISPRITE);
			Sprite(l).addChild(icon);
			updatePosition();
		}

		private function updatePosition():void {
			icon.x=map.lon2coord(node.lon)-icon.width/2;
			icon.y=map.latp2coord(node.latp)-icon.height/2;
		}

	}
}
