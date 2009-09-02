package net.systemeD.halcyon.connection {

    public class Way extends Entity {
        private var nodes:Array;
		public static var entity_type:String = 'way';

        public function Way(id:Number, version:uint, tags:Object, nodes:Array) {
            super(id, version, tags);
            this.nodes = nodes;
			for each (var node:Node in nodes) { node.addParent(this); }
        }

        public function get length():uint {
            return nodes.length;
        }
        
        public function getNode(index:uint):Node {
            return nodes[index];
        }

        public function insertNode(index:uint, node:Node):void {
			node.addParent(this);
            nodes.splice(index, 0, node);
        }

        public function appendNode(node:Node):uint {
			node.addParent(this);
            nodes.push(node);
            return nodes.length;
        }

        public function removeNode(index:uint):void {
            var removed:Array=nodes.splice(index, 1);
			removed[0].removeParent(this);
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
