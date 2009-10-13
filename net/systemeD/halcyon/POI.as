package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.Connection;
	import net.systemeD.halcyon.styleparser.*;
	
	public class POI extends Object {
		
        private var node:Node;
		public var map:Map;							// reference to parent map
		public var icon:Sprite;						// instance in display list
		public var name:Sprite;						//  |
		private var iconname:String='';				// name of icon
		public var loaded:Boolean=false;

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
//			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};
//		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
//		public static var DejaVu:Class;

		public function POI(node:Node, map:Map, sl:StyleList=null) {
			this.map = map;
			this.node = node;
			redraw(sl);
			node.addEventListener(Connection.NODE_MOVED, nodeMoved);
		}
		
		public function nodeMoved(event:Event):void {
		    updatePosition();
		}
		
		public function redraw(sl:StyleList=null):Boolean {
			var tags:Object = node.getTagsCopy();
			// ** apply :hover etc.
			if (!sl) { sl=map.ruleset.getStyles(this.node,tags); }
			if (!sl.hasStyles() && iconname=='') { return false; }
			
			var r:Boolean=false;	// ** rendered
			var l:DisplayObject;
			for (var sublayer:uint=0; sublayer<10; sublayer++) {

				if (sl.pointStyles[sublayer]) {
					var s:PointStyle=sl.pointStyles[sublayer];
					r=true;
					if (s.icon_image!=iconname) {
						// 'load' icon (actually just from library)
						if (map.ruleset.images[s.icon_image]) {
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedIcon);
							loader.loadBytes(map.ruleset.images[s.icon_image]);
							iconname=s.icon_image;
						}
					} else {
						// already loaded, so just reposition
						updatePosition();
					}
				}

				// name sprite
				var a:String, t:TextStyle;
				if (sl.textStyles[sublayer]) {
					t=sl.textStyles[sublayer];
					a=tags[t.text];
				}

				var c:DisplayObject=map.getChildAt(map.NAMESPRITE);
				if (a) { 
					if (!name) { name=new Sprite(); Sprite(c).addChild(name); }
					t.writeNameLabel(name,a,map.lon2coord(node.lon),map.latp2coord(node.latp));
				} else if (name) {
					Sprite(c).removeChild(name);
					name=null;
				}
			}
			if (!r && iconname!='') {
				// not rendered any more, so remove
				l=map.getChildAt(map.POISPRITE);
				Sprite(l).removeChild(icon);
				iconname='';
			}
			return true;
		}

		private function loadedIcon(event:Event):void {
			icon = new Sprite();
			icon.addChild(Bitmap(event.target.content));
			var l:DisplayObject=map.getChildAt(map.POISPRITE);
			Sprite(l).addChild(icon);
			loaded=true;
			updatePosition();

            icon.addEventListener(MouseEvent.CLICK, mouseEvent);
            icon.addEventListener(MouseEvent.DOUBLE_CLICK, mouseEvent);
            icon.addEventListener(MouseEvent.MOUSE_OVER, mouseEvent);
            icon.addEventListener(MouseEvent.MOUSE_OUT, mouseEvent);
            icon.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
            icon.addEventListener(MouseEvent.MOUSE_UP, mouseEvent);
            icon.addEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
            icon.buttonMode = true;
            icon.mouseEnabled = true;

		}

        private function mouseEvent(event:MouseEvent):void {
			map.entityMouseEvent(event, node);
        }

		private function updatePosition():void {
			if (!loaded) { return; }
			icon.x=map.lon2coord(node.lon)-icon.width/2;
			icon.y=map.latp2coord(node.latp)-icon.height/2;
		}

	}
}
