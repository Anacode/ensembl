# Parse UniProt (SwissProt & SPTrEMBL) files to create xrefs.
#
# Files actually contain both types of xref, distinguished by ID line;
#
# ID   CYC_PIG                 Reviewed;         104 AA.  Swissprot
# ID   Q3ASY8_CHLCH            Unreviewed;     36805 AA.  SPTrEMBL



package XrefParser::UniProtParser;

use strict;
use POSIX qw(strftime);
use File::Basename;

use base qw( XrefParser::BaseParser );

# --------------------------------------------------------------------------------
# Parse command line and run if being run directly

if (!defined(caller())) {

  if (scalar(@ARGV) != 3) {
    print "\nUsage: UniProtParser.pm file.SPC <source_id> <species_id>\n\n";
    print scalar(@ARGV);
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
  my $species_name;

  my ($sp_source_id, $sptr_source_id);

  if(!defined($species_id)){
    ($species_id, $species_name) = get_species($file);
  }
  $sp_source_id = XrefParser::BaseParser->get_source_id_for_source_name('Uniprot/SWISSPROT');
  $sptr_source_id = XrefParser::BaseParser->get_source_id_for_source_name('Uniprot/SPTREMBL');
  print "SwissProt source id for $file: $sp_source_id\n";
  print "SpTREMBL source id for $file: $sptr_source_id\n";
 

  my @xrefs =
    $self->create_xrefs( $sp_source_id, $sptr_source_id, $species_id,
      $file );

  if ( !@xrefs ) {
      return 1;    # 1 error
  }

  # delete previous if running directly rather than via BaseParser
  if (!defined(caller(1))) {
    print "Deleting previous xrefs for these sources\n";
    XrefParser::BaseParser->delete_by_source(\@xrefs);
  }

  # upload
  if(!defined(XrefParser::BaseParser->upload_xref_object_graphs(@xrefs))){
    return 1; 
  }
  return 0; # successfull
}

# --------------------------------------------------------------------------------
# Get species (id and name) from file
# For UniProt files the filename is the taxonomy ID

sub get_species {

  my ($file) = @_;

  my ($taxonomy_id, $extension) = split(/\./, basename($file));

  my $sth = XrefParser::BaseParser->dbi()->prepare("SELECT species_id,name FROM species WHERE taxonomy_id=?");
  $sth->execute($taxonomy_id);
  my ($species_id, $species_name);
  while(my @row = $sth->fetchrow_array()) {
    $species_id = $row[0];
    $species_name = $row[1];
  }
  $sth->finish;

  if (defined $species_name) {

    print "Taxonomy ID " . $taxonomy_id . " corresponds to species ID " . $species_id . " name " . $species_name . "\n";

  } else {

    print "Cannot find species corresponding to taxonomy ID " . $species_id . " - check species table\n";
    exit(1);

  }

  return ($species_id, $species_name);

}

# --------------------------------------------------------------------------------
# Parse file into array of xref objects

sub create_xrefs {
  my $self = shift;

  my ( $sp_source_id, $sptr_source_id, $species_id, $file ) = @_;

  my $num_sp = 0;
  my $num_sptr = 0;
  my $num_sp_pred = 0;
  my $num_sptr_pred = 0;

  my %dependent_sources = XrefParser::BaseParser->get_dependent_xref_sources(); # name-id hash

  # Get predicted equivalents of various sources used here
  my $sp_pred_source_id = XrefParser::BaseParser->get_source_id_for_source_name('Uniprot/SWISSPROT_predicted');
  my $sptr_pred_source_id = XrefParser::BaseParser->get_source_id_for_source_name('Uniprot/SPTREMBL_predicted');
#  my $go_source_id = XrefParser::BaseParser->get_source_id_for_source_name('GO');
  my $embl_pred_source_id = $dependent_sources{'EMBL_predicted'};
  my $protein_id_pred_source_id = $dependent_sources{'protein_id_predicted'};
  print "Predicted SwissProt source id for $file: $sp_pred_source_id\n";
  print "Prediced SpTREMBL source id for $file: $sptr_pred_source_id\n";
  print "Predicted EMBL source id for $file: $embl_pred_source_id\n";
  print "Predicted protein_id source id for $file: $protein_id_pred_source_id\n";
#  print "GO source id for $file: $go_source_id\n";

  my (%genemap) = %{XrefParser::BaseParser->get_valid_codes("mim_gene",$species_id)};
  my (%morbidmap) = %{XrefParser::BaseParser->get_valid_codes("mim_morbid",$species_id)};

    my $uniprot_io = $self->get_filehandle($file);
    if ( !defined $uniprot_io ) { return undef }

  my @xrefs;

  local $/ = "//\n";

  while ( $_ = $uniprot_io->getline() ) {

    # if an OX line exists, only store the xref if the taxonomy ID that the OX
    # line refers to is in the species table
    # due to some records having more than one tax_id, we need to check them 
    # all and only proceed if one of them matches.
    #OX   NCBI_TaxID=158878, 158879;
    #OX   NCBI_TaxID=103690;

    my ($ox) = $_ =~ /OX\s+[a-zA-Z_]+=([0-9 ,]+);/;
    my @ox = ();
    my $found = 0;

    if ( defined $ox ) {
        @ox = split /\, /, $ox;

        my %taxonomy2species_id =
          XrefParser::BaseParser->taxonomy2species_id();

        foreach my $taxon_id_from_file (@ox) {
            if ( exists $taxonomy2species_id{$taxon_id_from_file}
                and $taxonomy2species_id{$taxon_id_from_file} eq
                $species_id )
            {
                $found = 1;
            }
        }
    }

    next if (!$found); # no taxon_id's match, so skip to next record
    my $xref;

    # set accession (and synonyms if more than one)
    # AC line may have primary accession and possibly several ; separated synonyms
    # May also be more than one AC line
    my ($acc) = $_ =~ /(AC\s+.+)/s; # will match first AC line and everything else
    my @all_lines = split /\n/, $acc;

    # extract ^AC lines only & build list of accessions
    my @accessions;
    foreach my $line (@all_lines) {
      my ($accessions_only) = $line =~ /^AC\s+(.+)/;
      push(@accessions, (split /;\s*/, $accessions_only)) if ($accessions_only);
    }

    $xref->{ACCESSION} = $accessions[0];
    for (my $a=1; $a <= $#accessions; $a++) {
      push(@{$xref->{"SYNONYMS"} }, $accessions[$a]);
    }

    # Check for CC (caution) lines containing certain text
    # if this appears then set the source of this and and dependent xrefs to the predicted equivalents
    my $is_predicted = /CC.*EMBL\/GenBank\/DDBJ whole genome shotgun \(WGS\) entry/;

    my ($label, $sp_type) = $_ =~ /ID\s+(\w+)\s+(\w+)/;

    # SwissProt/SPTrEMBL are differentiated by having STANDARD/PRELIMINARY here
    if ($sp_type =~ /^Reviewed/i) {

      $xref->{SOURCE_ID} = $sp_source_id;
      if ($is_predicted) {
	$xref->{SOURCE_ID} = $sp_pred_source_id;
	$num_sp_pred++;
      } else {
	$xref->{SOURCE_ID} = $sp_source_id;
	$num_sp++;
      }
    } elsif ($sp_type =~ /Unreviewed/i) {

      if ($is_predicted) {
	$xref->{SOURCE_ID} = $sptr_pred_source_id;
	$num_sptr_pred++;
      } else {
	$xref->{SOURCE_ID} = $sptr_source_id;
	$num_sptr++;
      }

    } else {

      next; # ignore if it's neither one nor t'other

    }



    # some straightforward fields
    $xref->{LABEL} = $label;
    $xref->{SPECIES_ID} = $species_id;
    $xref->{SEQUENCE_TYPE} = 'peptide';
    $xref->{STATUS} = 'experimental';

    # May have multi-line descriptions
    my ($description_and_rest) = $_ =~ /(DE\s+.*)/s;
    @all_lines = split /\n/, $description_and_rest;

    # extract ^DE lines only & build cumulative description string
    my $description;
    foreach my $line (@all_lines) {
      my ($description_only) = $line =~ /^DE\s+(.+)/;
      $description .= $description_only if ($description_only);
      $description .= " ";
    }

    $description =~ s/^\s*//g;
    $description =~ s/\s*$//g;

    $xref->{DESCRIPTION} = $description;

    # extract sequence
    my ($seq) = $_ =~ /SQ\s+(.+)/s; # /s allows . to match newline
      my @seq_lines = split /\n/, $seq;
    my $parsed_seq = "";
    foreach my $x (@seq_lines) {
      $parsed_seq .= $x;
    }
    $parsed_seq =~ s/\/\///g;   # remove trailing end-of-record character
    $parsed_seq =~ s/\s//g;     # remove whitespace
    $parsed_seq =~ s/^.*;//g;   # remove everything before last ;

    $xref->{SEQUENCE} = $parsed_seq;
    #print "Adding " . $xref->{ACCESSION} . " " . $xref->{LABEL} ."\n";

    # dependent xrefs - only store those that are from sources listed in the source table
    my ($deps) = $_ =~ /(DR\s+.+)/s; # /s allows . to match newline

    my @dep_lines = ();
    if ( defined $deps ) { @dep_lines = split /\n/, $deps }

    foreach my $dep (@dep_lines) {
      #both GO and UniGene have the own sources so ignore those in the uniprot files
      #as the uniprot data should be older
      if($dep =~ /GO/ || $dep =~ /UniGene/){
	next;
      }
      if ($dep =~ /^DR\s+(.+)/) {
	my ($source, $acc, @extra) = split /;\s*/, $1;
	if($source =~ "RGD"){  #using RGD file now instead.
	  next;
	}
	if (exists $dependent_sources{$source} ) {
	  # create dependent xref structure & store it
	  my %dep;
          $dep{SOURCE_NAME} = $source;
          $dep{LINKAGE_SOURCE_ID} = $xref->{SOURCE_ID};
          $dep{SOURCE_ID} = $dependent_sources{$source};
	  $dep{ACCESSION} = $acc;
	  if($dep =~ /MIM/){
	    $dep{ACCESSION} = $acc;
	    if(defined($morbidmap{$acc}) and $extra[0] eq "phenotype."){
	      $dep{SOURCE_NAME} = "MIM_MORBID";
	      $dep{SOURCE_ID} = $dependent_sources{"MIM_MORBID"};
	    }
	    elsif(defined($genemap{$acc}) and $extra[0] eq "gene."){
	      $dep{SOURCE_NAME} = "MIM_GENE";
	      $dep{SOURCE_ID} = $dependent_sources{"MIM_GENE"};
	    }
	    elsif($extra[0] eq "gene+phenotype."){
	      $dep{SOURCE_NAME} = "MIM_MORBID";
	      $dep{SOURCE_ID} = $dependent_sources{"MIM_MORBID"};
	      if(defined($morbidmap{$acc})){
		push @{$xref->{DEPENDENT_XREFS}}, \%dep; # array of hashrefs
	      }
	      my %dep2;
	      $dep2{ACCESSION} = $acc;
	      $dep2{LINKAGE_SOURCE_ID} = $xref->{SOURCE_ID};
	      $dep2{SOURCE_NAME} = "MIM_GENE";
	      $dep2{SOURCE_ID} = $dependent_sources{"MIM_GENE"};	      
	      if(defined($genemap{$acc})){
		push @{$xref->{DEPENDENT_XREFS}}, \%dep2; # array of hashrefs
	      }
	      next;
	    }
	    else{
#	      print "missed $dep\n";
	      next;
	    }
	  }
	  if ($source eq "EMBL" && $is_predicted) {
	    $dep{SOURCE_ID} = $embl_pred_source_id
	  };

	  $dep{ACCESSION} = $acc;
	  push @{$xref->{DEPENDENT_XREFS}}, \%dep; # array of hashrefs

	  if($dep =~ /EMBL/){
	    my ($protein_id) = $extra[0];
	    if($protein_id ne "-"){
	      my %dep2;
	      $dep2{SOURCE_NAME} = $source;
	      $dep2{SOURCE_ID} = $dependent_sources{protein_id};
	      if ($is_predicted) {
		$dep2{SOURCE_ID} = $protein_id_pred_source_id
	      };
	      $dep2{LINKAGE_SOURCE_ID} = $xref->{SOURCE_ID};
	      # store accession unversioned
	      $dep2{LABEL} = $protein_id;
	      my ($prot_acc, $prot_version) = $protein_id =~ /([^.]+)\.([^.]+)/;
	      $dep2{ACCESSION} = $prot_acc;
	      $dep2{VERSION} = $prot_acc;
	      push @{$xref->{DEPENDENT_XREFS}}, \%dep2; # array of hashrefs
	    }
	  }
	}
      }
    }

    push @xrefs, $xref;

  }

  $uniprot_io->close();

  print "Read $num_sp SwissProt xrefs and $num_sptr SPTrEMBL xrefs from $file\n";
  print "Found $num_sp_pred predicted SwissProt xrefs and $num_sptr_pred predicted SPTrEMBL xrefs\n" if ($num_sp_pred > 0 || $num_sptr_pred > 0);

  return \@xrefs;

  #TODO - currently include records from other species - filter on OX line??
}

1;
