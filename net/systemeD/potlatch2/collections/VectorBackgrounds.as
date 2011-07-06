package net.systemeD.potlatch2.collections {

	import flash.events.*
	import flash.net.*
	import flash.system.Security;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.connection.Connection;
	import net.systemeD.halcyon.DebugURLRequest;
	import net.systemeD.potlatch2.utils.*;
		
	public class VectorBackgrounds extends EventDispatcher {

		private static const GLOBAL_INSTANCE:VectorBackgrounds = new VectorBackgrounds();
		public static function instance():VectorBackgrounds { return GLOBAL_INSTANCE; }

		private var _map:Map;


		public function init(map:Map):void {
			_map = map;
			var request:DebugURLRequest = new DebugURLRequest("vectors.xml");
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onConfigLoad);
			loader.load(request.request);
		}

		public function onConfigLoad(e:Event):void {
			var xml:XML = XML(e.target.data);

			// reconstitute results as Array, as we can't run .forEach over an XMLList
			var sets:Array = [];
			for each (var set:XML in xml.set) { sets.push(set); }
			
			// use .forEach to avoid closure problem (http://stackoverflow.com/questions/422784/how-to-fix-closure-problem-in-actionscript-3-as3#3971784)
			sets.forEach(function(set:XML, index:int, array:Array):void {

				if (!(set.policyfile == undefined)) {
					Security.loadPolicyFile(String(set.policyfile));
				}

                // Check for any bounds for the vector layer. Obviously won't kick in during subsequent panning
                var validBbox:Boolean = false;
                if (set.@minlon && String(set.@minlon) != '') {
                    if (((_map.edge_l>set.@minlon && _map.edge_l<set.@maxlon) ||
                         (_map.edge_r>set.@minlon && _map.edge_r<set.@maxlon) ||
                         (_map.edge_l<set.@minlon && _map.edge_r>set.@maxlon)) &&
                        ((_map.edge_b>set.@minlat && _map.edge_b<set.@maxlat) ||
                         (_map.edge_t>set.@minlat && _map.edge_t<set.@maxlat) ||
                         (_map.edge_b<set.@minlat && _map.edge_t>set.@maxlat))) {
                        validBbox = true;
                    } else {
                        validBbox = false; // out of bounds
                    }
                } else {
                    validBbox = true; // global set
                }

				if (set.@disabled == "true") {
                    // Don't do anything with it. The "disabled" attribute allows examples to appear in the config file
				} else if (validBbox) {

					var name:String = (set.name == undefined) ? null : String(set.name);
					var loader:String = set.loader;
					switch (loader) {
						case "TrackLoader":
							break;
						case "KMLImporter":
							break;
						case "GPXImporter":
							if (set.url) {
								if (set.@loaded == "true") {
									name ||= 'GPX file';
									var gpx_url:String = String(set.url);

									var connection:Connection = new Connection(name, gpx_url, null, null);
									var gpx:GpxImporter=new GpxImporter(connection, _map, [gpx_url],
									function(success:Boolean,message:String=null):void {
										if (!success) return;
										var paint:MapPaint = _map.addLayer(connection, "stylesheets/gpx.css");
										paint.updateEntityUIs(false, false);
										dispatchEvent(new Event("layers_changed"));
									}, false);
								} else {
								trace("configured but not loaded isn't supported yet");
								}
							} else {
								trace("AutoVectorBackground: no url for GPXImporter");
							}
							break;

						case "BugLoader":
							if (set.url && set.apiKey) {
								name ||= 'Bugs';
								var bugLoader:BugLoader = new BugLoader(_map, String(set.url), String(set.apikey), name, String(set.details));
								if (set.@loaded == "true") {
									bugLoader.load();
								}
							} else {
								trace("AutoVectorBackground: error with BugLoader");
							}
							break;

						case "BikeShopLoader":
							if (set.url) {
								name ||= 'Missing Bike Shops'
								var bikeShopLoader:BikeShopLoader = new BikeShopLoader(_map, String(set.url), name);
								if (set.@loaded == "true") {
									bikeShopLoader.load();
								}
							} else {
								trace("AutoVectorBackground: no url for BikeShopLoader");
							}
							break;

						case "SnapshotLoader":
							if (set.url) {
								name ||= 'Snapshot Server'
								var snapshotLoader:SnapshotLoader = new SnapshotLoader(_map, String(set.url), name, String(set.style));
								if (set.@loaded == "true") {
									snapshotLoader.load();
								}
							} else {
								trace("VectorBackground: no url for SnapshotLoader");
							}
							break;

						default:
							trace("AutoVectorBackground: unknown loader");
					}
				}
			});
		}
	}
}
