package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class MergeWaysAction extends CompositeUndoableAction {
        private var way1:Way;
        private var way2:Way;
        private var toPos:uint;
        private var fromPos:uint;
    
        public function MergeWaysAction(way1:Way, way2:Way, toPos:uint, fromPos:uint) {
            super("Merge ways "+way1.id+" "+way2.id);
            this.way1 = way1;
            this.way2 = way2;
            this.toPos = toPos;
            this.fromPos = fromPos;
        }
        
        public override function doAction():uint {
            // subactions are added to the composite list -- we then
            // execute them all at the bottom. Doing it this way gives
            // us an automatic undo
            super.clearActions();
            way1.suspend();

            mergeRelations();
        	mergeTags();
        	mergeNodes();
			way2.remove(push);

            super.doAction();
			way1.resume();
            
            return SUCCESS;
        }

        public override function undoAction():uint {
            way1.suspend();
            super.undoAction();
            way1.resume();
            
            return SUCCESS;
        }
        
        public function mergeRelations():void {
			for each (var r:Relation in way2.parentRelations) {
				// ** needs to copy roles as well
				if (r.findEntityMemberIndex(way1)==-1) {
					r.appendMember(new RelationMember(way1, ''));
				}
			}
        }
        
        public function mergeTags():void {
        	var way1Tags:Object = way1.getTagsHash();
			var way2Tags:Object = way2.getTagsHash();
			for (var k:String in way2Tags) {
			    var v1:String = way1Tags[k];
			    var v2:String = way2Tags[k];
				if ( v1 && v1 != v2) {
					way1.setTag(k, v1+"; "+v2, push);
					// ** send a warning about tags not matching
				} else {
					way1.setTag(k, v2, push);
				}
			}
        }
        
        public function mergeNodes():void {
            var i:int;
        	if (fromPos==0) {
        	    for (i = 0; i < way2.length; i++)
        	        way1.addToEnd(toPos, way2.getNode(i), push);
        	} else {
        	    for (i = way2.length-1; i >= 0; i--)
        	        way1.addToEnd(toPos, way2.getNode(i), push);
        	}
        }   
    }
}

