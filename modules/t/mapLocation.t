use lib 't';
use strict;

BEGIN { $| = 1;  
	use Test ;
	plan tests => 11
}

use Bio::EnsEMBL::Map::MapLocation;
use Bio::EnsEMBL::Chromosome;
use MultiTestDB;
use TestUtils qw(debug test_getter_setter);

our $verbose = 0; #set to 1 to turn on debug printouts


my $multi = MultiTestDB->new();
my $db = $multi->get_DBAdaptor( 'core' );


######
# 1  #
######

#test constructor
my $mapname = 'genethon';
my $name = 'DS1234';
my $chr = $db->get_ChromosomeAdaptor->fetch_by_chr_name('X');
my $pos = '12.5';
my $lod = 0.23;

my $mloc = 
  Bio::EnsEMBL::Map::MapLocation->new($name, $mapname, $chr, $pos, $lod);

ok($mloc && ref $mloc && $mloc->isa('Bio::EnsEMBL::Map::MapLocation'));



#######
# 2-3 #
#######

#test map_name

ok($mapname eq $mloc->map_name);
ok(&test_getter_setter($mloc, 'map_name', 'marshfield'));

#######
# 4-5 #
#######

#test chromosome
ok($chr == $mloc->chromosome);
ok(&test_getter_setter($mloc, 'chromosome', undef));

#######
# 6-7 #
#######

#test name
ok($name eq $mloc->name);
ok(&test_getter_setter($mloc, 'name', 'Z123213')); 


#######
# 8-9 #
#######

#test position
ok($pos eq $mloc->position);
ok(&test_getter_setter($mloc, 'position', 'q13.1'));

########
# 10-11#
########

#test lod_score

ok($lod == $mloc->lod_score);
ok(&test_getter_setter($mloc, 'lod_score', 0.03 ));


