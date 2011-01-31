package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;
    
    public class SplitWayAction extends CompositeUndoableAction {
    
        private var selectedWay:Way;
        private var nodeIndex:uint; // Index rather than node required as nodes can occur multiple times
        private var newWay:Way;
    
        public function SplitWayAction(selectedWay:Way, nodeIndex:uint) {
            super("Split way "+selectedWay.id);
            this.selectedWay = selectedWay;
            this.nodeIndex = nodeIndex;
        }
    
        public override function doAction():uint {
            if (newWay==null) {
				newWay = Connection.getConnection().createWay(
					selectedWay.getTagsCopy(), 
					selectedWay.sliceNodes(nodeIndex,selectedWay.length),
					push);

				// we reverse the list, which is already sorted by position. This way positions aren't affected
				// for previous inserts when all the inserts are eventually executed
				for each (var o:Object in selectedWay.memberships.reverse()) {
					// don't add a turn restriction to the relation if it's no longer relevant
					if (o.relation.tagIs('type','restriction')) {
						var vias:Array=o.relation.findMembersByRole('via');
						if (vias.length && vias[0] is Node) {
							if (newWay.indexOfNode(Node(vias[0]))==-1) { 
								continue;
							}
						}
					}

                  // newWay should be added immediately after the selectedWay, unless the setup
                  // is arse-backwards. By that I mean either:
                  // a) The first node (0) of selectedWay is in the subsequentWay, or
                  // b) The last node (N) of selectedWay is in the preceedingWay
                  // Note that the code above means newWay is the tail of selectedWay S-->.-->N
                  // i.e. preceedingWay x--x--x--x                             P-1   ↓
                  //      selectedWay            N<--.<--S<--.<--0             P     ↓ relation members list
                  //      subsequentWay                           x--x--x--x   P+1   ↓
                  // There are some edge cases:
                  // 1) If the immediately adjacent member isn't a way - handled fine
                  // 2) If the selectedWay shares first/last node with non-adjacent ways - phooey
                  
                  var backwards:Boolean = false;
                  // note that backwards is actually a ternary of 'true', 'false', and 'itdoesntmatter' (== 'false')
                  
                  var offset:int = 1; //work from o.position outwards along the length of the relationmembers
                  while ((o.position - offset) >= 0 || (o.position + offset < o.relation.length)) {
                    if ((o.position - offset >= 0) && o.relation.getMember(o.position - offset).entity is Way)  {
                      var preceedingWay:Way = o.relation.getMember(o.position - offset).entity as Way;
                      if(preceedingWay.indexOfNode(selectedWay.getLastNode()) >= 0) {
                        backwards = true;
                      }
                    }
                    if ((o.position + offset < o.relation.length) && o.relation.getMember(o.position + offset).entity is Way) {
                      var subsequentWay:Way = o.relation.getMember(o.position + offset).entity as Way;
                      if(subsequentWay.indexOfNode(selectedWay.getNode(0)) >= 0) {
                        backwards = true;
                      }
                    }
                    offset++;
                  }
                  if (backwards) {
                    o.relation.insertMember(o.position, new RelationMember(newWay, o.role), push); //insert newWay before selectedWay
                  } else {
                    o.relation.insertMember(o.position + 1, new RelationMember(newWay, o.role), push); // insert after
                  }
                }
                
                // now that we're done with the selectedWay, remove the nodes
                selectedWay.deleteNodesFrom(nodeIndex+1, push);

				// and remove from any turn restrictions that aren't relevant
				for each (var r:Relation in selectedWay.findParentRelationsOfType('restriction')) {
					vias=r.findMembersByRole('via');
					if (vias.length && vias[0] is Node) {
						if (selectedWay.indexOfNode(Node(vias[0]))==-1) { 
							r.removeMember(selectedWay,push);
						}
					}
				}

            }
            newWay.suspend();
            selectedWay.suspend();
            super.doAction();
            newWay.resume();
            selectedWay.resume();
            return SUCCESS;
        }
        
        public override function undoAction():uint {
            selectedWay.suspend();
            newWay.suspend();
            
            super.undoAction();
            
            newWay.resume();
            selectedWay.resume();
            return SUCCESS;
        }
    }

}