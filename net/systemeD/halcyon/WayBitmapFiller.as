package net.systemeD.halcyon {

	import net.systemeD.halcyon.styleparser.*;
    import net.systemeD.halcyon.connection.*;
	import flash.display.*;
	import flash.events.*;

	public class WayBitmapFiller {
		private var wayui:WayUI;
		private var style:ShapeStyle;
		private var graphics:Graphics;
		private var loader:Loader = new Loader();

		public function WayBitmapFiller(wayui:WayUI,graphics:Graphics,style:ShapeStyle) {
			this.wayui=wayui;
			this.graphics=graphics;
			this.style=style;
			
			if (wayui.paint.ruleset.images[style.fill_image]) {
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedFill);
				loader.loadBytes(wayui.paint.ruleset.images[style.fill_image]);
			}
		}
		
		private function loadedFill(event:Event):void {
			var image:BitmapData = new BitmapData(loader.width, loader.height, false);
			image.draw(loader);
			graphics.beginBitmapFill(image);
			wayui.solidLine(graphics);
			graphics.endFill();
		}
	}
}