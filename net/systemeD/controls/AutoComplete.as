/*
	AutoComplete component
	based on Adobe original but heavily bug-fixed and stripped down
	http://www.adobe.com/cfusion/exchange/index.cfm?event=extensionDetail&extid=1047291
	
	Enhancements to do:
	- up/down when field empty should show everything
	- up (to 0) when dropdown displayed should cause it to reset to previous typed value
	- down (past only item) when dropdown displayed should paste it
	- shouldn't be able to leave empty fields, or those which already exist
*/

package net.systemeD.controls {
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.ui.Keyboard;
	import mx.core.UIComponent;
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.listClasses.ListBase;
	import mx.collections.ArrayCollection;
	import mx.collections.ListCollectionView;
	import mx.events.DropdownEvent;
	import mx.events.ListEvent;
	import mx.events.FlexEvent;
	import mx.managers.IFocusManagerComponent;

	[Event(name="filterFunctionChange", type="flash.events.Event")]
	[Event(name="typedTextChange", type="flash.events.Event")]

	[Exclude(name="editable", kind="property")]

	/**
	 *	The AutoComplete control is an enhanced 
	 *	TextInput control which pops up a list of suggestions 
	 *	based on characters entered by the user. These suggestions
	 *	are to be provided by setting the <code>dataProvider
	 *	</code> property of the control.
	 *	@mxml
	 *
	 *	<p>The <code>&lt;fc:AutoComplete&gt;</code> tag inherits all the tag attributes
	 *	of its superclass, and adds the following tag attributes:</p>
	 *
	 *	<pre>
	 *	&lt;fc:AutoComplete
	 *	  <b>Properties</b>
	 *	  keepLocalHistory="false"
	 *	  typedText=""
	 *	  filterFunction="<i>Internal filter function</i>"
	 *
	 *	  <b>Events</b>
	 *	  filterFunctionChange="<i>No default</i>"
	 *	  typedTextChange="<i>No default</i>"
	 *	/&gt;
	 *	</pre>
	 *
	 *	@includeExample ../../../../../../docs/com/adobe/flex/extras/controls/example/AutoCompleteCountriesData/AutoCompleteCountriesData.mxml
	 *
	 *	@see mx.controls.ComboBox
	 *
	 */
	public class AutoComplete extends ComboBox 
	{

		//--------------------------------------------------------------------------
		//	Constructor
		//--------------------------------------------------------------------------

		public function AutoComplete() {
			super();

			//Make ComboBox look like a normal text field
			editable = true;

			setStyle("arrowButtonWidth",0);
			setStyle("fontWeight","normal");
			setStyle("cornerRadius",0);
			setStyle("paddingLeft",0);
			setStyle("paddingRight",0);
			rowCount = 7;
//			restrict="\u0020-\uFFFF";
		}
		
		//--------------------------------------------------------------------------
		//	Variables
		//--------------------------------------------------------------------------

		private var cursorPosition:Number=0;
		private var prevIndex:Number = -1;
		private var showDropdown:Boolean=false;
		private var showingDropdown:Boolean=false;
		private var tempCollection:Object;
		private var dropdownClosed:Boolean=true;

		//--------------------------------------------------------------------------
		//	Overridden Properties
		//--------------------------------------------------------------------------

		override public function set editable(value:Boolean):void {
			//This is done to prevent user from resetting the value to false
			super.editable = true;
		}
		override public function set dataProvider(value:Object):void {
			super.dataProvider = value;
			tempCollection = value;

			// Big bug in Flex 3.5:
			//  http://www.newtriks.com/?p=935
			//  http://forums.adobe.com/message/2952677
			//  https://bugs.adobe.com/jira/browse/SDK-25567
			//  https://bugs.adobe.com/jira/browse/SDK-25705
			//  http://stackoverflow.com/questions/3006291/adobe-flex-combobox-dataprovider
			// We can remove this workaround if we ever move to Flex 3.6 or Flex 4
			var newDropDown:ListBase = dropdown;
			if(newDropDown) {
				validateSize(true);
				newDropDown.dataProvider = super.dataProvider;

				dropdown.addEventListener(ListEvent.ITEM_CLICK, itemClickHandler, false, 0, true);
			}
		}

		override public function set labelField(value:String):void {
			super.labelField = value;
			invalidateProperties();
			invalidateDisplayList();
		}


		//--------------------------------------------------------------------------
		//	Properties
		//--------------------------------------------------------------------------

		private var _typedText:String="";			// text changed by user
		private var typedTextChanged:Boolean;

		[Bindable("typedTextChange")]
		[Inspectable(category="Data")]
		public function get typedText():String { return _typedText; }

		public function set typedText(input:String):void {
			_typedText = input;
			typedTextChanged = true;
			
			invalidateProperties();
			invalidateDisplayList();
			dispatchEvent(new Event("typedTextChange"));
		}

		//--------------------------------------------------------------------------
		//	New event listener to restore item-click
		//--------------------------------------------------------------------------

		protected function itemClickHandler(event:ListEvent):void {
			typedTextChanged=false;
			textInput.text=itemToLabel(collection[event.rowIndex]);
			selectNextField();
		}

		protected function selectNextField():void {
			if (this.parent.parent is DataGrid) {
				this.parent.parent.dispatchEvent(new FocusEvent("keyFocusChange",true,true,null,false,9));
			} else {
				focusManager.getNextFocusManagerComponent(true).setFocus();
			}
		}

		//--------------------------------------------------------------------------
		//	Overridden methods
		//--------------------------------------------------------------------------

		override protected function commitProperties():void {
			super.commitProperties();

			if (dropdown) {
				if (typedTextChanged) {
					cursorPosition = textInput.selectionBeginIndex;
					updateDataProvider();

					if( collection.length==0 || typedText=="" || typedText==null ) {
						// no suggestions, so no dropdown
						dropdownClosed=true;
						showDropdown=false;
						showingDropdown=false;
					} else {
						// show dropdown
						showDropdown = true;
						selectedIndex = 0;
					}
				}
			} else {
				selectedIndex=-1
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, 
								  unscaledHeight:Number):void {

			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(selectedIndex == -1 && typedTextChanged && textInput.text!=typedText) { 
				// not in menu
				// trace("not in menu"); trace("- restoring to "+typedText);
				textInput.text = typedText;
				textInput.setSelection(textInput.text.length, textInput.text.length);
			} else if (dropdown && typedTextChanged && textInput.text!=typedText) {
				// in menu, but user has typed
				// trace("in menu, but user has typed"); trace("- restoring to "+typedText);
				textInput.text = typedText;
				textInput.setSelection(cursorPosition, cursorPosition);
			} else if (showingDropdown && textInput.text==selectedLabel) {
				// force update if Flex has fucked up again
				// trace("should force update");
				textInput.htmlText=selectedLabel;
				textInput.validateNow();
			} else if (showingDropdown && textInput.text!=selectedLabel && !typedTextChanged) {
				// in menu, user has navigated with cursor keys/mouse
				// trace("in menu, user has navigated with cursor keys/mouse");
				textInput.text = selectedLabel;
				textInput.setSelection(0, textInput.text.length);
			} else if (textInput.text!="") {
				textInput.setSelection(cursorPosition, cursorPosition);
			}

			if (showDropdown && !dropdown.visible) {
				// controls the open duration of the dropdown
				super.open();
				showDropdown = false;
				showingDropdown = true;
				dropdownClosed = false;
			}
		}
	
		override protected function keyDownHandler(event:KeyboardEvent):void {
			super.keyDownHandler(event);

			if (event.keyCode==Keyboard.UP || event.keyCode==Keyboard.DOWN) {
				typedTextChanged=false;
			}

			if (event.keyCode==Keyboard.ESCAPE && showingDropdown) {
				// ESCAPE cancels dropdown
				textInput.text = typedText;
				textInput.setSelection(textInput.text.length, textInput.text.length);
				showingDropdown = false;
				dropdownClosed=true;

			} else if (event.keyCode == Keyboard.ENTER) {
				// ENTER pressed, so select the topmost item (if it exists)
				if (selectedIndex>-1) { textInput.text = selectedLabel; }
				dropdownClosed=true;
				
				// and move on to the next field
				event.stopImmediatePropagation();
				selectNextField();

			} else if (event.ctrlKey && event.keyCode == Keyboard.UP) {
				dropdownClosed=true;
			}
		
			prevIndex = selectedIndex;
		}
	
		override public function getStyle(styleProp:String):* {
			if (styleProp != "openDuration") {
				return super.getStyle(styleProp);
			} else {
				if (dropdownClosed) return super.getStyle(styleProp);
				else return 0;
			}
		}

		override protected function textInput_changeHandler(event:Event):void {
			super.textInput_changeHandler(event);
			typedText = text;
			typedTextChanged = true;
		}

		override protected function measure():void {
			super.measure();
			measuredWidth = mx.core.UIComponent.DEFAULT_MEASURED_WIDTH;
		}

		override public function set selectedIndex(value:int):void {
			var prevtext:String=text;
			super.selectedIndex=value;
			text=prevtext;
		}


		//----------------------------------
		//	filterFunction
		//----------------------------------
		/**
		 *	A function that is used to select items that match the
		 *	function's criteria. 
		 *	A filterFunction is expected to have the following signature:
		 *
		 *	<pre>f(item:~~, text:String):Boolean</pre>
		 *
		 *	where the return value is <code>true</code> if the specified item
		 *	should displayed as a suggestion. 
		 *	Whenever there is a change in text in the AutoComplete control, this 
		 *	filterFunction is run on each item in the <code>dataProvider</code>.
		 *	
		 *	<p>The default implementation for filterFunction works as follows:<br>
		 *	If "AB" has been typed, it will display all the items matching 
		 *	"AB~~" (ABaa, ABcc, abAc etc.).</p>
		 *
		 *	<p>An example usage of a customized filterFunction is when text typed
		 *	is a regular expression and we want to display all the
		 *	items which come in the set.</p>
		 *
		 *	@example
		 *	<pre>
		 *	public function myFilterFunction(item:~~, text:String):Boolean
		 *	{
		 *	   public var regExp:RegExp = new RegExp(text,"");
		 *	   return regExp.test(item);
		 *	}
		 *	</pre>
		 *
		 */

		private var _filterFunction:Function = defaultFilterFunction;
		private var filterFunctionChanged:Boolean = true;

		[Bindable("filterFunctionChange")]
		[Inspectable(category="General")]

		public function get filterFunction():Function {
			return _filterFunction;
		}

		public function set filterFunction(value:Function):void {
			//An empty filterFunction is allowed but not a null filterFunction
			if(value!=null) {
				_filterFunction = value;
				filterFunctionChanged = true;

				invalidateProperties();
				invalidateDisplayList();
	
				dispatchEvent(new Event("filterFunctionChange"));
			} else {
				_filterFunction = defaultFilterFunction;
			}
		}
				
		private function defaultFilterFunction(element:*, text:String):Boolean {
			var label:String = itemToLabel(element);
			return (label.toLowerCase().substring(0,text.length) == text.toLowerCase());
		}

		private function templateFilterFunction(element:*):Boolean {
			var flag:Boolean=false;
			if(filterFunction!=null)
				flag=filterFunction(element,typedText);
			return flag;
		}

		// Updates the dataProvider used for showing suggestions
		private function updateDataProvider():void {
			dataProvider = tempCollection;
			collection.filterFunction = templateFilterFunction;
			collection.refresh();
		}
	}	
}
