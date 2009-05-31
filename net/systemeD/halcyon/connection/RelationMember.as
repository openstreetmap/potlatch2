package net.systemeD.halcyon.connection {

    public class RelationMember {
        private var _entity:Entity;
        private var _role:String;

        public function RelationMember(entity:Entity, role:String) {
            this._entity = entity;
            this._role = role;
        }

        public function get entity():Entity {
            return _entity;
        }

        public function get role():String {
            return _role;
        }
    }

}
