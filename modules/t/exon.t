use lib 't';
use strict;

BEGIN { $| = 1;  
	use Test ;
	plan tests => 18;
}

my $loaded = 0;
END {print "not ok 1\n" unless $loaded;}

use MultiTestDB;
use TestUtils qw(debug test_getter_setter);

our $verbose = 0; #set to 1 to turn on debug printouts

$loaded = 1;
my $multi = MultiTestDB->new();

ok(1);

my $db = $multi->get_DBAdaptor( 'core' );

ok($db);


# Exon specific tests

my $exonad = $db->get_ExonAdaptor();
my $rca = $db->get_RawContigAdaptor();

my $contig = $rca->fetch_by_dbID( 469270 );
ok($exonad);

my $exon = Bio::EnsEMBL::Exon->new();


$exon->start(31_200);
ok(&test_getter_setter($exon, 'start', 200));

$exon->end(31_400);
ok(&test_getter_setter($exon, 'end', 400));

$exon->strand(1);
ok(&test_getter_setter($exon, 'strand', -1));

$exon->phase(0);
ok(&test_getter_setter($exon, 'phase', -1));

$exon->contig( $contig );
ok(&test_getter_setter($exon, 'contig', $contig));

# should try to store (!)
$exon->end_phase( -1 );
ok(&test_getter_setter($exon, 'end_phase', 1));


#
# find supporting evidence for the exon
#
my @evidence = ();
my @fs = ();
push @fs, @{$db->get_DnaAlignFeatureAdaptor->fetch_all_by_RawContig($contig)};
push @fs, @{$db->get_ProteinAlignFeatureAdaptor->fetch_all_by_RawContig($contig)};

while(my $f = shift @fs) {
  #debug("feature at: " . $f->start . "-" . $f->end);
  next if $f->start > $exon->end || $f->end < $exon->start;
  push(@evidence, $f);
}

my $count = scalar(@evidence);
debug("adding $count supporting features");
$exon->add_supporting_features(@evidence);

$multi->hide( "core", "exon", "supporting_feature", 
	      "protein_align_feature", "dna_align_feature");

$exonad->store($exon);

ok($exon->dbID() == 1 && $exon->adaptor == $exonad);

# now test fetch_by_dbID

my $newexon = $exonad->fetch_by_dbID($exon->dbID);

ok($newexon);


#
# Test transform to empty Slice
#
my $slice = new Bio::EnsEMBL::Slice(-empty => 1, 
				    -adaptor => $db->get_SliceAdaptor);
$exon = $newexon->transform($slice);

debug("exon chr start  = " . $exon->start);
debug("exon chr end    = " . $exon->end);
debug("exon chr strand = " . $exon->strand); 
ok($exon->start == 30_961_059 && $exon->end == 30_961_259 && $exon->strand==1);


#
# Test transform to another slice
#
$slice = $db->get_SliceAdaptor->fetch_by_chr_start_end($slice->chr_name,
						   $exon->start - 10,
						   $exon->end + 10);
$exon = $exon->transform($slice);
debug("exon chr start  = " . $exon->start);
debug("exon chr end    = " . $exon->end);
debug("exon chr strand = " . $exon->strand); 
ok($exon->start == 11 && $exon->end == 211 && $exon->strand==1);


#
# Test Transform back to Raw Contig
#
$exon = $exon->transform;
ok($exon->start == 31_200);
ok($exon->end   == 31_400);
ok($exon->strand == 1);
ok($exon->contig->name eq $exon->contig->name);

#regression test, supporting evidence was lost post transform before...
ok(scalar(@{$exon->get_all_supporting_features} == $count));

$multi->restore();

