package net.systemeD.controls {
	import flexlib.controls.PromptingTextInput;
	import flash.display.DisplayObject;
	import mx.controls.Image;

	public class PromptingTextInputWarning extends PromptingTextInput {

		private var _image:Image;
		[Embed(source="../../../embedded/warning.png")] private var warningIcon:Class;

		function PromptingTextInputWarning():void {
			super();
		}

		override protected function createChildren():void {
			super.createChildren();
			_image = new Image();
			_image.source = warningIcon;
			_image.width = 16;
			_image.height = 16;
			addChild(DisplayObject(_image));
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (text && text.indexOf(';')>-1) {
				setStyle('color',0xFF0000);
				_image.visible=true;
				_image.x = width -_image.width -5;
				_image.y = height-_image.height-3;
				_image.toolTip = "The tag contains more than one value - please check";
				textField.width = width-_image.width-5;
			} else {
				setStyle('color',0);
				_image.visible=false;
			}
		}
	}
}
