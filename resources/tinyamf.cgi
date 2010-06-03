#!/usr/bin/perl -w

	# ----------------------
	# Tiny AMF read-only API
	# Richard Fairhurst 2010
	# richard@systemeD.net
	
	# This is the simplest possible server for Halcyon (Flash vector map
	# renderer) to read from an OpenStreetMap database - populated by
	# Osmosis, for example. It has no dependencies other than DBI. It
	# expects to run on Apache or another server that populates the
	# CONTENT_LENGTH environment variable.
	#
	# The database should have the current_ tables populated, and be
	# consistent with a changeset and user table containing at least one
	# entry each. Edit the DBI->connect line to contain the connection
	# details for your database.
	#
	# Configure Halcyon's connection like this:
	#   fo.addVariable("api","tinyamf.cgi?");
	#   fo.addVariable("connection","AMF");
	#
	# Note the question mark at the end of tinyamf.cgi.
	#
	# Questions? Patches? Please subscribe to the potlatch-dev mailing 
	# list at lists.openstreetmap.org and ask there.

	# With thanks to Musicman (AMF) and Tom Hughes (quadtiles) from whose
	# PHP and Ruby code some of this is adapted.
	
	# The following globals are maintained throughout the program:
	#	$d		 - input file
	#	$offset	 - position in input file
	#	$result	 - response file
	#	$results - number of responses
	#	$dbh	 - database handle
	#	$ppc	 - PowerPC or Intel byte-order
	
	use DBI;
	$dbh=DBI->connect('DBI:mysql:openstreetmap','openstreetmap','openstreetmap', { RaiseError =>1 } ); 
	$"=',';
	
	# -----	Get data
	
	$l=$ENV{'CONTENT_LENGTH'};
	read (STDIN, $d, $l);

	$tmp=pack("d", 1); $ppc=0;
	if	  ($tmp eq "\0\0\0\0\0\0\360\77") { $ppc=0; }
	elsif ($tmp eq "\77\360\0\0\0\0\0\0") { $ppc=1; }
	else { die "Unknown byte order\n"; }

	# -----	Read headers
	
	%headers=();
	$offset=3;
	$hc=ord(substr($d,$offset++,1));
	while (--$hc>=0) {
		$key=getstr($d, $offset);
		$offset++;
		$lo=getlength($d, $offset);	# not used
		$ch=ord(substr($d,$offset++,1));
		$val=parseitem($ch, $offset);
		$headers{$key}=$val;
	}

	# -----	Read calls
	
	$result=''; $results=0;
	$offset+=2;
	while ($offset<$l) {

		# -	Get call name
		$fn=getstr($d, $offset);

		# -	Get number in sequence
		$seq=substr(getstr($d, $offset),1);
		$lo=getlength($d, $offset);	# length of all params? not used

		# -	Get all parameters (sent as an array, hence the '10')
		@params=();
		$ch=ord(substr($d,$offset++,1)); if ($ch!=10) { print "Error - expecting array"; }
		$lo=getlength($d, $offset);
		for ($ni=0; $ni<$lo; $ni++) {
			$ch=ord(substr($d,$offset++,1));
			$p=parseitem($ch, $offset);
			push (@params,$p);
		}

		if ($fn eq 'whichways') { addresult($seq,whichways(@params)); }
		elsif ($fn eq 'getway') { addresult($seq,getway(@params)); }
		elsif ($fn eq 'getrelation') { addresult($seq,getrelation(@params)); }
		
	}

	# -----	Write response

	$dbh->disconnect();

	print "Content-type: application/x-amf\n\n";
	print "\0\0\0\0";
	print pack("n",$results);
	print $result;
	

	# ====================================================================================
	# whichways

	sub whichways {
		my ($query,$query2,$sql,$id,$lat,$lon,$v,$k,$vv);
		my ($xmin,$ymin,$xmax,$ymax)=@_;
		my $enlarge = ($xmax-$xmin)/8; if ($enlarge<0.01) { $enlarge=0.01; }
		$xmin -= $enlarge; $ymin -= $enlarge;
		$xmax += $enlarge; $ymax += $enlarge;
		my $sqlarea=sql_for_area($ymin,$xmin,$ymax,$xmax,'current_nodes.');

		# -	Ways in area

		$sql=<<EOF;
    SELECT DISTINCT current_ways.id AS wayid,current_ways.version AS version
               FROM current_way_nodes
         INNER JOIN current_nodes ON current_nodes.id=current_way_nodes.node_id
         INNER JOIN current_ways  ON current_ways.id =current_way_nodes.id
              WHERE current_nodes.visible=TRUE 
                AND current_ways.visible=TRUE 
                AND $sqlarea
EOF
		$query=$dbh->prepare($sql); $query->execute();
		my $ways=(); my @wayids=();
		while (($id,$v)=$query->fetchrow_array()) { push (@ways,[$id,$v]); push (@wayids,$id); }
		$query->finish();
		
		# - POIs in area
		
		$sql=<<EOF;
          SELECT current_nodes.id,current_nodes.latitude*0.0000001 AS lat,current_nodes.longitude*0.0000001 AS lon,current_nodes.version 
            FROM current_nodes 
 LEFT OUTER JOIN current_way_nodes cwn ON cwn.node_id=current_nodes.id 
           WHERE current_nodes.visible=TRUE
             AND cwn.id IS NULL
             AND $sqlarea
EOF
		$query=$dbh->prepare($sql); $query->execute();
		my @pois=();
		while (($id,$lat,$lon,$v)=$query->fetchrow_array()) {
			my %tags=();
			$query2=$dbh->prepare("SELECT k,v FROM current_node_tags WHERE id=?");
			$query2->execute($id); while (($k,$vv)=$query2->fetchrow_array()) { $tags{$k}=$vv; }
			$query2->finish();
			push (@pois,[$id,$lon,$lat,{%tags},$v]);
		}
		$query->finish();
		
		# - Relations in area

		$sql=<<EOF;
SELECT DISTINCT cr.id AS relid,cr.version AS version 
           FROM current_relations cr
     INNER JOIN current_relation_members crm ON crm.id=cr.id 
     INNER JOIN current_nodes ON crm.member_id=current_nodes.id AND crm.member_type='Node' 
          WHERE $sqlarea
EOF
		unless ($#wayids) {
			$sql.=<<EOF;
          UNION 
SELECT DISTINCT cr.id AS relid,cr.version AS version
           FROM current_relations cr
     INNER JOIN current_relation_members crm ON crm.id=cr.id
          WHERE crm.member_type='Way' 
            AND crm.member_id IN (@wayids)
EOF
		}
		$query=$dbh->prepare($sql); $query->execute();
		my @rels=();
		while (($id,$v)=$query->fetchrow_array()) { push (@rels,[$id,$v]); }
		$query->finish();

		return [0,'',[@ways],[@pois],[@rels]];
	}

	# ====================================================================================
	# getway

	sub getway {
		my $wayid=$_[0];
		my ($sql,$query,$lat,$lon,$id,$v,$k,$vv,$uid,%tags);
		$sql=<<EOF;
   SELECT latitude*0.0000001 AS lat,longitude*0.0000001 AS lon,current_nodes.id,current_nodes.version 
     FROM current_way_nodes,current_nodes 
    WHERE current_way_nodes.id=?
      AND current_way_nodes.node_id=current_nodes.id 
      AND current_nodes.visible=TRUE
 ORDER BY sequence_id
EOF
		$query=$dbh->prepare($sql); $query->execute($wayid);
		my @points=();
		while (($lat,$lon,$id,$v)=$query->fetchrow_array()) {
			%tags=();
			$query2=$dbh->prepare("SELECT k,v FROM current_node_tags WHERE id=?");
			$query2->execute($id); while (($k,$vv)=$query2->fetchrow_array()) { $tags{$k}=$vv; }
			$query2->finish();
			push (@points,[$lon,$lat,$id,{%tags},$v]);
		}
		$query->finish();
		
		$query=$dbh->prepare("SELECT k,v FROM current_way_tags WHERE id=?"); $query->execute($wayid);
		%tags=();
		while (($k,$vv)=$query->fetchrow_array()) { $tags{$k}=$vv; }
		$query->finish();
		
		$query=$dbh->prepare("SELECT version FROM current_ways WHERE id=?"); $query->execute($wayid);
		$v=$query->fetchrow_array();
		$query->finish();
		
		$query=$dbh->prepare("SELECT user_id FROM current_ways,changesets WHERE current_ways.id=? AND current_ways.changeset_id=changesets.id"); $query->execute($wayid);
		$uid=$query->fetchrow_array();
		$query->finish();

		return [0, '', $wayid, [@points], {%tags}, $v, $uid];
	}

	# ====================================================================================
	# getrelation
	
	sub getrelation {
		my $relid=$_[0];
		my ($sql,$query,$v,$k,$vv,$type,$id,$role);

		$query=$dbh->prepare("SELECT member_type,member_id,member_role FROM current_relation_members,current_relations WHERE current_relations.id=? AND current_relation_members.id=current_relations.id ORDER BY sequence_id");
		$query->execute($relid);
		my @members=();
		while (($type,$id,$role)=$query->fetchrow_array()) { push(@members,[ucfirst $type,$id,$role]); }
		$query->finish();

		$query=$dbh->prepare("SELECT k,v FROM current_relation_tags WHERE id=?"); $query->execute($relid);
		my %tags=();
		while (($k,$vv)=$query->fetchrow_array()) { $tags{$k}=$vv; }
		$query->finish();
		
		$query=$dbh->prepare("SELECT version FROM current_relations WHERE id=?"); $query->execute($relid);
		$v=$query->fetchrow_array();
		$query->finish();
		
		return [0, '', $relid, {%tags}, [@members], $v];
	}


	# ====================================================================================
	# AMF decoding routines

	# returns object of unknown type
	sub parseitem {
		my $ch=$_[0];

		if    ($ch==0) { return getnumber(); }					# number
		elsif ($ch==1) { return ord(subtr($d,$offset++,1)); }	# boolean
		elsif ($ch==2) { return getstr(); }						# string
		elsif ($ch==3) { return getobj(); }						# object
		elsif ($ch==5) { return undef; }						# null
		elsif ($ch==6) { return undef; }						# undefined
		elsif ($ch==8) { return getmixed(); }					# mixedArray
		elsif ($ch==10){ return getarray(); }					# array

		print "Didn't recognise type $ch\n";
	}

	sub getstr {       
		my $hi=ord(substr($d,$offset++,1));
		my $lo=ord(substr($d,$offset++,1))+256*$hi;
		my $val=substr($d,$offset,$lo);
		$offset+=$lo;
		return $val;
	}


	sub getnumber {       
		my $ibf='';
		if ($ppc) { $ibf=substr($d,$offset,8); }
		     else { for (my $nc=7; $nc>=0; $nc--) { $ibf.=substr($d,$offset+$nc,1); } }
		$offset+=8;
		return unpack("d", $ibf);
	}

	sub getobj {
		my %ret=();
		my ($key,$ch);
		while($key=getstr()) {
			$ch=ord(substr($d,$offset++,1));
			$ret{$key}=parseitem($ch);
		}
		$ch=ord(substr($d,$offset++,1));
		if ($ch!=9) { print "Unexpected object end: $ch"; }
		return $ret;
	}

	sub getmixed {
		my $lo=getlength();
		return getobj();
	}

	sub getarray {
		my @ret=();
		my $lo=getlength();
		for (my $ni=0; $ni<$lo; $ni++) {
			my $ch=ord(substr($d,$offset++,1));
			push (@ret,parseitem($ch));
		}
		return $ret;
	}


	# ====================================================================================
	# AMF encoding routines

	# $data is object of unknown type
	sub addresult {
		my $seq=$_[0]; my $data=$_[1];
		$results++;
		$result.=sendstr("/$seq/onResult").sendstr("null").pack("N",-1).sendobj($data);
	}

	# $ref is a reference to an object of unknown type
	sub sendobj {
		my $ref=$_[0];
		my $type=ref $ref;
		my ($key,$first,$n);

		if ($type eq 'ARRAY') {
			# Send as array (code 10)
			my @arr=@{$ref};
			my $ret="\12".pack("N",$#arr+1);
			for ($n=0; $n<=$#arr; $n++) { $ret.=sendobj($arr[$n]); }
			return $ret;

		} elsif ($type eq 'HASH') {
			# Send as object (code 3)
			my %hash=%{$ref};
			my $ret="\3";
			foreach $key (keys %hash) { $ret.=sendstr($key).sendobj($hash{$key}); }
			return $ret.sendstr('')."\11";

		} elsif ($ref=~/^[+\-]?[\d\.]+$/) {
			# Send as number (code 0)
			return "\0" . sendnum($ref);

		} elsif ($ref) {
			# Send as string (code 2)
			return "\2" . sendstr($ref);

		} else {
			# Send as undefined
			return "\6";
		}

	}

	sub sendstr {
		my $b=$_[0];
		return pack("n", length($b)).$b;
	}

	sub sendnum {
		my $b=pack("d", $_[0]);
		if ($ppc) { return $b; }
		my $r=''; for (my $n=7; $n>=0; $n--) { $r.=substr($b,$n,1); }
		return $r;
	}

	sub getlength {
		my $b=0;
		for (my $c=0; $c<4; $c++) {
			$b*=256;
			$b+=ord(substr($d,$offset++,1));
		}
		return $b;
	}

	# ================================================================
	# OSM quadtile routines
	# based on original Ruby code by Tom Hughes

	sub tile_for_point {
		my $lat=$_[0]; my $lon=$_[1];
		return tile_for_xy(round(($lon+180)*65535/360),round(($lat+90)*65535/180));
	}
	
	sub round {
		return int($_[0] + .5 * ($_[0] <=> 0));
	}
	
	sub tiles_for_area {
		my $minlat=$_[0]; my $minlon=$_[1];
		my $maxlat=$_[2]; my $maxlon=$_[3];
	
		$minx=round(($minlon + 180) * 65535 / 360);
		$maxx=round(($maxlon + 180) * 65535 / 360);
		$miny=round(($minlat + 90 ) * 65535 / 180);
		$maxy=round(($maxlat + 90 ) * 65535 / 180);
		@tiles=();
	
		for ($x=$minx; $x<=$maxx; $x++) {
			for ($y=$miny; $y<=$maxy; $y++) {
				push(@tiles,tile_for_xy($x,$y));
			}
		}
		return @tiles;
	}
	
	sub tile_for_xy {
		my $x=$_[0];
		my $y=$_[1];
		my $t=0;
		my $i;
		
		for ($i=0; $i<16; $i++) {
			$t=$t<<1;
			unless (($x & 0x8000)==0) { $t=$t | 1; }
			$x<<=1;
	
			$t=$t<< 1;
			unless (($y & 0x8000)==0) { $t=$t | 1; }
			$y<<=1;
		}
		return $t;
	}
	
	sub sql_for_area {
		my $minlat=$_[0]; my $minlon=$_[1];
		my $maxlat=$_[2]; my $maxlon=$_[3];
		my $prefix=$_[4];
		my @tiles=tiles_for_area($minlat,$minlon,$maxlat,$maxlon);
	
		my @singles=();
		my $sql='';
		my $tile;
		my $last=-2;
		my @run=();
		my $rl;
		
		foreach $tile (sort @tiles) {
			if ($tile==$last+1) {
				# part of a run, so keep going
				push (@run,$tile); 
			} else {
				# end of a run
				$rl=@run;
				if ($rl<3) { push (@singles,@run); }
					  else { $sql.="${prefix}tile BETWEEN ".$run[0].' AND '.$run[$rl-1]." OR "; }
				@run=();
				push (@run,$tile); 
			}
			$last=$tile;
		}
		$rl=@run;
		if ($rl<3) { push (@singles,@run); }
			  else { $sql.="${prefix}tile BETWEEN ".$run[0].' AND '.$run[$rl-1]." OR "; }
		if ($#singles>-1) { $sql.="${prefix}tile IN (".join(',',@singles).') '; }
		$sql=~s/ OR $//;
		return $sql;
	}
