# Parse UniGene Hs.seq.uniq files to create xrefs.

package XrefParser::UniGeneParser;

use strict;

use File::Basename;

use base qw( XrefParser::BaseParser );

# --------------------------------------------------------------------------------
# Parse command line and run if being run directly

if (!defined(caller())) {

  if (scalar(@ARGV) != 1) {
    print "\nUsage: UniGeneParser.pm file.SPC <source_id> <species_id>\n\n";
    exit(1);
  }

  run($ARGV[0], -1);

}

# --------------------------------------------------------------------------------

sub run {

  my $self = shift if (defined(caller(1)));
  my $file = shift;
  my $source_id = shift;
  my $species_id = shift;

  my $unigene_source_id = XrefParser::BaseParser->get_source_id_for_source_name('UniGene');

  print "UniGene source ID = $unigene_source_id.\n";

  if(!defined($species_id)){
    $species_id = XrefParser::BaseParser->get_species_id_for_filename($file);
  }

  my $xrefs =
    $self->create_xrefs( $unigene_source_id, $unigene_source_id, $file,
      $species_id );

  if(!defined($xrefs)){
    return 1; #error
  }
  if(!defined(XrefParser::BaseParser->upload_xref_object_graphs($xrefs))){
    return 1; # error
  }
  return 0; # successfull

}


my %geneid_2_desc;

sub get_desc{
  my $self = shift;
  my $file = shift;

  my $dir = dirname($file);

  (my $name) = $file  =~ /\/(\w+)\.seq\.uniq/;
  print $name."\n";

  local $/ = "//";

  my $desc_io = $self->get_filehandle( $dir . '/' . $name . '.data' );

  if ( !defined $desc_io ) {
    print "ERROR: Can't open $dir/$name.data\n";
    return undef;
  }

  while ( $_ = $desc_io->getline() ) {
    #ID          Hs.159356
    #TITLE       Hypothetical LOC388277
    
    (my $id) = $_ =~ /ID\s+(\S+)/;
    (my $descrip) = $_ =~ /TITLE\s+(.+)\n/;

    $geneid_2_desc{$id} = $descrip;
    
  }

  $desc_io->close();

  return 1;
}


sub create_xrefs {
  my $self = shift;

  my ( $peptide_source_id, $unigene_source_id, $file, $species_id ) = @_;

  my %name2species_id = XrefParser::BaseParser->name2species_id();

  if ( !defined( $self->get_desc($file) ) ) {
    return undef;
  }

  my $unigene_io = $self->get_filehandle($file);

  if ( !defined $unigene_io ) {
    print "Can't open RefSeq file $file\n";
    return undef;
  }

#>gnl|UG|Hs#S19185843 Homo sapiens N-acetyltransferase 2 (arylamine N-acetyltransferase)
  # , mRNA (cDNA clone MGC:71963 IMAGE:4722596), complete cds /cds=(105,977) /gb=BC067218 /gi=45501306 /ug=Hs.2 /len=1344
#GGGGACTTCCCTTGCAGACTTTGGAAGGGAGAGCACTTTATTACAGACCTTGGAAGCAAG


  my @xrefs;

  local $/ = "\n>";

  while ( $_ = $unigene_io->getline() ) {

    my $xref;

    my $entry = $_;
    chomp $entry;
    my ($header, $sequence) = split (/\n/, $entry, 2);
    $sequence =~ s/^>//;
    # remove newlines
    my @seq_lines = split (/\n/, $sequence);
    $sequence = join("", @seq_lines);

#    (my $gnl, my $n, my $rest) = split(/\|/, $header,3);

    (my $acc_no_ver) = $header =~ /\/ug=(\S*)/;

    if(!defined($geneid_2_desc{$acc_no_ver})){
      print "****$_\n";
      $geneid_2_desc{$acc_no_ver} = "";
      warn "No desc for $acc_no_ver\n";
    }


    $xref->{SEQUENCE_TYPE} = 'dna';
    $xref->{STATUS} = 'experimental';
    $xref->{SOURCE_ID} = $unigene_source_id;
   

    ##No species check as files contain data  fro only one species.
    
    $xref->{ACCESSION} = $acc_no_ver;
    $xref->{LABEL} = $acc_no_ver;
    $xref->{DESCRIPTION} = $geneid_2_desc{$acc_no_ver};
    $xref->{SEQUENCE} = $sequence;
    $xref->{SPECIES_ID} = $species_id;
    
    push @xrefs, $xref;
    
  }

  $unigene_io->close();

  %geneid_2_desc=();
  print "Read " . scalar(@xrefs) ." xrefs from $file\n";

  return \@xrefs;

}

1;
