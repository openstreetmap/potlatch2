/*

The MIT License

Copyright (c) 2007-2008 Ali Rantakari of hasseg.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package net.systemeD.controls {
	
	import flash.events.*;
	import mx.effects.AnimateProperty;
	import mx.events.*;
	import mx.containers.Panel;
	import mx.core.ScrollPolicy;
	
	/**
	* The icon designating a "closed" state
	*/
	[Style(name="closedIcon", property="closedIcon", type="Object")]
	
	/**
	* The icon designating an "open" state
	*/
	[Style(name="openIcon", property="openIcon", type="Object")]
	
	/**
	* This is a Panel that can be collapsed and expanded by clicking on the header.
	* 
	* @author Ali Rantakari
	*/
	public class CollapsiblePanel extends Panel {
		


		private var _creationComplete:Boolean = false;
		private var _open:Boolean = true;
		private var _openAnim:AnimateProperty;
		
		
		
		/**
		* Constructor
		* 
		*/
		public function CollapsiblePanel(aOpen:Boolean = true):void
		{
			super();
			open = aOpen;
			this.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
		}
		
		
		
		
		
		
		
		
		// BEGIN: event handlers				------------------------------------------------------------
		
		private function creationCompleteHandler(event:FlexEvent):void
		{
			this.horizontalScrollPolicy = ScrollPolicy.OFF;
			this.verticalScrollPolicy = ScrollPolicy.OFF;
			
			_openAnim = new AnimateProperty(this);
			_openAnim.duration = 300;
			_openAnim.property = "height";
			
			titleBar.addEventListener(MouseEvent.CLICK, headerClickHandler);
			
			_creationComplete = true;
		}
		
		private function headerClickHandler(event:MouseEvent):void { toggleOpen(); }
		
		private function callUpdateOpenOnCreationComplete(event:FlexEvent):void { updateOpen(); }
		
		// --end--: event handlers			- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		
		
		
		
		
		
		
		
		// BEGIN: private methods				------------------------------------------------------------
		
		// sets the height of the component without animation, based
		// on the _open variable
		private function updateOpen():void
		{
			if (!_open) height = closedHeight;
			else height = openHeight;
			setTitleIcon();
		}
		
		// the height that the component should be when open
		private function get openHeight():Number {
			return measuredHeight;
		}
		
		// the height that the component should be when closed
		private function get closedHeight():Number {
			var hh:Number = getStyle("headerHeight");
			if (hh <= 0 || isNaN(hh)) hh = titleBar.height;
			return hh;
		}
		
		// sets the correct title icon
		private function setTitleIcon():void
		{
			if (!_open) this.titleIcon = getStyle("closedIcon");
			else this.titleIcon = getStyle("openIcon");
		}
		
		// --end--: private methods			- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		
		
		
		
		
		
		
		
		// BEGIN: public methods				------------------------------------------------------------
		
		
		
		/**
		* Collapses / expands this block (with animation)
		*/
		public function toggleOpen():void 
		{
			if (_creationComplete && !_openAnim.isPlaying) {
				
				_openAnim.fromValue = _openAnim.target.height;
				if (!_open) {
					_openAnim.toValue = openHeight;
					_open = true;
					dispatchEvent(new Event(Event.OPEN));
				}else{
					_openAnim.toValue = _openAnim.target.closedHeight;
					_open = false;
					dispatchEvent(new Event(Event.CLOSE));
				}
				setTitleIcon();
				_openAnim.play();
				
			}
			
		}
		
		
		/**
		* Whether the block is in a expanded (open) state or not
		*/
		public function get open():Boolean {
			return _open;
		}
		/**
		* @private
		*/
		public function set open(aValue:Boolean):void {
			_open = aValue;
			if (_creationComplete) updateOpen();
			else this.addEventListener(FlexEvent.CREATION_COMPLETE, callUpdateOpenOnCreationComplete, false, 0, true);
		}
		
		
		/**
		* @private
		*/
		override public function invalidateSize():void {
			super.invalidateSize();
			if (_creationComplete)
				if (_open && !_openAnim.isPlaying) this.height = openHeight;
		}
		
		
		// --end--: public methods			- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		
		
	}

}

