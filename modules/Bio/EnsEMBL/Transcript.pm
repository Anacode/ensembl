#
# BioPerl module for Transcript
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Transcript - gene transcript object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Contains details of coordinates of all exons that make
up a gene transcript.

Creation:

     my $tran = new Bio::EnsEMBL::Transcript();
     my $tran = new Bio::EnsEMBL::Transcript(@exons);

Manipulation:

     # Returns an array of Exon objects
     my @exons = @{$tran->get_all_Exons}     
     # Returns the peptide translation of the exons as a Bio::Seq
     my $pep   = $tran->translate()       
     # Sorts exons into order (forward for + strand, reverse for - strand)
     $tran->sort()                        

=head1 CONTACT

Email questions to the ensembl developer mailing list <ensembl-dev@ebi.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::EnsEMBL::Transcript;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Object

use Bio::EnsEMBL::Root;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Intron;
use Bio::EnsEMBL::Translation;
use Bio::EnsEMBL::TranscriptI;
use Bio::Tools::CodonTable;
use Bio::EnsEMBL::Mapper;

@ISA = qw(Bio::EnsEMBL::Root Bio::EnsEMBL::TranscriptI);
# new() is inherited from Bio::Root::Object

sub new {
  my($class,@args) = @_;

  if( ref $class ) { 
      $class = ref $class;
  }

  my $self = {};
  bless $self,$class;

  $self->{'_trans_exon_array'} = [];

  # set stuff in self from @args
  foreach my $a (@args) {
    $self->add_Exon($a);
  }


  return $self; # success - we hope!
}



=head2 get_all_DBLinks

  Arg [1]    : 
  Example    : 
  Description: 
  Returntype : 
  Exceptions : 
  Caller     : 

=cut

sub get_all_DBLinks {
  my $self = shift;

  if( !defined $self->{'_db_link'} ) {
    $self->{'_db_link'} = [];
    if( defined $self->adaptor ) {
      $self->adaptor->db->get_DBEntryAdaptor->fetch_all_by_Transcript($self);
    }
  } 
  
  return $self->{'_db_link'};
}


=head2 add_DBLink

 Title   : add_DBLink
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub add_DBLink{
   my ($self,$value) = @_;

   unless(defined $value && ref $value && 
	  $value->isa('Bio::Annotation::DBLink') ) {
     $self->throw("This [$value] is not a DBLink");
   }

   if( !defined $self->{'_db_link'} ) {
     $self->{'_db_link'} = [];
   }

   push(@{$self->{'_db_link'}},$value);
}



sub dbID {
   my $self = shift;
   
   if( @_ ) {
      my $value = shift;
      $self->{'dbID'} = $value;
    }
    return $self->{'dbID'};

}

=head2 external_db

 Title   : external_db
 Usage   : $ext_db = $obj->external_db();
 Function: external_name if available
 Returns : the external db link for this transcript
 Args    : new external db (optional)

=cut

sub external_db {
  my ($self, $ext_dbname) = @_;

  if(defined $ext_dbname) { 
    $self->{'_ext_dbname'} = $ext_dbname;
  } 

  if( exists $self->{'_ext_dbname'} ) {
    return $self->{'_ext_dbname'};
  }

  $self->{'_ext_dbname'} = $self->adaptor->get_external_dbname($self->dbID);
  return $self->{'_ext_dbname'};

}


=head2 external_name

 Title   : external_name
 Usage   : $ext_name = $obj->external_name();
 Function: external_name if available
 Example : 
 Returns : the external name of this transcript
 Args    : new external name (optional)

=cut

sub external_name {
  my ($self, $ext_name) = @_;

  if(defined $ext_name) { 
    $self->{'_ext_name'} = $ext_name;
  } 

  if( exists $self->{'_ext_name'} ) {
    return $self->{'_ext_name'};
  }

  $self->{'_ext_name'} = $self->adaptor->get_external_name($self->dbID);
  return $self->{'_ext_name'};

}


sub is_known {
  my $self = shift;
  if( defined $self->external_name() && $self->external_name() ne '' ) {
    return 1;
  } else {
    return 0;
  }
}


sub type {
  my ($self, $type) = @_;

  if(defined $type) {
    $self->{'_type'} = $type;
  }

  return $self->{'_type'};
}

sub adaptor {
   my $self = shift;
   
   if( @_ ) {
      my $value = shift;
      $self->{'adaptor'} = $value;
    }
    return $self->{'adaptor'};

}


=head2 relevant_xref

  Arg [1]    : int $relevant_xref_id
  Example    : $transcript->relevant_xref(42);
  Description: get/set/lazy_loaded relevant_xref_id for this transcript
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub relevant_xref{

    my ($self,$value) = @_;
    
    if( defined $value ) {
      $self->{'relevant_xref'} = $value;
      return;
    }

    if( exists $self->{'relevant_xref'} ) {
      return $self->{'relevant_xref'};
    }

    $self->{'relevant_xref'} = $self->adaptor->get_relevant_xref_id($self->dbID);

    return $self->{'relevant_xref'};
}



=head2 _translation_id

 Title   : _translation_id
 Usage   : $obj->_translation_id($newval)
 Function: 
 Returns : translation objects dbID
 Args    : newvalue (optional)


=cut

sub _translation_id {
   my $self = shift;
   
   if( @_ ) {
      my $value = shift;
      $self->{'_translation_id'} = $value;
    }
    return $self->{'_translation_id'};

}


=head2 translation

 Title   : translation
 Usage   : $obj->translation($newval)
 Function: 
 Returns : value of translation
 Args    : newvalue (optional)


=cut

sub translation {
  my $self = shift;
  if( @_ ) {
    my $value = shift;
    if( ! ref $value || !$value->isa('Bio::EnsEMBL::Translation') ) {
      $self->throw("This [$value] is not a translation");
    }
    $self->{'translation'} = $value;
  } else {
    if( ! defined $self->{'translation'} &&
	defined $self->_translation_id() ) {
      $self->{'translation'} = 
	$self->adaptor->db->get_TranslationAdaptor->fetch_by_dbID( 
					    $self->_translation_id(), $self );
    }
  }
  return $self->{'translation'};
}

=head2 start

 Description: it returns the start coordinate of the lef-most exon, i.e.
              the 5prime exon in the forward strand and the 3prime exon in the reverse strand

=cut


sub start {
  my $self = shift;
  my $arg = shift;
  
  my $strand;
  my $start;
  if( defined $arg ) {
    $self->{'_start'} = $arg;
  } elsif(!  defined $self->{'_start'} ) {

    $strand = $self->start_Exon->strand();
    if( $strand == 1 ) {
      $start = $self->start_Exon->start();
    } else {
      $start = $self->end_Exon->start();
    }
    $self->{'_start'} = $start;
  }
  
  return $self->{'_start'};
}


sub end {
  my $self = shift;
  my $arg = shift;

  my $strand;
  my $end
;
  if( defined $arg ) {
    $self->{'_end'} = $arg;
  } elsif( ! defined $self->{'_end'} ) {
    $strand = $self->start_Exon->strand();
    if( $strand == 1 ) {
      $end = $self->end_Exon->end();
    } else {
      $end = $self->start_Exon->end();
    }
    $self->{'_end'} = $end;
  }
  
  return $self->{'_end'};
}


=head2 spliced_seq

  Args       : none
  Example    : none
  Description: retrieves all Exon sequences and concats them together. No phase padding magic is 
               done, even if phases dont align.
  Returntype : txt
  Exceptions : none
  Caller     : general

=cut

sub spliced_seq {
  my ( $self ) = @_;
  
  my $seq_string = "";
  for my $ex ( @{$self->get_all_Exons()} ) {
    $seq_string .= $ex->seq()->seq();
  }

  return $seq_string;
}


=head2 translateable_seq

  Args       : none
  Example    : none
  Description: returns a string with the translateable part of the
               Sequence. It magically pads the exon sequences with
               N if the phases of the Exons dont align
  Returntype : txt
  Exceptions : none
  Caller     : general

=cut

sub translateable_seq {
  my ( $self ) = @_;

  my $mrna = "";
  my $lastphase = 0;
  my $first = 1;

  foreach my $exon (@{$self->get_all_translateable_Exons()}) {

    my $phase = 0;
    if (defined($exon->phase)) {
      $phase = $exon->phase;
    }
    
    # startpadding is needed if MONKEY_EXONS are on
    if( $first && (! defined $ENV{'MONKEY_EXONS'}) ) {
      $mrna .= 'N' x $phase;
      $first = 0;
    }

    if( $phase != $lastphase && ( defined $ENV{'MONKEY_EXONS'})) {
      # endpadding for the last exon
      if( $lastphase == 1 ) {
	$mrna .= 'NN';
      } elsif( $lastphase == 2 ) {
	$mrna .= 'N';
      }
      #startpadding for this exon
      $mrna .= 'N' x $phase;
    }
    $mrna .= $exon->seq->seq();
    $lastphase = $exon->end_phase();
  }
  return $mrna;
}



=head2 cdna_coding_start

  Arg [1]    : (optional) $value
  Example    : $relative_coding_start = $transcript->cdna_coding_start;
  Description: Retrieves the position of the coding start of this transcript
               in cdna coordinates (relative to the start of the 5prime end of
               the transcript, excluding introns, including utrs).
  Returntype : int
  Exceptions : none
  Caller     : five_prime_utr, get_all_snps, general

=cut

sub cdna_coding_start {
  my ($self, $value) = @_;

  if(defined $value) {
    $self->{'cdna_coding_start'} = $value;
  } elsif(!defined $self->{'cdna_coding_start'} && defined $self->translation){
    #
    #calculate the coding start relative from the start of the
    #translation (in cdna coords)
    #
    my $start = 0;

    my @exons = @{$self->get_all_Exons};
    my $exon;

    while($exon = shift @exons) {
      if($exon == $self->translation->start_Exon) {
	#add the utr portion of the start exon
	$start += $self->translation->start;
	last;
      } else {
	#add the entire length of this non-coding exon
	$start += $exon->length;
      }
    }
    $self->{'cdna_coding_start'} = $start;
  }

  return $self->{'cdna_coding_start'};
}



=head2 cdna_coding_end

  Arg [1]    : (optional) $value
  Example    : $cdna_coding_end = $transcript->coding_end;
  Description: Retrieves the end of the coding region of this transcript in
               cdna coordinates (relative to the five prime end of the
               transcript, excluding introns, including utrs)
  Returntype : none
  Exceptions : none
  Caller     : general

=cut

sub cdna_coding_end {
  my ($self, $value) = @_;

  if($value) {
    $self->{'cdna_coding_end'} = $value;
  } elsif(!defined $self->{'cdna_coding_end'} && defined $self->translation) {
    my @exons = @{$self->get_all_Exons};

    my $end = 0;
    while(my $exon = shift @exons) {
      if($exon == $self->translation->end_Exon) {
	#add the coding portion of the final coding exon
	$end += $self->translation->end;
	last;
      } else {
	#add the entire exon
	$end += $exon->length;
      }
    }
    $self->{'cdna_coding_end'} = $end;
  }

  return $self->{'cdna_coding_end'};
}



=head2 coding_start

  Arg [1]    : (optional) $value
  Example    : $coding_start = $transcript->coding_start
  Description: Retrieves the start of the coding region of this transcript
               in genomic coordinates (i.e. in either slice or contig coords).
  Returntype : none
  Exceptions : none
  Caller     : general

=cut

sub coding_start {
  my ($self, $value) = @_;

  if( defined $value ) {
    $self->{'coding_start'} = $value;
  } elsif(!defined $self->{'coding_start'} && defined $self->translation) {
    #calculate the coding start from the translation
    my $start;
    my $strand = $self->translation()->start_Exon->strand();
    if( $strand == 1 ) {
      $start = $self->translation()->start_Exon->start();
      $start += ( $self->translation()->start() - 1 );
    } else {
      $start = $self->translation()->end_Exon->end();
      $start -= ( $self->translation()->end() - 1 );
    }
    $self->{'coding_start'} = $start;
  }

  return $self->{'coding_start'};
}



=head2 coding_end

  Arg [1]    : 
  Example    : 
  Description: 
  Returntype : 
  Exceptions : 
  Caller     : 

=cut

sub coding_end {
  my ($self, $value ) = @_;

  my $strand;
  my $end;

  if( defined $value ) {
    $self->{'coding_end'} = $value;
  } elsif( ! defined $self->{'coding_end'} && defined $self->translation() ) {
    $strand = $self->translation()->start_Exon->strand();
    if( $strand == 1 ) {
      $end = $self->translation()->end_Exon->start();
      $end += ( $self->translation()->end() - 1 );
    } else {
      $end = $self->translation()->start_Exon->end();
      $end -= ( $self->translation()->start() - 1 );
    }
    $self->{'coding_end'} = $end;
  }

  return $self->{'coding_end'};
}




=head2 add_Exon

 Title   : add_Exon
 Usage   : $trans->add_Exon($exon)
 Returns : Nothing
 Args    :

=cut

sub add_Exon{
   my ($self,$exon) = @_;

   #yup - we are going to be picky here...
   unless(defined $exon && ref $exon && $exon->isa("Bio::EnsEMBL::Exon") ) {
     $self->throw("[$exon] is not a Bio::EnsEMBL::Exon!");
   }

   #invalidate the start, end and strand - they may need to be recalculated
   $self->{'_start'} = undef;
   $self->{'_end'} = undef;
   $self->{'_strand'} = undef;

   push(@{$self->{'_trans_exon_array'}},$exon);
}



=head2 get_all_Exons

  Arg [1]    : none
  Example    : my @exons = @{$transcript->get_all_Exons()};
  Description: Returns an listref of the exons in this transcipr in order.
               i.e. the first exon in the listref is the 5prime most exon in 
               the transcript.
  Returntype : a list reference to Bio::EnsEMBL::Exon objects
  Exceptions : none
  Caller     : general

=cut

sub get_all_Exons {
   my ($self) = @_;

   return $self->{'_trans_exon_array'};
}



=head2 length


    my $t_length = $transcript->length

Returns the sum of the length of all the exons in
the transcript.

=cut

sub length {
    my( $self ) = @_;
    
    my $length = 0;
    foreach my $ex (@{$self->get_all_Exons}) {
        $length += $ex->length;
    }
    return $length;
}



=head2 get_all_Introns

  Args       : none
  Example    : @introns = @{$transcript->get_all_Introns()};
  Description: Returns an listref of Bio::EnsEMBL::Intron objects.  The result 
               is not cached in any way, so calling each_Intron multiple times
               will create new Intron objects (although they will, of course, 
               have the same properties).
  Returntype : list reference to Bio::EnsEMBL::Intron objects
  Exceptions : none
  Caller     : general

=cut

sub get_all_Introns {
    my( $self ) = @_;
    
    my @exons = @{$self->get_all_Exons};
    my $last = @exons - 1;
    my( @int );
    for (my $i = 0; $i < $last; $i++) {
        my $intron = Bio::EnsEMBL::Intron->new;
        $intron->upstream_Exon  ($exons[$i]    );
        $intron->downstream_Exon($exons[$i + 1]);
        push(@int, $intron);
    }
    return \@int;
}



=head2 get_all_peptide_variations

  Arg [1]    : (optional) $snps listref of coding snps in cdna coordinates
  Example    : $pep_hash = $trans->get_all_peptide_variations;
  Description: Takes an optional list of coding snps on this transcript in 
               which are in cdna coordinates and returns a hash with peptide 
               coordinate keys and listrefs of alternative amino acids as 
               values.  If no argument is provided all of the coding snps on 
               this transcript are used by default. Note that the peptide 
               encoded by the reference sequence is also present in the results
               and that duplicate peptides (e.g. resulting from synonomous 
               mutations) are discarded.  It is possible to have greated than
               two peptides variations at a given location given
               adjacent or overlapping snps. Insertion/deletion variations
               are ignored by this method. 
               Example of a data structure that could be returned:
               {  1  => ['I', 'M'], 
                 10  => ['I', 'T'], 
                 37  => ['N', 'D'], 
                 56  => ['G', 'E'], 
                 118 => ['R', 'K'], 
                 159 => ['D', 'E'], 
                 167 => ['Q', 'R'], 
                 173 => ['H', 'Q'] } 
  Returntype : hashref
  Exceptions : none
  Caller     : general

=cut

sub get_all_peptide_variations {
  my $self = shift;
  my $snps = shift;

  my $codon_table = Bio::Tools::CodonTable->new;
  my $codon_length = 3;
  my $cdna = $self->spliced_seq;

  unless(defined $snps) {
    $snps = $self->get_all_cdna_SNPs->{'coding'};
  }

  my $variant_alleles;
  my $translation_start = $self->cdna_coding_start;
  foreach my $snp (@$snps) {
    #skip variations not on a single base
    next if ($snp->start != $snp->end);

    my $start = $snp->start;
    my $strand = $snp->strand;    

    #calculate offset of the nucleotide from codon start (0|1|2)
    my $codon_pos = ($start - $translation_start) % $codon_length;

    #calculate the peptide coordinate of the snp
    my $peptide = ($start - $translation_start + 
		   ($codon_length - $codon_pos)) / $codon_length;

    #retrieve the codon
    my $codon = substr($cdna, $start - $codon_pos-1, $codon_length);

    #store each alternative allele by its location in the peptide
    my @alleles = split('/', lc($snp->alleles));
    foreach my $allele (@alleles) {
      next if $allele eq '-';       #skip deletions
      next if CORE::length($allele) != 1; #skip insertions
      
      if($strand == -1) {
	#complement the allele if the snp is on the reverse strand
	$allele =~ 
	 tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
      }

      #create a data structure of variant alleles sorted by both their
      #peptide position and their position within the peptides codon
      $variant_alleles ||= {};
      if(exists $variant_alleles->{$peptide}) {
	my $alleles_arr = $variant_alleles->{$peptide}->[1];
	push @{$alleles_arr->[$codon_pos]}, $allele;
      } else {
	#create a list of 3 lists (one list for each codon position)
	my $alleles_arr = [[],[],[]];
	push @{$alleles_arr->[$codon_pos]}, $allele;
	$variant_alleles->{$peptide} = [$codon, $alleles_arr];
      }
    }
  }

  my %out;
  #now generate all possible codons for each peptide and translate them
  foreach my $peptide (keys %$variant_alleles) {
    my ($codon, $alleles) = @{$variant_alleles->{$peptide}};

    #need to push original nucleotides onto each position
    #so that all possible combinations can be generated
    push @{$alleles->[0]}, substr($codon,0,1);
    push @{$alleles->[1]}, substr($codon,1,1);
    push @{$alleles->[2]}, substr($codon,2,1);

    my %alt_amino_acids;
    foreach my $a1 (@{$alleles->[0]}) {
      substr($codon, 0, 1) = $a1;
      foreach my $a2 (@{$alleles->[1]}) {
	substr($codon, 1, 1) = $a2;
	foreach my $a3 (@{$alleles->[2]}) {
	  substr($codon, 2, 1) = $a3;
	  my $aa = $codon_table->translate($codon);
	  #print "$codon translation is $aa\n";
	  $alt_amino_acids{$aa} = 1;
	}
      }
    }

    my @aas = keys %alt_amino_acids;
    $out{$peptide} = \@aas;
  }

  return \%out;
}


=head2 get_all_SNPs

  Arg [1]    : (optional) int $flanking
               The number of basepairs of transcript flanking sequence to 
               retrieve snps from (default 0) 
  Example    : $snp_hashref = $transcript->get_all_SNPs;
  Description: Retrieves all snps found within the region of this transcript. 
               The snps are returned in a hash with keys corresponding
               to the region the snp was found in.  Possible keys are:
               'three prime UTR', 'five prime UTR', 'coding', 'intronic',
               'three prime flanking', 'five prime flanking'
               If no flanking argument is provided no flanking snps will be
               obtained.
               The listrefs which are the values of the returned hash
               contain snps in coordinates of the transcript region 
               (i.e. first base = first base of the first exon on the
               postive strand - flanking bases + 1) 
  Returntype : hasref with string keys and listrefs of Bio::EnsEMBL::SNPs for 
               values
  Exceptions : none
  Caller     : general

=cut

sub get_all_SNPs {
  my $self = shift;
  my $flanking = shift;

  my %snp_hash;
  my $sa = $self->adaptor->db->get_SliceAdaptor;

  #retrieve a slice in the region of the transcript
  my $slice = $sa->fetch_by_transcript_id($self->dbID);

  #copy this transcript, so we can work in coord system we are interested in
  my $transcript = Bio::EnsEMBL::Transcript->new;
  %$transcript = %$self;

  #transform transcript to same coord system we will get snps in
  my %exon_transforms;
  foreach my $exon (@{$transcript->get_all_Exons}) {
    my $new_exon = $exon->transform($slice);
    $exon_transforms{$exon} = $new_exon;
  }
  $transcript->transform(\%exon_transforms);

  #get all of the snps in the transcript region
  my $snps = $slice->get_all_SNPs;

  my $trans_start  = $flanking + 1;
  my $trans_end    = $slice->length - $flanking;
  my $trans_strand = $transcript->get_all_Exons->[0]->strand;

  #classify each snp
  foreach my $snp (@$snps) {
    my $key;

    if(($trans_strand == 1 && $snp->end < $trans_start) ||
       ($trans_strand == -1 && $snp->start > $trans_end)) {
      #this snp is upstream from the transcript
      $key = 'five prime flanking';
    }

    elsif(($trans_strand == 1 && $snp->start > $trans_end) ||
	  ($trans_strand == -1 && $snp->start < $trans_start)) {
      #this snp is downstream from the transcript
      $key = 'three prime flanking';
    }

    else {
      #snp is inside transcript region check if it overlaps an exon
      foreach my $e (@{$transcript->get_all_Exons}) {
	if($snp->end >= $e->start && $snp->start <= $e->end) {
	  #this snp is in an exon

	  if(($trans_strand == 1 && $snp->end < $transcript->coding_start) ||
	  ($trans_strand == -1 && $snp->start > $transcript->coding_end)) {
	    #this snp is in the 5' UTR
	    $key = 'five prime UTR';
	  }

	  elsif(($trans_strand == 1 && $snp->start > $transcript->coding_end)||
	     ($trans_strand == -1 && $snp->end < $transcript->coding_start)) {
	    #this snp is in the 3' UTR
	    $key = 'three prime UTR';
	  }

	  else {
	    #snp is coding
	    $key = 'coding';
	  }
	  last;
	}
      }
      unless($key) {
	#snp was not in an exon and is therefore intronic
	$key = 'intronic';
      }
    }

    unless($key) {
      #$self->warn('SNP could not be mapped. In/Dels not supported yet...');
      next;
    }

    if(exists $snp_hash{$key}) {
      push @{$snp_hash{$key}}, $snp;
    } else {
      $snp_hash{$key} = [$snp];
    }
  }

  return \%snp_hash;
}



=head2 get_all_cdna_SNPs

  Arg [1]    : none 
  Example    : $cdna_snp_hasref = $transcript->get_all_cdna_SNPs;
  Description: Retrieves all snps found within exons of this transcript. 
               The snps are returned in a hash with three keys corresponding
               to the region the snp was found in.  Valid keys are:
               'three prime UTR', 'five prime UTR', 'coding'
               The listrefs which are the values of the returned hash
               contain snps in CDNA coordinates.
  Returntype : hasref with string keys and listrefs of Bio::EnsEMBL::SNPs for 
               values
  Exceptions : none
  Caller     : general

=cut

sub get_all_cdna_SNPs {
  my ($self) = shift;

  #retrieve all of the snps from this transcript
  my $all_snps = $self->get_all_SNPs;
  my %snp_hash;

  my @cdna_types = ('three prime UTR', 
		    'five prime UTR',
		    'coding');

  my $sa = $self->adaptor->db->get_SliceAdaptor;
  my $slice = $sa->fetch_by_transcript_id($self->dbID);

  #copy this transcript, so we can work in coord system we are interested in
  my $transcript = Bio::EnsEMBL::Transcript->new;
  %$transcript = %$self;

  #transform transcript to same coord system we will get snps in
  my %exon_transforms;
  foreach my $exon (@{$transcript->get_all_Exons}) {
    my $new_exon = $exon->transform($slice);
    $exon_transforms{$exon} = $new_exon;
  }
  $transcript->transform(\%exon_transforms);

  foreach my $type (@cdna_types) {
    $snp_hash{$type} = [];
    foreach my $snp (@{$all_snps->{$type}}) {
      my @coords = 
	$transcript->genomic2cdna($snp->start, 
				  $snp->end, 
				  $snp->strand, 
				  $slice);

      #skip snps that don't map cleanly (possibly an indel...)
      if(scalar(@coords) != 1) {
	#$self->warn("snp of type $type does not map cleanly\n");
	next;
      }

      my ($coord) = @coords;

      unless($coord->isa('Bio::EnsEMBL::Mapper::Coordinate')) {
	#$self->warn("snp of type $type maps to gap\n");
	next;
      }

      #copy the snp and convert to cdna coords...
      my $new_snp;
      %$new_snp = %$snp;
      bless $new_snp, ref $snp;
      $new_snp->start($coord->start);
      $new_snp->end($coord->end);
      $new_snp->strand($coord->strand);
      push @{$snp_hash{$type}}, $new_snp;
    }
  }

  return \%snp_hash;
}


=head2 flush_Exons

 Title   : flush_Exons
 Usage   : Removes all Exons from the array.
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub flush_Exons{
   my ($self,@args) = @_;
   $self->{'_exon_coord_mapper'} = undef;
   $self->{'coding_start'} = undef;
   $self->{'coding_end'} = undef;
   $self->{'_start'} = undef;
   $self->{'_end'} = undef;
   $self->{'_strand'} = undef;

   $self->{'_trans_exon_array'} = [];
}



=head2 five_prime_utr and three_prime_utr

    my $five_prime  = $transcrpt->five_prime_utr
        or warn "No five prime UTR";
    my $three_prime = $transcrpt->three_prime_utr
        or warn "No three prime UTR";

These methods return a B<Bio::Seq> object
containing the sequence of the five prime or
three prime UTR, or undef if there isn't a UTR.

Both method throw an exception if there isn't a
translation attached to the transcript object.

=cut

sub five_prime_utr {
  my $self = shift;

  my $seq = substr($self->spliced_seq, 0, $self->cdna_coding_start - 1);

  return Bio::Seq->new(
	       -DISPLAY_ID => $self->stable_id,
	       -MOLTYPE    => 'dna',
	       -SEQ        => $seq);
}


sub three_prime_utr {
  my $self = shift;

  my $seq = substr($self->spliced_seq, $self->cdna_coding_end);

  return Bio::Seq->new(
	       -DISPLAY_ID => $self->stable_id,
	       -MOLTYPE    => 'dna',
	       -SEQ        => $seq);
}


=head2 get_all_translateable_Exons

  Args       : none
  Example    : none
  Description: Returns a list of exons that translate with the
               start and end exons truncated to the CDS regions.
               Will not work correctly if Exons are Sticky. 
  Returntype : listref Bio::EnsEMBL::Exon
  Exceptions : If there is no Translation object
  Caller     : Genebuild, $self->translate()

=cut


sub get_all_translateable_Exons {
  my ( $self ) = @_;

  my $translation = $self->translation
    or $self->throw("No translation attached to transcript object");
  my $start_exon      = $translation->start_Exon;
  my $end_exon        = $translation->end_Exon;
  my $t_start         = $translation->start;
  my $t_end           = $translation->end;

  my( @translateable );

  foreach my $ex (@{$self->get_all_Exons}) {

    if ($ex ne $start_exon and ! @translateable) {
      next;   # Not yet in translated region
    }

    my $length  = $ex->length;
        
    my $adjust_start = 0;
    my $adjust_end = 0;
    # Adjust to translation start if this is the start exon
    if ($ex == $start_exon ) {
      if ($t_start < 1 or $t_start > $length) {
	$self->throw("Translation start '$t_start' is outside exon $ex length=$length");
      }
      $adjust_start = $t_start - 1;
    }
        
    # Adjust to translation end if this is the end exon
    if ($ex == $end_exon) {
      if ($t_end < 1 or $t_end > $length) {
	$self->throw("Translation end '$t_end' is outside exon $ex length=$length");
      }
      $adjust_end = $t_end - $length;
    }

    # Make a truncated exon if the translation start or
    # end causes the coordinates to be altered.
    if ($adjust_end || $adjust_start) {
      my $newex = $ex->adjust_start_end( $adjust_start, $adjust_end );

      push( @translateable, $newex );
    } else {
      push(@translateable, $ex);
    }
        
    # Exit the loop when we've found the last exon
    last if $ex eq $end_exon;
  }
  return \@translateable;
}





=head2 translate

  Args       : none
  Example    : none
  Description: return the peptide (plus eventuel stop codon) for this transcript.
               Does N padding of non phase matching exons. It uses translateable_seq
               internally. 
  Returntype : Bio::Seq
  Exceptions : If no Translation is set in this Transcript
  Caller     : general

=cut

sub translate {
  my ($self) = @_;

  my $mrna = $self->translateable_seq();
  my $display_id;

  if( defined $self->translation->stable_id ) {
    $display_id = $self->translation->stable_id;
  } elsif ( defined $self->temporary_id ) {
    $display_id = $self->temporary_id;
  } else {
    $display_id = $self->translation->dbID;
  }
	
  $mrna =~ s/TAG$|TGA$|TAA$//i;
  # the above line will remove the final stop codon from the mrna
  # sequence produced if it is present, this is so any peptide produced
  # won't have a terminal stop codon
  # if you want to have a terminal stop codon either comment this line out
  # or call translatable seq directly and produce a translation from it
  
  my $peptide = Bio::Seq->new( -seq => $mrna,
			       -moltype => "dna",
			       -alphabet => 'dna',
			       -id => $display_id );
    
  return $peptide->translate;
}

=head2 seq

Returns a Bio::Seq object which consists of just
the sequence of the exons concatenated together,
without messing about with padding with N\'s from
Exon phases like B<dna_seq> does.

=cut

sub seq {
    my( $self ) = @_;
    
    my $transcript_seq_string = '';
    foreach my $ex (@{$self->get_all_Exons}) {
#        $transcript_seq_string .= $ex->seq;
        $transcript_seq_string .= $ex->seq->seq;
    }
    
    my $seq = Bio::Seq->new(
        -DISPLAY_ID => $self->stable_id,
        -MOLTYPE    => 'dna',
        -SEQ        => $transcript_seq_string,
        );

    return $seq;
}




=head2 sort

 Title   : sort
 Usage   : $feat->sort()
 Function: Sorts the exon features by start coordinate
           Sorts forward for forward strand and reverse for reverse strand
 Returns : none
 Args    : none

=cut

sub sort {
  my $self = shift;

  # Fetch all the features
  my @exons = @{$self->get_all_Exons()};

  # Empty the feature table
  $self->flush_Exons();

  # Now sort the exons and put back in the feature table
  my $strand = $exons[0]->strand;

  if ($strand == 1) {
    @exons = sort { $a->start <=> $b->start } @exons;
  } elsif ($strand == -1) {
    @exons = sort { $b->start <=> $a->start } @exons;
  }

  foreach my $e (@exons) {
    $self->add_Exon($e);
  }
}



=head1 pep2genomic

  Arg  1   : integer start - relative to peptide
  Arg  2   : integer end   - relative to peptide

  Function : Provides a list of Bio::EnsEMBL::SeqFeatures which
             is the genomic coordinates of this start/end on the peptide

  Returns  : list of Bio::EnsEMBL::SeqFeature

=cut

sub pep2genomic {
  my ($self,$start,$end) = @_;

  if( !defined $end ) {
    $self->throw("Must call with start/end");
  }

  # move start end into translate cDNA coordinates now.
  # much easier!
  $start = 3* $start-2 + ($self->cdna_coding_start - 1);
  $end   = 3* $end + ($self->cdna_coding_start - 1);

  return $self->cdna2genomic( $start, $end );
}



=head2 genomic2pep

  Arg [1]    : $start
               The start position in genomic coordinates
  Arg [2]    : $end
               The end position in genomic coordinates
  Arg [3]    : $strand
               The strand of the genomic coordinates
  Arg [4]    : (optional) $contig
               The contig the coordinates are on.  This can be a slice
               or RawContig, but must be the same object in memory as
               the contig(s) of this transcripts exon(s), because of the
               use of object identity. If no contig argument is specified the
               contig of the first exon is used, which is fine for slice
               coordinates but may cause incorrect mappings in raw contig
               coords if this transcript spans multiple contigs.
  Example    : @coords = $transcript->genomic2pep($start, $end, $strand);
  Description: Converts genomic coordinates to peptide coordinates.  The
               return value is a list of coordinates and gaps.
  Returntype : list of Bio::EnsEMBL::Mapper::Coordinate and
               Bio::EnsEMBL::Mapper::Gap objects
  Exceptions : none
  Caller     : general

=cut

sub genomic2pep {
  my ($self, $start, $end, $strand, $contig) = @_;

  unless(defined $start && defined $end && defined $strand) {
    $self->throw("start, end and strand arguments are required");
  }
 
  my @coords = $self->genomic2cdna($start, $end, $strand, $contig);

  my @out;

  my $exons = $self->get_all_Exons;
  my $start_phase;
  if(@$exons) {
    $start_phase = $exons->[0]->phase;
  } else {
    $start_phase = -1;
  }

  foreach my $coord (@coords) {
    if($coord->isa('Bio::EnsEMBL::Mapper::Gap')) {
      push @out, $coord;
    } else {
      my $start = $coord->start;
      my $end   = $coord->end;
      my $cdna_cstart = $self->cdna_coding_start;
      my $cdna_cend   = $self->cdna_coding_end;
      
      if($coord->strand == -1 || $end < $cdna_cstart || $start > $cdna_cend) {
	#is all gap - does not map to peptide
	my $gap = new Bio::EnsEMBL::Mapper::Gap;
	$gap->start($start);
	$gap->end($end);
	push @out, $gap;
      } else {
	#we know area is at least partially overlapping CDS
	
	my $cds_start = $start - $cdna_cstart + 1;
	my $cds_end   = $end   - $cdna_cstart + 1;

	if($start < $cdna_cstart) {
	  #start of coordinates are in the 5prime UTR
	  my $gap = new Bio::EnsEMBL::Mapper::Gap;
	  my $gap_len = $cdna_cstart - $start;
	  $gap->start($start);
	  $gap->end($cdna_cstart - 1);
	  #start is now relative to start of CDS
	  $cds_start = 1;
	  push @out, $gap;
	} 
	
	my $end_gap = undef;
	if($end > $cdna_cend) {
	  #end of coordinates are in the 3prime UTR
	  $end_gap = new Bio::EnsEMBL::Mapper::Gap;
	  $end_gap->start($cdna_cend + 1);
	  $end_gap->end($end);
	  #adjust end to relative to CDS start
	  $cds_end = $cdna_cend - $cdna_cstart + 1;
	}

	#start and end are now entirely in CDS and relative to CDS start

	#take into account possible N padding at beginning of CDS
	my $shift = ($start_phase > 0) ? $start_phase : 0;
	
	#convert to peptide coordinates
	my $pep_start = int(($cds_start + $shift + 2) / 3);
	my $pep_end   = int(($cds_end   + $shift + 2) / 3);
	$coord->start($pep_start);
	$coord->end($pep_end);
	
	push @out, $coord;

	if($end_gap) {
	  #push out the region which was in the 3prime utr
	  push @out, $end_gap;
	}
      }	
    }
  }

  return @out;
}

    
  
  


=head2 cdna2genomic

  Arg [1]    : $start
               The start position in genomic coordinates
  Arg [2]    : $end
               The end position in genomic coordinates
  Arg [3]    : (optional) $strand
               The strand of the genomic coordinates
  Example    : @coords = $transcript->cdna2genomic($start, $end);
  Description: Converts cdna coordinates to genomic coordinates.  The
               return value is a list of coordinates and gaps.
  Returntype : list of Bio::EnsEMBL::Mapper::Coordinate and
               Bio::EnsEMBL::Mapper::Gap objects
  Exceptions : none
  Caller     : general

=cut

sub cdna2genomic {
  my ($self,$start,$end) = @_;

  if( !defined $end ) {
    $self->throw("Must call with start/end");
  }

  my $mapper = $self->_get_cdna_coord_mapper();

  return $mapper->map_coordinates( $self, $start, $end, 1, "cdna" );
}



=head2 genomic2cdna

  Arg [1]    : $start
               The start position in genomic coordinates
  Arg [2]    : $end
               The end position in genomic coordinates
  Arg [3]    : (optional) $strand
               The strand of the genomic coordinates (default value 1)
  Arg [4]    : (optional) $contig
               The contig the coordinates are on.  This can be a slice
               or RawContig, but must be the same object in memory as
               the contig(s) of this transcripts exon(s), because of the
               use of object identity. If no contig argument is specified the
               contig of the first exon is used, which is fine for slice
               coordinates but may cause incorrect mappings in raw contig
               coords if this transcript spans multiple contigs.
  Example    : @coords = $transcript->genomic2cdna($start, $end, $strnd, $ctg);
  Description: Converts genomic coordinates to cdna coordinates.  The
               return value is a list of coordinates and gaps.  Gaps
               represent intronic or upstream/downstream regions which do
               not comprise this transcripts cdna.  Coordinate objects
               represent genomic regions which map to exons (utrs included).
  Returntype : list of Bio::EnsEMBL::Mapper::Coordinate and
               Bio::EnsEMBL::Mapper::Gap objects
  Exceptions : none
  Caller     : general

=cut

sub genomic2cdna {
  my ($self, $start, $end, $strand, $contig) = @_;

  unless(defined $start && defined $end && defined $strand) {
    $self->throw("start, end and strand arguments are required\n");
  }

  #"ids" in mapper are contigs of exons, so use the same contig that should
  #be attached to all of the exons...
  $contig = $self->get_all_Exons->[0]->contig unless(defined $contig);
  my $mapper = $self->_get_cdna_coord_mapper;


  #print "MAPPING $start - $end ($strand)\n";
  #print $contig->name . "=" . $self->get_all_Exons->[0]->contig->name . "\n";

  return $mapper->map_coordinates($contig, $start, $end, $strand, "genomic");
}


=head2 _get_cdna_coord_mapper

  Args       : none
  Example    : none
  Description: creates and caches a mapper from "cdna" coordinate system to 
               "genomic" coordinate system. Uses Exons to help with that. Only
               calculates in the translateable part. 
  Returntype : Bio::EnsEMBL::Mapper( "cdna", "genomic" );
  Exceptions : none
  Caller     : cdna2genomic, pep2genomic

=cut

sub _get_cdna_coord_mapper {
  my ( $self ) = @_;

  if( defined $self->{'_exon_coord_mapper'} ) {
    return $self->{'_exon_coord_mapper'};
  }

  #
  # the mapper is loaded with OBJECTS in place of the IDs !!!!
  #  the objects are the contigs in the exons
  #
  my $mapper;
  $mapper = Bio::EnsEMBL::Mapper->new( "cdna", "genomic" );
  my @exons = @{$self->get_all_Exons() };
  my $start = 1;
  for my $exon ( @exons ) {
    $exon->load_genomic_mapper( $mapper, $self, $start );
    $start += $exon->length;
  }
  $self->{'_exon_coord_mapper'} = $mapper;
  return $mapper;
}



=head2 start_Exon

 Title   : start_Exon
 Usage   : $start_exon = $transcript->start_Exon;
 Returns : The first exon in the transcript.
 Args    : NONE

=cut

sub start_Exon{
   my ($self,@args) = @_;

   return ${$self->{'_trans_exon_array'}}[0];
}

=head2 end_Exon

 Title   : end_exon
 Usage   : $end_exon = $transcript->end_Exon;
 Returns : The last exon in the transcript.
 Args    : NONE

=cut

sub end_Exon{
   my ($self,@args) = @_;

   return ${$self->{'_trans_exon_array'}}[$#{$self->{'_trans_exon_array'}}];
}


=head2 created

 Title   : created
 Usage   : $obj->created($newval)
 Function: 
 Returns : value of created
 Args    : newvalue (optional)


=cut

sub created{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'created'} = $value;
    }
    return $obj->{'created'};

}


=head2 modified

 Title   : modified
 Usage   : $obj->modified($newval)
 Function: 
 Returns : value of modified
 Args    : newvalue (optional)


=cut

sub modified{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'modified'} = $value;
    }
    return $obj->{'modified'};

}




=head2 description

 Title   : description
 Usage   : $obj->description($newval)
 Function: 
 Returns : value of description
 Args    : newvalue (optional)


=cut

sub description{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'description'} = $value;
    }
    return $obj->{'description'};

}


=head2 version

 Title   : version
 Usage   : $obj->version()
 Function: 
 Returns : value of version
 Args    : 

=cut

sub version{

    my ($self,$value) = @_;
    

    if( defined $value ) {
      $self->{'_version'} = $value;
    }

    if( exists $self->{'_version'} ) {
      return $self->{'_version'};
    }

    $self->_get_stable_entry_info();

    return $self->{'_version'};

}


=head2 stable_id

 Title   : stable_id
 Usage   : $obj->stable_id
 Function: 
 Returns : value of stable_id
 Args    : 


=cut

sub stable_id{

    my ($self,$value) = @_;
    

    if( defined $value ) {
      $self->{'_stable_id'} = $value;
      return;
    }

    if( exists $self->{'_stable_id'} ) {
      return $self->{'_stable_id'};
    }

    $self->_get_stable_entry_info();

    return $self->{'_stable_id'};

}

sub _get_stable_entry_info {
   my $self = shift;

   if( !defined $self->adaptor ) {
     return undef;
   }

   $self->adaptor->get_stable_entry_info($self);

}

=head2 temporary_id

 Title   : temporary_id
 Usage   : $obj->temporary_id($newval)
 Function: Temporary ids are used for Genscan predictions - which should probably
           be moved over to being stored inside the gene tables anyway. Bio::EnsEMBL::TranscriptFactory use this
 Example : 
 Returns : value of temporary_id
 Args    : newvalue (optional)


=cut

sub temporary_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'temporary_id'} = $value;
    }
    return $obj->{'temporary_id'};

}





=head2 transform

  Arg  1    : hashref $old_new_exon_map
              a hash that maps old to new exons for a whole gene
  Function  : maps transcript in place to different coordinate system,
              It does so by replacing its old exons with new ones.
  Returntype: none
  Exceptions: none
  Caller    : Gene->transform()

=cut


sub transform {
  my $self = shift;
  my $href_exons = shift;
  my @mapped_list_of_exons;

  foreach my $exon (@{$self->get_all_Exons()}) {
    # the old exon was successfully remapped then store the new exon
    if ( exists $$href_exons{$exon} ) {
      push @mapped_list_of_exons, $$href_exons{$exon};
    }
    # but for the case where the exon was unable to be mapped, as it
    # was outside the bounds of the slice, include the original exon.
    else {
      push @mapped_list_of_exons, $exon;
    }
  }

  # flush the old list of exons
  $self->{'_trans_exon_array'} = [];

  # attach the new list of exons to the transcript
  push @{$self->{'_trans_exon_array'}},@mapped_list_of_exons;

  if( defined $self->{'translation'} ) {
    $self->translation->transform( $href_exons );
  }

  #invalidate the current start, end, strand - they need to be recalculated
  $self->{'_start'} = undef;
  $self->{'_end'} = undef;
  $self->{'_strand'} = undef;
  $self->{'_exon_coord_mapper'} = undef;
  $self->{'coding_start'} = undef;
  $self->{'coding_end'} = undef;
}



=head2 species

  Arg [1]    : optional Bio::Species $species
  Example    : none
  Description: You can set the species for this gene if you want to use species 
               specific behaviour. Otherwise species is retrieved from attached 
               database.
  Returntype : Bio::Species
  Exceptions : none
  Caller     : external_name, external_db, general for setting

=cut


sub species {
  my ( $self, $species ) = @_;

  if( defined $species ) {
    $self->{species} = $species;
  } else {
    if( ! exists $self->{species} ) {
      if( defined $self->adaptor() ) {
	$self->{species} = $self->adaptor()->db->get_MetaContainer()
	  ->get_Species();
      }
    }
  }
  
  return $self->{species};
}


##########################################################
#
# sub DEPRECATED METHODS FOLLOW
#
##########################################################


=head2 sub DEPRECATED methods follow
=cut

sub translateable_exons {
    my( $self ) = @_;
  
    $self->warn( "Please use get_all_translateable_Exons(). Careful as it returns listref." );
    
    return @{$self->get_all_translateable_Exons()};
}


sub finex_string {
   my ($self) = @_;

   my ($p, $f, $l) = caller;

   $self->warn( "Transcript::finex string is deprecated. Caller $f:$l\n");

   my $finex;

   if ($self->stable_id ne "") {
     $finex = $self->stable_id;
   } else {
     $finex = $self->dbID;
   }

   $finex .= " ";

   my @exons = @{$self->get_all_Exons};

   $finex .= scalar(@exons) . " ";

   if ($exons[0]->strand == 1) {
      @exons = sort {$a->start <=> $b->start} @exons;
   } else {
      @exons = sort {$b->start <=> $a->start} @exons;
   }


   my $found_start = 0;
   my $found_end   = 0;

   foreach my $exon (@exons) {
     my $length = $exon->length;

     
     if ($exon == $self->translation->start_Exon &&
	 $exon == $self->translation->end_Exon) {
       $length = $self->translation->end - $self->translation->start + 1;

       $found_start = 1;
       $found_end   = 1;

       $finex .= $exon->phase . ":" . $exon->end_phase . ":" . $length . " ";

     } elsif ($exon == $self->translation->start_Exon) {
       $length = $exon->length - $self->translation->start + 1;
       $found_start = 1;

       $finex .= $exon->phase . ":" . $exon->end_phase . ":" . $length . " ";

     } elsif ($exon == $self->translation->end_Exon) {
       $length = $self->translation->end;
       $found_end = 1;

       $finex .= $exon->phase . ":" . $exon->end_phase . ":" . $length . " ";
       
     } elsif ($found_start == 1 && $found_end == 0) {
       $length = $exon->length;

       $finex .= $exon->phase . ":" . $exon->end_phase . ":" . $length . " ";
     }
   }

   $finex =~ s/\ $//;

   return $finex;
}



sub find_coord {
  my ($self,$coord,$type) = @_;
 
  my ($p,$f,$l) = caller;
  $self->warn("$f:$l find_coord is deprecated. Use pep2genomic");

  my $count = 0;
  my @exons = @{$self->get_all_Exons};
  my $end   = $#exons;
  my $dna;

  my ($starts,$ends) = $self->pep_coords;
  my $strand = $exons[0]->strand;

  # $starts and $ends are array refs containing the _peptide_ coordinates
  # of each exon. We may have 1 missing residue that spans an intron.
  # We ignore these.

  if ($strand == 1) {
    foreach my $ex (@{$self->get_all_Exons}) {
      
      if ($coord >= $starts->[$count] && $coord <= $ends->[$count]) {
	my $dna   = $ex->start + $ex->phase;
	my $nopep = $coord - $starts->[$count];
	
	$dna += 3 * $nopep;

	if ($type eq "end") {
	  $dna += 2;
	}
	
	return $dna;
	
      } elsif ($count < $end) {
	my $endpep = $ends->[$count]+1;
	if ($endpep == $coord) {

	  my $dna;

	  if ($type eq "end") {
	    my $end_phase = $ex->end_phase;
	    $dna = $ex->end - 3 + $end_phase;
	  } else {
	    $dna = $exons[$count+1]->start + $exons[$count+1]->phase;
	  }
	  return $dna;
	}
      }
      $count++;
    }
  } else {

    foreach my $ex (@{$self->get_all_Exons}) {
      
      if ($coord >= $starts->[$count] && $coord <= $ends->[$count]) {
	
	my $dna   = $ex->end - $ex->phase;
	my $nopep = $coord - $starts->[$count];

	$dna -= 3*$nopep;

	if ($type eq "end") {
	  $dna -= 2;
	}
	
	return $dna;
	
      } elsif ($count < $end) {
	my $endpep = $ends->[$count]+1;

	if ($endpep == $coord) {
	  my $dna;

	  if ($type eq "end") {
	    my $end_phase = $ex->end_phase;
	    $dna = $ex->start + 3 - $end_phase;
	  } else {
	    $dna = $exons[$count+1]->end - $exons[$count+1]->phase;
	  }
	  return $dna;
	}
      }
      $count++;
    } 
  }
}



=head2 rna_pos

  Title   : rna_pos
  Usage   : $loc = $feat->dna_seq(23456)
  Function: Translates genomic coordinates into mRNA coordinates
            ARNE: padding probably not correct
  Returns : integer
  Args    : integer, genomic location

=cut

sub rna_pos {
    my ($self, $loc) = @_;

    my $start = $self->start_exon->start;
    #test that loc is within  mRNA
    return undef if $loc < $start;
    return undef if $loc >= $self->end_Exon->end;

    my $mrna = 1;

    my $prev = undef;
    foreach my $exon (@{$self->get_all_Exons}) {
	
	my $tmp = CORE::length( $exon->seq->seq());
	#$tmp -= $exon->phase if not $prev;

	# we now have to figure out if the phase is compatible. If it
	# is not, we need to add some stuff in...

	if( $prev ) {
	    if( $prev->end_phase != $exon->phase ) {
		if( $prev->end_phase == 0 ) {
		    if( $exon->phase == 1 ) {
			$mrna += 2;
		    }

		    if( $exon->phase == 2 ) {
			$mrna += 1;
		    }
		} elsif ( $prev->end_phase == 1 ) {
		    if( $exon->phase == 0 ) {
			$mrna += 2;
		    }
		    
		    if( $exon->phase == 2 ) {
			$mrna += 1;
		    }
		} elsif ( $prev->end_phase == 2 ) {
		    if( $exon->phase == 0 ) {
			$mrna += 1;
		    }
		    
		    if( $exon->phase == 1 ) {
			$mrna += 2;
		    }
		} else {
		    $self->warn("Impossible phases in calculating fixing stuff");
		}
	    }
	} # end of if previous is there

	if ($loc < $exon->end) {
	    return $loc - $exon->start + $mrna ;
	}
	$mrna  += $tmp;
	$prev = $exon;
    }
    #return $mrna;
}

=head2 dna_length

  Title   : dna_length
  Usage   : $loc = $feat->dna_length;
  Function: return the length of the transcript''s DNA
  Returns : integer
  Args    : nn

=cut

sub dna_length {
     my ($self) = @_;

     # # not setting:
     # if( defined $value ) {
     #      $self->{'_dna_length'} = $value;
     # }

     if (! defined $self->{'_dna_length'}) { 
         # get from dna_seq;
         $self->{'_dna_length'} = $self->dna_seq->length;         
     }
     return $self->{'_dna_length'};
}


sub pep_coords {
    my $self = shift;

    # for mapping the peptide coords back onto the dna sequence
    # it would be handy to have a list of the peptide start end coords
    # for each exon
  
    my ($p,$f,$l) = caller;
    $self->warn("$f:$l  Calls to pep_coords should no longer be necessary. Please use pep2genomic");
    my @starts;
    my @ends;
  
    my $fullpep = $self->translate()->seq;

    
    foreach my $ex ($self->translateable_exons) {

	my $tex=$ex->translate;
	

	my $pep=$tex->seq;
	$pep =~ s/X$//g;
	
	my $start = index($fullpep,$pep) + 1;
	
	my $end = $start + CORE::length($pep) - 1;
    
	push(@starts,$start);
	push(@ends,$end);
	
    }

    return \@starts,\@ends;
}



1;

__END__;
