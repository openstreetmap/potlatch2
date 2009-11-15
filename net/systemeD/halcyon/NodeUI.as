package net.systemeD.halcyon {

	import flash.display.*;
	import flash.events.*;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.geom.Matrix;
	import flash.geom.Point;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.Connection;
	import net.systemeD.halcyon.styleparser.*;
	import net.systemeD.halcyon.Globals;
	
	public class NodeUI extends Object {
		
        private var node:Node;
		public var map:Map;							// reference to parent map
		public var icon:Sprite;						// instance in display list
		public var name:Sprite;						//  |
		private var iconname:String='';				// name of icon
		private var heading:Number=0;				// heading within way
		private var rotation:Number=0;				// rotation applied to this POI
		public var loaded:Boolean=false;

		public static const DEFAULT_TEXTFIELD_PARAMS:Object = {
//			embedFonts: true,
			antiAliasType: AntiAliasType.ADVANCED,
			gridFitType: GridFitType.NONE
		};
//		[Embed(source="fonts/DejaVuSans.ttf", fontFamily="DejaVu", fontWeight="normal", mimeType="application/x-font-truetype")]
//		public static var DejaVu:Class;

		public function NodeUI(node:Node, map:Map, rotation:Number=0) {
			this.map = map;
			this.node = node;
			this.rotation = rotation;
			node.addEventListener(Connection.NODE_MOVED, nodeMoved);
		}
		
		public function nodeMoved(event:Event):void {
		    updatePosition();
		}
		
		public function redraw(sl:StyleList=null,forceDraw:Boolean=false):Boolean {
			var tags:Object = node.getTagsCopy();
			tags['_heading']=heading;
			// ** apply :hover etc.
			if (!sl) { sl=map.ruleset.getStyles(this.node,tags); }

			var inWay:Boolean=node.hasParentWays;
			var hasStyles:Boolean=sl.hasStyles();
			
			removePrevious();
			if (!hasStyles && !inWay) {
				// No styles, not in way; usually return, but render as green circle if showall set
				if (!map.showall) { return false; }
				return renderAsCircle();
			} else if (!hasStyles && inWay) {
				// No styles, in way; so render as highlight
				// *** needs to be blue/red depending on mouse-over
				if (forceDraw) {
					return renderAsSquare();
				} else {
					return false;
				}
			} else {
				// Styled, so render properly
				return renderFromStyle(sl,tags);
			}
		}

		private function renderAsSquare():Boolean {
			createIcon();
			icon.graphics.beginFill(0xFF0000);
			icon.graphics.drawRect(0,0,6,6);	// ** NODESIZE
			loaded=true;
			updatePosition();
			iconname='_square';
			return true;
		}
		
		private function renderAsCircle():Boolean {
			createIcon();
			icon.graphics.lineStyle(1,0,1);
			icon.graphics.beginFill(0x00FF00);
			icon.graphics.drawCircle(4,4,4);	// ** NODESIZE
			loaded=true;
			updatePosition();
			iconname='_circle';
			return true;
		}
		
		private function renderFromStyle(sl:StyleList,tags:Object):Boolean {
			var r:Boolean=false;	// ** rendered
			for (var sublayer:uint=0; sublayer<10; sublayer++) {

				if (sl.pointStyles[sublayer]) {
					var s:PointStyle=sl.pointStyles[sublayer];
					r=true;
					if (s.rotation) { rotation=s.rotation; }
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

				if (a) { 
					var l:DisplayObject=map.getChildAt(map.NAMESPRITE);
					if (!name) { name=new Sprite(); Sprite(l).addChild(name); }
					t.writeNameLabel(name,a,map.lon2coord(node.lon),map.latp2coord(node.latp));
				}
			}
			return r;
		}

		private function removePrevious():void {
			var l:DisplayObject;
			
			if (icon) {
				l=map.getChildAt(map.POISPRITE);
				Sprite(l).removeChild(icon);
				icon=null;
				iconname='';
			}
			if (name) {
				l=map.getChildAt(map.NAMESPRITE);
				Sprite(l).removeChild(name);
				name=null;
			}
		}

		private function loadedIcon(event:Event):void {
			createIcon();
			icon.addChild(Bitmap(event.target.content));
			loaded=true;
			updatePosition();
		}

		private function createIcon():void {
			icon = new Sprite();
			var l:DisplayObject=map.getChildAt(map.POISPRITE);
			Sprite(l).addChild(icon);
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
			if (!loaded || !icon) { return; }
			icon.x=0; icon.y=0; icon.rotation=0;

			var m:Matrix=new Matrix();
//			m.identity();
			m.translate(-icon.width/2,-icon.height/2);
			m.rotate(rotation);
			m.translate(map.lon2coord(node.lon),map.latp2coord(node.latp));
			icon.transform.matrix=m;
		}

	}
}
