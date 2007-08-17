package XrefParser::HUGO_ENSGParser;

use strict;

use DBI;

use base qw( XrefParser::BaseParser );

# Parse file of HGNC records and assign direct xrefs
# All assumed to be linked to genes

sub run {

  my ($self, $source_id, $species_id, $file) = @_;

  my $hugo_io = $self->get_filehandle($file);

  if ( !defined $hugo_io ) {
    print "Could not open $file\n";
    return 1;
  }

  my $line_count = 0;
  my $xref_count = 0;

  # becouse the direct mapping have no descriptions etc
  # we have to steal these fromt he previous HUGO parser.
  # This is why the order states this is after the other one.
  # maybe 1091,1092 is not right maybe should use name = HUGO and priority = 30r4 ??

  my %label;
  my %version;
  my %description;

  my $dbi = $self->dbi();  

  #get the source ids for HUGO refseq, entrezgene and unitprot
  my $sql = 'select source_id, priority_description from source where name like "HUGO"';
  my $sth = $dbi->prepare($sql);
  
  $sth->execute();
  my ($hgnc_source_id, $desc);
  $sth->bind_columns(\$hgnc_source_id, \$desc);
  my @arr;
  while($sth->fetch()){
    if(lc($desc) eq "refseq" or lc($desc) eq "uniprot" or lc($desc) eq "entrezgene"){
      push @arr, $hgnc_source_id;
    }
  }
  $sth->finish;
  
  $sql = "select accession, label, version,  description from xref where source_id in (".join(", ",@arr).")";
  $sth = $dbi->prepare($sql);
  $sth->execute();
  my ($acc, $lab, $ver);
  $sth->bind_columns(\$acc, \$lab, \$ver, \$desc);
  while (my @row = $sth->fetchrow_array()) {
    $label{$acc} = $lab;
    $version{$acc} = $ver;
    $description{$acc} = $desc;
  }
  $sth->finish;


  my $ignore_count = 0;
  my $ignore_examples ="";
  my %acc;

  while ( $_ = $hugo_io->getline() ) {

    my ($hgnc, $stable_id) = split;

    if(!defined($label{$hgnc})){
      $ignore_count++;
      if($ignore_count < 10){
	$ignore_examples .= " ".$hgnc;
      }
      next;
    }
    if(!defined($acc{$hgnc})){
      $acc{$hgnc} = 1;
      my $version ="";
      $line_count++;
      
      my $xref_id = $self->add_xref($hgnc, $version{$hgnc} , $label{$hgnc}||$hgnc , $description{$hgnc}, $source_id, $species_id);
      $xref_count++;
      

      $self->add_direct_xref($xref_id, $stable_id, "gene", "");
    }
  }

  print "Parsed $line_count HGNC identifiers from $file, added $xref_count xrefs and $line_count direct_xrefs\n";
  if($ignore_count){
    print $ignore_count." ignoreed due to numbers no identifiers being no longer valid :- $ignore_examples\n";
  }

  $hugo_io->close();

  return 0;
}

1;
