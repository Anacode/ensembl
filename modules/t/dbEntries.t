use lib 't';
use strict;
use warnings;

BEGIN { $| = 1;  
	use Test;
	plan tests => 9;
}

use MultiTestDB;
use TestUtils qw ( debug test_getter_setter );

use Bio::EnsEMBL::DBEntry;

# switch on the debug prints

our $verbose = 1;

debug( "Startup test" );
#
# 1 Test started
#
ok(1);

my $multi = MultiTestDB->new();

my $db = $multi->get_DBAdaptor( "core" );

debug( "Test database instatiated" );

#
# 2 Database instatiated
#
ok( $db );


# some retrievals
my $dbEntryAdaptor = $db->get_DBEntryAdaptor();


my $sth = $db->prepare( 'select count(*) from object_xref where ensembl_object_type = "Translation"' );
$sth->execute();

my ( $xref_count )  = $sth->fetchrow_array();
my $db_entry_count = 0;
my $goxref_count = 0;
my $ident_count = 0;

$sth->finish();

my $ga = $db->get_GeneAdaptor();

my $all_gene_ids = $ga->list_geneIds();
for my $gene_id ( @$all_gene_ids ) {
  my $gene = $ga->fetch_by_dbID( $gene_id );

  for my $tr ( @{$gene->get_all_Transcripts()} ) {
    my $tl = $tr->translation();
    my $dbentries = $dbEntryAdaptor->fetch_all_by_Translation( $tl );
    $db_entry_count += scalar( @{$dbentries});
    $goxref_count += grep { $_->isa( "Bio::EnsEMBL::GoXref" )} @$dbentries;
    $ident_count += grep {$_->isa( "Bio::EnsEMBL::IdentityXref" )} @$dbentries;
  }
}

debug( "Found $xref_count xrefs and $db_entry_count dblinks." );
debug( " $goxref_count GoXrefs, $ident_count identityXrefs." );

#
# 3 as many dblinks as entries in object_xref
#
ok( $db_entry_count == $xref_count );

#
# 4,5 correct number of GoXrefs and IdentityXrefs
#
ok( $goxref_count == 48 );
ok( $ident_count == 32 );


# try storing and retrieval

my $xref = Bio::EnsEMBL::DBEntry->new
  (
   -primary_id => "1",
   -dbname => "SWISSPROT",
   -release => "1",
   -display_id => "Ens related thing"
   );


my %goxref = %$xref;
my %identxref = %$xref;

my $goref = Bio::EnsEMBL::GoXref->new
  (
   -primary_id => "1",
   -dbname => "GO",
   -release => "1",
   -display_id => "Ens related GO"
   );
$goref->linkage_type( "experimental" );

my $ident_xref = Bio::EnsEMBL::IdentityXref->new
  (
   -primary_id => "1",
   -dbname => "SPTREMBL",
   -release => "1",
   -display_id => "Ens related Ident"
   );

$ident_xref->query_identity( 100 );
$ident_xref->target_identity( 95 );


$multi->hide( "core", "object_xref", "xref", "identity_xref", "go_xref" );


my $gene = $ga->fetch_by_dbID( $all_gene_ids->[0] );
my $tr = $gene->get_all_Transcripts()->[0];
my $tl = $tr->translation();



$dbEntryAdaptor->store( $xref, $gene, "Gene" );
$dbEntryAdaptor->store( $xref, $tr, "Transcript" );
$dbEntryAdaptor->store( $goref, $tl, "Translation" );
$dbEntryAdaptor->store( $ident_xref, $tl, "Translation" );
$dbEntryAdaptor->store( $ident_xref, $tr, "Transcript" );

my ( $oxr_count, $go_count );

$sth = $db->prepare( "select count(*) from object_xref" );
$sth->execute();

( $oxr_count ) = $sth->fetchrow_array();
$sth->finish();

#
# 6 right number of object xrefs in db
#
debug( "object_xref_count = $oxr_count" );
ok( $oxr_count == 5 );


$sth = $db->prepare( "select count(*) from xref" );
$sth->execute();

( $xref_count ) = $sth->fetchrow_array();
$sth->finish();

#
# 7 number of xrefs right
#
debug( "Number of xrefs = $xref_count" );
ok( $xref_count == 3 );

$sth = $db->prepare( "select count(*) from go_xref" );
$sth->execute();

( $go_count ) = $sth->fetchrow_array();
$sth->finish();

#
# 8 number of go entries right
#
debug( "Number of go_xrefs = $go_count" );
ok( $go_count == 1 );

$sth = $db->prepare( "select count(*) from identity_xref" );
$sth->execute();

( $ident_count ) = $sth->fetchrow_array();
$sth->finish();


#
# 9 identity xrefs right
#

# the identity (query/target)values are not normalized ...
debug( "Number of identity_xrefs = $ident_count" );
ok( $ident_count == 2 );


#
# Need more tests here ...
#


$multi->restore();
