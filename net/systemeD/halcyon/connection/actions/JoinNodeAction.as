package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    public class JoinNodeAction extends CompositeUndoableAction {

      private var node:Node;
      private var nodes:Array;
      private var ways:Array;

      /**
      * For the given node, replace all the given nodes with this node, and insert
      * the given node into the list of ways.
      */
      public function JoinNodeAction(node:Node, nodes:Array, ways:Array) {
          super("Join node "+node.id);
          this.node = node;
          this.nodes = nodes;
          this.ways = ways;
      }

      public override function doAction():uint {

          // don't insert the node into either a way that contains it already,
          // nor a way that contains a dupe we're replacing.
          var avoidWays:Array = node.parentWays;

          for each (var dupe:Node in nodes) {
            for each (var parentWay:Way in dupe.parentWays) {
              avoidWays.push(parentWay);
            }

            dupe.replaceWith(node, push);
          }

          for each (var way:Way in ways) {
            if (avoidWays.indexOf(way) == -1) {
              way.insertNodeAtClosestPosition(node, false, push);
            }
          }
          return super.doAction();
      }

      public override function undoAction():uint {
          return super.undoAction();
      }

    }
}