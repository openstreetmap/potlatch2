package net.systemeD.halcyon.connection.actions {

    import net.systemeD.halcyon.connection.*;

    /** Action that substitutes one node instead of another, in all the ways and relations that that node is part of. */
    public class ReplaceNodeWithNewAction extends ReplaceNodeAction {

        private var connection:Connection;
        private var lat:Number;
        private var lon:Number;
        private var tags:Object;

        /**
        * @param node The node we're getting rid of
        * @param replacement The node we want to end up with
        */
        public function ReplaceNodeWithNewAction(node:Node, connection:Connection, lat:Number, lon:Number, tags:Object) {
			super(node,null);
            this.connection = connection;
            this.lat = lat;
            this.lon = lon;
            this.tags = tags;
        }

        public override function doAction():uint {
            replacement = connection.createNode(tags,lat,lon,push);
			return super.doAction();
        }

        public override function undoAction():uint {
            return super.undoAction();
        }
    }
}

