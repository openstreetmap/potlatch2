package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    /** Action that creates a new node, then replaces an existing one with the new one in all the ways and relations that that node was part of. */
    public class ReplaceNodeWithNewAction extends ReplaceNodeAction {

        private var connection:Connection;
        private var lat:Number;
        private var lon:Number;
        private var tags:Object;

        /**
        * @param node The node we're getting rid of
        * @param connection, lat, lon, tags: Properties to define the new node.
        */
        public function ReplaceNodeWithNewAction(node:Node, connection:Connection, lat:Number, lon:Number, tags:Object) {
			super(node,null);
            this.connection = connection;
            this.lat = lat;
            this.lon = lon;
            this.tags = tags;
        }

        /** Create new node, then as for ReplaceNodeAction.doAction() */
        public override function doAction():uint {
            replacement = connection.createNode(tags,lat,lon,push);
			return super.doAction();
        }
    }
}

