use lib 't';
use strict;
use warnings;
use vars qw( $verbose );

BEGIN { $| = 1;  
	use Test;
	plan tests => 4;
}

my $loaded = 0;
END {print "not ok 1\n" unless $loaded;}

use MultiTestDB;
use TestUtils qw( debug );

$verbose = 1;
$loaded = 1;

ok(1);

my $multi = MultiTestDB->new();

ok($multi);

my $db = $multi->get_DBAdaptor( "core" );

my $gene = $db->get_GeneAdaptor->fetch_by_transcript_stable_id( "ENST00000217347" );
my $geneid = $gene->stable_id;

$gene = $db->get_GeneAdaptor->fetch_by_Peptide_id( "ENSP00000278995" );
$geneid = $gene->stable_id;

$gene = $db->get_GeneAdaptor()->fetch_by_stable_id( "ENSG00000101321" );

ok( 1);

