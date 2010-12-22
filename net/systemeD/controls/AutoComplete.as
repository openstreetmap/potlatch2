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
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.listClasses.ListBase;
	import mx.core.UIComponent;
	import mx.events.ListEvent;

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
	 * 
	 *  #includeExample ../../../../../../docs/com/adobe/flex/extras/controls/example/AutoCompleteCountriesData/AutoCompleteCountriesData.mxml
	 *
	 *	@see mx.controls.ComboBox
	 *
	 */
	 // Comment from Steve Bennett: this class is kind of nightmarish because of complicated event sequences, where 
	 // setting one property triggers an event which sets more properties... If someone can get their head around it,
	 // it would be nice to document what are the fundamental properties that should be set, and what sequences of events
	 // cascade out of that. textinput, text, selectedindex...
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
		}
		
		//--------------------------------------------------------------------------
		//	Variables
		//--------------------------------------------------------------------------

		// Tracks cursor position. Because the text field has to be changed so often (to compensate for unwanted changes),
		// and because changing the text field moves the cursor, we need to keep track of where the cursor position should be
		// in order to restore it all the time. (Could be done more gracefully though.)
		private var cursorPosition:Number=0;
		// The previous state of selectedIndex - appears not to be used, though.
		private var prevIndex:Number = -1;
		/** Indicates that at the next UpdateDisplayList, the dropdown will be opened. */
		private var showDropdown:Boolean=false;
		/** Set by UpdateDisplayList, indicates that the dropdown is currently open. */
		private var showingDropdown:Boolean=false;
		private var tempCollection:Object;
		// Very confusing - why is there a dropdownClosed *and* a showingDropdown? They appear to be used by different functions
		// ...but why?
		private var dropdownClosed:Boolean=true;
		// produce spammy UI output
		private var dbg:Boolean = false;

		//--------------------------------------------------------------------------
		//	Overridden Properties
		//--------------------------------------------------------------------------

		/** Hardcoded to set value to true. */
		override public function set editable(value:Boolean):void {
			//This is done to prevent user from resetting the value to false
			super.editable = true;
		}
		/** This whole function is a temporary patch for the bug described inside. */
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

		/** Records text that was actually typed by the user, as distinct from text automatically populated 
		 * from the drop down list. This turns out to be pretty important as the TextInput field constantly
		 * gets populated, unexpectedly.. */ 
		public function set typedText(input:String):void {
			
			if (dbg) trace("set typedText("+input+")");
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

		/** Finds the next field to send focus to when user is done with this one. */
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
					if (dbg) trace ("commitProperties: Move cursor from " + cursorPosition + " to " + textInput.selectionBeginIndex);  
					cursorPosition = textInput.selectionBeginIndex;
					updateDataProvider();

					if( collection.length==0 || typedText=="" || typedText==null ) {
						// no suggestions, so no dropdown
						dropdownClosed=true;
						showDropdown=false;
						showingDropdown=false;
						selectedIndex=-1; //correct state when nothing in dropdown is selected
					} else {
						// show dropdown
						showDropdown = true;
						selectedIndex = 0; // select first item in dropdown
					}
				}
			} else {
				selectedIndex=-1 // There is no list of suggestions at all, so don't select anything in it
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, 
								  unscaledHeight:Number):void {

			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (dbg) trace ("updateDisplayList. textInput.text: " + textInput.text + 
			"; typedText: " + typedText + 
			"; selectedLabel: " + selectedLabel + 
			"; cursorPosition: " + cursorPosition);
			if (dbg) trace("   Showing/show/_dropdown: " + showingDropdown+ ", " + showDropdown +","+ dropdown + ". selectedIndex: " + selectedIndex + ". typedTextChanged: " + typedTextChanged);
			
			if(selectedIndex == -1 && typedTextChanged && textInput.text!=typedText) { 
				// not in menu
				if (dbg) { trace("   not in menu"); trace("- restoring to "+typedText); }
				textInput.text = typedText;
			    textInput.setSelection(cursorPosition, cursorPosition);
				if (dbg) trace("   setSelection: textinput.text.length:" + textInput.text.length);
				//textInput.setSelection(textInput.text.length, textInput.text.length);
				if (dbg) trace ("   Option 1");
			} else if (dropdown && typedTextChanged && textInput.text!=typedText) {
				// "in menu, but user has typed"
				
				if (dbg) { trace("   in menu, but user has typed"); trace("- restoring to "+typedText); }
				textInput.text = typedText;
				textInput.setSelection(cursorPosition, cursorPosition);
                if (dbg) trace ("   Option 2");				
			} else if (showingDropdown && textInput.text==selectedLabel) {
				// "force update if Flex has fucked up again"
				
				// this option happens when user types the last character of an autocomplete match
				// the whole string also gets selected, which is a usability issue (makes it very hard 
				// to keep typing, eg "motorway_link" 
				if (dbg) trace("   should force update");
				textInput.htmlText=selectedLabel;
				textInput.validateNow();
                if (dbg) trace ("   Option 3");				
			} else if (showingDropdown && textInput.text!=selectedLabel && !typedTextChanged) {
				// in menu, user has navigated with cursor keys/mouse
				if (dbg) trace("   in menu, user has navigated with cursor keys/mouse");
				textInput.text = selectedLabel;
				textInput.setSelection(0, textInput.text.length);
                if (dbg) trace ("   Option 4");				
			} else if (textInput.text!="") {
				// This is the most common situation when user is typing and it's not matching. But
				// it's very complicated to predict when this one happens or when option 1. For example,
				// sometimes you type 4 characters (Option 5) then suddenly the next character is option 1.
				if (dbg) trace ("   Option 5, cursorPosition:" + cursorPosition);
				textInput.setSelection(cursorPosition, cursorPosition);
                 				
			} else // occurs while keyboarding up and down menu, maybe also when exiting menu.
			if (dbg) trace ("   Option else");
            if (dbg) trace ("Result. textInput.text: " + textInput.text + 
            "; typedText: " + typedText + 
            "; selectedLabel: " + selectedLabel + 
            "; cursorPosition " + cursorPosition + "\n\n\n");

			if (showDropdown && !dropdown.visible) {
				// controls the open duration of the dropdown
				if (dbg) trace("   (Now open the drop down.)");
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
				// there is a usability issue here if the user is trying to type only part of an entry
				// and there is only one matching item in the dropdown. (eg, they want to type 'foo' but
				// there is 'footway'). It's not a killer because you can still escape by clicking somewhere
				// else, but it's unsettling. Not too common, fortunately.
				if (selectedIndex>-1) { textInput.text = selectedLabel; }
				dropdownClosed=true;
				
				// and move on to the next field
				event.stopImmediatePropagation();
				selectNextField();

			} else if (event.ctrlKey && event.keyCode == Keyboard.UP) {
				// Let the user manually shut the dropdown. fixme: cursor jumps
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
			if (dbg) trace("textInput_changeHandler, text was: " + text);
			super.textInput_changeHandler(event);
			if (dbg) trace("textInput_changeHandler, text is now: " + text + ". Cursor: " + cursorPosition);
			typedText = text;
			typedTextChanged = true;
		}

		override protected function measure():void {
			super.measure();
			measuredWidth = mx.core.UIComponent.DEFAULT_MEASURED_WIDTH;
		}

		override public function set selectedIndex(value:int):void {
			if (dbg) trace ("setSelectedIndex to " + value + ".");
			var prevtext:String=text;
			super.selectedIndex=value;
			if (dbg) trace ("   This made " + prevtext + " become " + text + " (now back again).");
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

		/** An empty filterFunction is allowed but not a null filterFunction*/
		public function set filterFunction(value:Function):void {
			
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

		/** Updates the dataProvider used for showing suggestions*/
		private function updateDataProvider():void {
			if (dbg) trace("updateDataProvider");
			dataProvider = tempCollection;
			collection.filterFunction = templateFilterFunction;
			collection.refresh();
		}
	}	
}
