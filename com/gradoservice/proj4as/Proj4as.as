package com.gradoservice.proj4as
{
	import com.gradoservice.proj4as.proj.AbstractProjProjection;
	
	public class Proj4as
	{
		
		static public const defaultDatum:String = 'WGS84';
		static public const WGS84:ProjProjection = new ProjProjection('WGS84');

		
		public function Proj4as()
		{
		}
		
		public function transform(source:ProjProjection, dest:ProjProjection, point:ProjPoint):ProjPoint
		{
        	
        	if (source==null || dest==null || point==null)
        	{
        		trace("Parametrs not created!");
        		return null;  
        	}
        	
        	if (!source.readyToUse || !dest.readyToUse) 
        	{
            trace("Proj4js initialization for "+source.srsCode+" not yet complete");
            	return point;
        	}
        
        // Workaround for Spherical Mercator
        if ((source.srsProjNumber =="900913" && dest.datumCode != "WGS84") ||
            (dest.srsProjNumber == "900913" && source.datumCode != "WGS84")) {
            var wgs84:ProjProjection = WGS84;
            this.transform(source, wgs84, point);
            source = wgs84;
        }

        // Transform source points to long/lat, if they aren't already.
        if ( source.projName=="longlat") {
            point.x *= ProjConstants.D2R;  // convert degrees to radians
            point.y *= ProjConstants.D2R;
        } else {
            if (source.to_meter) {
                point.x *= source.to_meter;
                point.y *= source.to_meter;
            }
            source.inverse(point); // Convert Cartesian to longlat
        }

        // Adjust for the prime meridian if necessary
        if (source.from_greenwich) { 
            point.x += source.from_greenwich; 
        }

        // Convert datums if needed, and if possible.
        point = this.datum_transform( source.datum, dest.datum, point );

        // Adjust for the prime meridian if necessary
        if (dest.from_greenwich) {
            point.x -= dest.from_greenwich;
        }

        if( dest.projName=="longlat" ) {             
            // convert radians to decimal degrees
            point.x *= ProjConstants.R2D;
            point.y *= ProjConstants.R2D;
        } else  {               // else project
            dest.forward(point);
            if (dest.to_meter) {
                point.x /= dest.to_meter;
                point.y /= dest.to_meter;
            }
        }
        return point;			
		}
		
		
    public function datum_transform( source:Datum, dest:Datum, point:ProjPoint ):ProjPoint 
    {

      // Short cut if the datums are identical.
      if( source.compare_datums( dest ) ) {
          return point; // in this case, zero is sucess,
                    // whereas cs_compare_datums returns 1 to indicate TRUE
                    // confusing, should fix this
      }

      // Explicitly skip datum transform by setting 'datum=none' as parameter for either source or dest
      if( source.datum_type == ProjConstants.PJD_NODATUM
          || dest.datum_type == ProjConstants.PJD_NODATUM) {
          return point;
      }

      // If this datum requires grid shifts, then apply it to geodetic coordinates.
      if( source.datum_type == ProjConstants.PJD_GRIDSHIFT )
      {
       trace("ERROR: Grid shift transformations are not implemented yet.");
        /*
          pj_apply_gridshift( pj_param(source.params,"snadgrids").s, 0,
                              point_count, point_offset, x, y, z );
          CHECK_RETURN;

          src_a = SRS_WGS84_SEMIMAJOR;
          src_es = 0.006694379990;
        */
      }

      if( dest.datum_type == ProjConstants.PJD_GRIDSHIFT )
      {
        trace("ERROR: Grid shift transformations are not implemented yet.");
        /*
          dst_a = ;
          dst_es = 0.006694379990;
        */
      }

      // Do we need to go through geocentric coordinates?
      if( source.es != dest.es || source.a != dest.a
          || source.datum_type == ProjConstants.PJD_3PARAM
          || source.datum_type == ProjConstants.PJD_7PARAM
          || dest.datum_type == ProjConstants.PJD_3PARAM
          || dest.datum_type == ProjConstants.PJD_7PARAM)
      {

        // Convert to geocentric coordinates.
        source.geodetic_to_geocentric( point );
        // CHECK_RETURN;

        // Convert between datums
        if( source.datum_type == ProjConstants.PJD_3PARAM || source.datum_type == ProjConstants.PJD_7PARAM ) {
          source.geocentric_to_wgs84(point);
          // CHECK_RETURN;
        }

        if( dest.datum_type == ProjConstants.PJD_3PARAM || dest.datum_type == ProjConstants.PJD_7PARAM ) {
          dest.geocentric_from_wgs84(point);
          // CHECK_RETURN;
        }

        // Convert back to geodetic coordinates
        dest.geocentric_to_geodetic( point );
          // CHECK_RETURN;
      }

      // Apply grid shift to destination if required
      if( dest.datum_type == ProjConstants.PJD_GRIDSHIFT )
      {
        trace("ERROR: Grid shift transformations are not implemented yet.");
        // pj_apply_gridshift( pj_param(dest.params,"snadgrids").s, 1, point);
        // CHECK_RETURN;
      }
      return point;
    }		

	}
}