package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.XMLConnection;

    public class SnapshotConnection extends XMLConnection {

        public function SnapshotConnection(cname:String,api:String,policy:String,initparams:Object=null) {
            super(cname,api,policy,initparams);
        }

        /* todo - stuff about marking nodes/ways as complete */

    }
}