package net.systemeD.potlatch2.controller {
	import flash.events.*;
	import flash.display.DisplayObject;
	
	import net.systemeD.halcyon.AttentionEvent;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.connection.actions.MergeWaysAction;
    import net.systemeD.halcyon.MapPaint;

	public class SelectedMultiple extends ControllerState {
		protected var initSelection:Array;
		
		public function SelectedMultiple(sel:Array, layer:MapPaint=null) {
			if (layer) this.layer=layer;
			initSelection=sel.concat();
		}

		override public function processMouseEvent(event:MouseEvent, entity:Entity):ControllerState {
			if (event.type==MouseEvent.MOUSE_MOVE || event.type==MouseEvent.ROLL_OVER || event.type==MouseEvent.MOUSE_OUT) { return this; }
			var paint:MapPaint = getMapPaint(DisplayObject(event.target));
			var focus:Entity = getTopLevelFocusEntity(entity);

			if ( event.type == MouseEvent.MOUSE_DOWN && entity && event.ctrlKey && !event.altKey && paint.interactive ) {
				// modify selection
				layer.setHighlight(entity, { selected: toggleSelection(entity) });
				controller.updateSelectionUI();

				if (selectCount>1) { return this; }
				return controller.findStateForSelection(selection);

			} else if ( event.type == MouseEvent.MOUSE_UP && selection.indexOf(focus)>-1 ) {
				return this;
			}
			var cs:ControllerState = sharedMouseEvents(event, entity);
			return cs ? cs : this;
		}

		override public function processKeyboardEvent(event:KeyboardEvent):ControllerState {
			if (event.keyCode==74) return mergeWays();			// 'J' (join)
			if (event.keyCode==72) return createMultipolygon();	// 'H' (hole)
			var cs:ControllerState = sharedKeyboardEvents(event);
			return cs ? cs : this;
		}
		
		public function mergeWays():ControllerState {
			var changed:Boolean;
			var waylist:Array=selectedWays;
			var tagConflict:Boolean=false; 
			var relationConflict:Boolean=false;
			var mergers:uint=0;
			do {
				// ** FIXME - we should have one CompositeUndoableAction for the whole caboodle,
				// but that screws up the execution order and can make the merge not work
				var undo:CompositeUndoableAction = new CompositeUndoableAction("Merge ways");
				changed=tryMerge(waylist, undo);
				if (changed) mergers++;
				MainUndoStack.getGlobalStack().addAction(undo);
				tagConflict     ||= MergeWaysAction.lastTagsMerged;
				relationConflict||= MergeWaysAction.lastRelationsMerged;

			} while (changed==true);

            if (mergers>0) {			                
			    var msg:String = 1 + mergers + " ways merged";
                if (tagConflict && relationConflict) msg+=": check tags and relations";
                else if (tagConflict) msg+=": check conflicting tags";
                else if (relationConflict) msg+=": check relations";
                controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, msg));
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
		
		/** Create multipolygon from selection, or add to existing multipolygon. */
		
		public function createMultipolygon():ControllerState {
			var inner:Way;
			var multi:Object=multipolygonMembers();
			if (!multi.outer) {
				controller.dispatchEvent(new AttentionEvent(AttentionEvent.ALERT, null, "Couldn't make the multipolygon"));
				return this;
			}

			// If relation exists, add any inners that aren't currently present
			if (multi.relation) {
				var action:CompositeUndoableAction = new CompositeUndoableAction("Add to multipolygon");
				for each (inner in multi.inners) {
					if (!multi.relation.hasMemberInRole(inner,'inner'))
						multi.relation.appendMember(new RelationMember(inner,'inner'),action.push);
				}
				MainUndoStack.getGlobalStack().addAction(action);
				
			// Otherwise, create whole new relation
			} else {
				var memberlist:Array=[new RelationMember(multi.outer,'outer')];
				for each (inner in multi.inners) 
					memberlist.push(new RelationMember(inner,'inner'));
				layer.connection.createRelation( { type: 'multipolygon' }, memberlist, MainUndoStack.getGlobalStack().addAction);
			}

			return new SelectedWay(multi.outer);
		}
		
		override public function enterState():void {
			selection=initSelection.concat();
			for each (var entity:Entity in selection) {
				layer.setHighlight(entity, { selected: true, hover: false });
			}
			controller.updateSelectionUI();
			layer.setPurgable(selection,false);
		}

		override public function exitState(newState:ControllerState):void {
			layer.setPurgable(selection,true);
			for each (var entity:Entity in selection) {
				layer.setHighlight(entity, { selected: false, hover: false });
			}
			selection = [];
			if (!newState.isSelectionState()) { controller.updateSelectionUI(); }
		}

		override public function toString():String {
			return "SelectedMultiple";
		}

	}
}
