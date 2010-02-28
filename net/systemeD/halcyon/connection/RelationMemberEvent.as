package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class RelationMemberEvent extends EntityEvent {
        private var _relation:Relation;
        private var _index:int;

        public function RelationMemberEvent(type:String, member:Entity, relation:Relation, index:int) {
            super(type, member);
            this._relation = relation;
            this._index = index;
        }

        public function get relation():Relation { return _relation; }
        public function get member():Entity { return entity; }
        public function get index():uint { return _index; }

        public override function toString():String {
            return super.toString() + " in "+_relation+" at "+_index;
        }
    }

}

