package net.systemeD.potlatch2.controller {
	import flash.events.*;
	
	import net.systemeD.halcyon.AttentionEvent;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.connection.actions.MergeWaysAction;
    

	public class SelectedMultiple extends ControllerState {
		protected var initSelection:Array;
		
		public function SelectedMultiple(sel:Array) {
			initSelection=sel.concat();
		}

		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
			var focus:Entity = getTopLevelFocusEntity(entity);

			if ( event.type == MouseEvent.MOUSE_DOWN && entity && event.ctrlKey ) {
				// modify selection
				controller.map.setHighlight(entity, { selected: toggleSelection(entity) });
				controller.updateSelectionUI();

				if (selectCount>1) { return this; }
				return controller.findStateForSelection(selection);
			}
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
		}

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==74) return mergeWays();	// 'J'
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		public function mergeWays():ControllerState {
			var changed:Boolean;
			var waylist:Array=selectedWays;
			var conflictTags:Object={}; 
			var mergers:uint=0;
			do {
				// ** FIXME - we should have one CompositeUndoableAction for the whole caboodle,
				// but that screws up the execution order and can make the merge not work
				var undo:CompositeUndoableAction = new CompositeUndoableAction("Merge ways");
				changed=tryMerge(waylist, undo);
				if (changed)
				    mergers ++;
                MainUndoStack.getGlobalStack().addAction(undo);
                
                if (MergeWaysAction.lastProblemTags) {
                	for each (var t:String in MergeWaysAction.lastProblemTags) {
                		conflictTags[t]=t;
                	}
                }
            				
			} while (changed==true);

            if (mergers>0) {			                
			    var msg:String = 1 + mergers + " ways merged."
                var conflictTags2:Array = new Array();
                // there must be a better way of avoiding duplicates...
                for each (var conflict:String in conflictTags) conflictTags2.push(conflict);
                if (conflictTags2.length>0)
                    msg += " *Warning* The following tags conflicted and need attention: " + conflictTags2;
                map.connection.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, msg));
            }

			return controller.findStateForSelection(waylist);
		}
		
		private function tryMerge(waylist:Array, undo:CompositeUndoableAction):Boolean {
			var way1:Way, way2:Way, del:uint;
			for (var i:uint=0; i<waylist.length; i++) {
				for (var j:uint=0; j<waylist.length; j++) {
					if (waylist[i]!=waylist[j]) {

						// Preserve positive IDs if we can
						if (waylist[i].id < waylist[j].id && waylist[i].id >= 0) {
							way1=waylist[i]; way2=waylist[j]; del=j;
						} else {
							way1=waylist[j]; way2=waylist[i]; del=i;
						}

						// Merge as appropriate
						if (way1.getNode(0)==way2.getNode(0)) {
							waylist.splice(del,1);
							undo.push(new MergeWaysAction(way1,way2,0,0));
							return true;
						} else if (way1.getNode(0)==way2.getLastNode()) { 
							waylist.splice(del,1);
							undo.push(new MergeWaysAction(way1,way2,0,way2.length-1));
							return true;
						} else if (way1.getLastNode()==way2.getNode(0)) {
							waylist.splice(del,1);
							undo.push(new MergeWaysAction(way1,way2,way1.length-1,0));
							return true;
						} else if (way1.getLastNode()==way2.getLastNode()) { 
							waylist.splice(del,1);
							undo.push(new MergeWaysAction(way1,way2,way1.length-1,way2.length-1));
							return true;
						}
					}
				}
			}
			return false;
		}

		override public function enterState():void {
			selection=initSelection.concat();
			for each (var entity:Entity in selection) {
				controller.map.setHighlight(entity, { selected: true, hover: false });
			}
			controller.updateSelectionUI();
			controller.map.setPurgable(selection,false);
		}

		override public function exitState(newState:ControllerState):void {
			controller.map.setPurgable(selection,true);
			for each (var entity:Entity in selection) {
				controller.map.setHighlight(entity, { selected: false, hover: false });
			}
			selection = [];
			if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
		}

		override public function toString():String {
			return "SelectedMultiple";
		}

	}
}
