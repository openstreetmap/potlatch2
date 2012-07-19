package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.potlatch2.tools.Simplify;

	public class OsmImporter extends Importer {

		public function OsmImporter(connection:Connection, map:Map, callback:Function=null, simplify:Boolean=false, options:Object=null) {
			super(connection,map,callback,simplify,options);
		}

		override protected function doImport():void {
			var action:CompositeUndoableAction = new CompositeUndoableAction("Import OSM "+connection.name);

			var data:XML;
			var oldid:Number;
			var tags:Object;

			var nodemap:Object={};
			var waymap:Object={};
			var relationmap:Object={};

			for (var f:uint=0; f<files.length; f++) {
				var map:XML = new XML(files[f]);
				if (map.name().localName=='osmChange') { map=map.create[0]; }

				for each(data in map.node) {
					oldid = Number(data.@id);
					nodemap[oldid] = connection.createNode(parseTags(data.tag), Number(data.@lat), Number(data.@lon), action.push);
				}

				for each(data in map.way) {
					oldid = Number(data.@id);
					var nodes:Array = [];
					for each(var nd:XML in data.nd) { nodes.push(nodemap[Number(nd.@ref)]); }
					waymap[oldid] = connection.createWay(parseTags(data.tag), nodes, action.push);
				}
            
				for each(data in map.relation) {
					oldid = Number(data.@id);
					var members:Array = [];
					for each(var memberXML:XML in data.member) {
						var type:String = memberXML.@type.toLowerCase();
						var role:String = memberXML.@role;
						var memberID:Number = Number(memberXML.@ref);
						var member:Entity = null;
						switch (memberXML.@type.toLowerCase()) {
							case 'node':		member=nodemap[memberID]; break;
							case 'way':			member=waymap[memberID]; break;
							case 'relation':	break;	// ** TODO - cope with evil nested relations
						}
						if (member!=null) { members.push(new RelationMember(member,role)); }
					}
					relationmap[oldid] = connection.createRelation(parseTags(data.tag), members, action.push);
				}
			}
			action.doAction();
			finish();
        }

        private function parseTags(tagElements:XMLList):Object {
            var tags:Object = {};
            for each (var tagEl:XML in tagElements)
                tags[tagEl.@k] = tagEl.@v.substr(0,255);
            return tags;
        }

	}
}
