use lib 't';
use strict;
use warnings;


BEGIN { $| = 1;  
	use Test;
	plan tests => 7;
}

use MultiTestDB;
use Bio::EnsEMBL::DBSQL::ArchiveStableIdAdaptor;
use TestUtils qw(test_getter_setter debug);

our $verbose = 0;


#
# 1 ArchiveStableId adaptor compiles
#
ok(1);

my $multi = MultiTestDB->new;
my $db    = $multi->get_DBAdaptor('core');

my $asia = $db->get_ArchiveStableIdAdaptor();

my $asi = $asia->fetch_by_stable_id( "G1" );

_print_asi( $asi );

#
# 2 retrieval of an archiveStableId
#
ok( $asi );

my $pre_asis = $asi->get_all_predecessors();

for my $asi ( @$pre_asis ) {
  debug( "Pre G1" );
  _print_asi( $asi );
}


#
# 3 how many predecessors does it have
#
ok( scalar( @$pre_asis ) == 2 );

my $transcripts = $pre_asis->[0]->get_all_transcript_archive_ids();

for my $asi ( @$transcripts ) {
  debug( "Transcripts G1" );
  _print_asi( $asi );
  
  my $tl = $asi->get_translation_archive_id();
  _print_asi( $tl );
}

#
# 4 transcripts for a gene
#
ok( scalar( @$transcripts ) == 1);



$pre_asis = $pre_asis->[0]->get_all_predecessors();
debug( "Predecessors: ".scalar( @$pre_asis ) );


#
# 5 no predecessor case
#
ok( scalar( @$pre_asis ) == 0 );

$asi = $asia->fetch_by_stable_id_dbname( "G4", "release_1" );
my $succ_asis = $asi->get_all_successors();
 
for my $asi ( @$succ_asis ) {
  debug( "Succ G4.1" );
  _print_asi( $asi );
}

#
# 6 successor case
#
ok( scalar( @$succ_asis ) == 1 );

$succ_asis = $succ_asis->[0]->get_all_successors();

for my $asi ( @$succ_asis ) {
  debug( "Succ Succ G4.1" );
  _print_asi( $asi );
}


#
# 7 no successor case
#

ok( scalar( @$succ_asis ) == 0 );



sub _print_asi {
  my $asi = shift;

  debug( "stable id: ".$asi->stable_id().
	 "\nversion: ".$asi->version().
	 "\ntype: ".$asi->type().
	 "\ndbname: ".$asi->db_name().
	 "\nTranscripts ".($asi->get_all_transcript_archive_ids()||"").
	 "\nTranslation ".($asi->get_translation_archive_id()||"").
	 "\nPeptide ".($asi->get_peptide()||"")."\n" );
}
  
