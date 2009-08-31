package net.systemeD.halcyon.connection {

    public class Way extends Entity {
        private var nodes:Array;
		public static var entity_type:String = 'way';

        public function Way(id:Number, version:uint, tags:Object, nodes:Array) {
            super(id, version, tags);
            this.nodes = nodes;
            for each(var node:Node in nodes)
                node.registerAddedToWay(this);
        }

        public function get length():uint {
            return nodes.length;
        }
        
        public function getNode(index:uint):Node {
            return nodes[index];
        }

        public function insertNode(index:uint, node:Node):void {
            nodes.splice(index, 0, node);
            node.registerAddedToWay(this);
        }

        public function appendNode(node:Node):uint {
            nodes.push(node);
            node.registerAddedToWay(this);
            return nodes.length;
        }

        public function removeNode(index:uint):void {
            var splicedNodes:Array = nodes.splice(index, 1);
            splicedNodes[0].registerRemovedFromWay(this);
        }

        public override function toString():String {
            return "Way("+id+"@"+version+"): "+getTagList()+
                     " "+nodes.map(function(item:Node,index:int, arr:Array):String {return item.id.toString();}).join(",");
        }

		public function isArea():Boolean {
			return (nodes[0].id==nodes[nodes.length-1].id && nodes.length>2);
		}

		public override function getType():String {
			return 'way';
		}
    }

}
