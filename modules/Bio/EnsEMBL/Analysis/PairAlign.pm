#
# BioPerl module for PairAlign object
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

PairAlign - Dna pairwise alignment module

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Contains list of sub alignments making up a dna-dna alignment

Creation:
   
    my $genomic = new Bio::EnsEMBL::SeqFeature(-start  => $qstart,
					       -end    => $qend,
					       -strand => $qstrand);

    my $cdna     = new Bio::EnsEMBL::SeqFeature(-start => $hstart,
						-end   => $hend,
						-strand => $hstrand);

    my $pair     = new Bio::EnsEMBL::FeaturePair(-feature1 => $genomic,
						 -feature2 => $cdna,
						 );

    my $pairaln   = new Bio::EnsEMBL::Analysis::PairAlign;
       $pairaln->addFeaturePair($pair);

Any number of pair alignments can be added to the PairAlign object


Manipulation:

To convert between coordinates : 

    my $cdna_coord = $pair->genomic2cDNA($gen_coord);
    my $gen_coord  = $pair->cDNA2genomic($cdna_coord);

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::EnsEMBL::Analysis::PairAlign;

use vars qw(@ISA);
use strict;


@ISA = qw(Bio::EnsEMBL::Root);

sub new {
    my($class,@args) = @_;
    my $self = {};
    bless $self, $class;

    $self->{'_homol'} = [];
    
    return $self; # success - we hope!
}

sub addFeaturePair {
    my ($self,$pair) = @_;

    $self->throw("Not a Bio::EnsEMBL::FeaturePair object") unless ($pair->isa("Bio::EnsEMBL::FeaturePair"));

    push(@{$self->{'_pairs'}},$pair);
    
}


=head2 eachFeaturePair

 Title   : eachFeaturePait
 Usage   : my @pairs = $pair->eachFeaturePair
 Function: 
 Example : 
 Returns : Array of Bio::SeqFeature::FeaturePair
 Args    : none


=cut

sub eachFeaturePair {
    my ($self) = @_;

    if (defined($self->{'_pairs'})) {
	return @{$self->{'_pairs'}};
    }
}

sub get_hstrand {
    my ($self) = @_;

    my @features = $self->eachFeaturePair;

    return $features[0]->hstrand;
}

=head2 genomic2cDNA

 Title   : genomic2cDNA
 Usage   : my $cdna_coord = $pair->genomic2cDNA($gen_coord)
 Function: Converts a genomic coordinate to a cdna coordinate
 Example : 
 Returns : int
 Args    : int


=cut

sub genomic2cDNA {
    my ($self,$coord) = @_;
    my @pairs = $self->eachFeaturePair;

    @pairs = sort {$a->start <=> $b->start} @pairs;
    
#    print STDERR "In genomic2cDNA converting : $coord\n";

    my $newcoord;

  HOMOL: while (my $sf1 = shift(@pairs)) {
#      print STDERR "Comparing to genomic exon " . $sf1->start . "\t" . $sf1->end . "\t" . $sf1->strand . "\n";
#      print STDERR "Comparing to cDNA    exon " . $sf1->hstart . "\t" . $sf1->hend . "\t" . $sf1->hstrand . "\n";
      next HOMOL unless ($coord >= $sf1->start && $coord <= $sf1->end);
      
      if ($sf1->strand == 1 && $sf1->hstrand == 1) {
	  $newcoord = $sf1->hstart + ($coord - $sf1->start);
	  last HOMOL;
      } elsif ($sf1->strand == 1 && $sf1->hstrand == -1) {
	  $newcoord = $sf1->hend   - ($coord - $sf1->start);
	  last HOMOL;
      } elsif ($sf1->strand == -1 && $sf1->hstrand == 1) {
	  $newcoord = $sf1->hstart + ($sf1->end - $coord);
	  last HOMOL;
      } elsif ($sf1->strand == -1 && $sf1->hstrand == -1) {
	  $newcoord = $sf1->hend   - ($sf1->end - $coord);
	  last HOMOL;
      } else {
	  $self->throw("ERROR: Wrong strand value in FeaturePair (" . $sf1->strand . "/" . $sf1->hstrand . "\n");
      }
  }    

    if (defined($newcoord)) {
#	print STDERR " - Found new cdna coord $newcoord\n";
	return $newcoord;
    } else {
	$self->throw("Couldn't convert $coord");
    }
}

=head2 cDNA2genomic

 Title   : cDNA2genomic
 Usage   : my $gen_coord = $pair->genomic2cDNA($cdna_coord)
 Function: Converts a cdna coordinate to a genomic coordinate
 Example : 
 Returns : int
 Args    : int


=cut

sub cDNA2genomic {
    my ($self,$coord) = @_;
#    print STDERR " - In cdna2genomic converting " . $coord . "\n";
    my @pairs = $self->eachFeaturePair;

    my $newcoord;

  HOMOL: while (my $sf1 = shift(@pairs)) {
#      print STDERR " - Comparing to " . $sf1->hstart . "\t" . $sf1->hend . "\t" . $sf1->hstrand . "\n";
#      print STDERR " - Genomic coords " . $sf1->start . "\t" . $sf1->end . "\t" . $sf1->strand . "\n";
      next HOMOL unless ($coord >= $sf1->hstart && $coord <= $sf1->hend);

      if ($sf1->strand == 1 && $sf1->hstrand == 1) {
	  $newcoord = $sf1->start + ($coord - $sf1->hstart);
	  last HOMOL;
      } elsif ($sf1->strand == 1 && $sf1->hstrand == -1) {
	  $newcoord = $sf1->start  +($sf1->hend - $coord);
	  last HOMOL;
      } elsif ($sf1->strand == -1 && $sf1->hstrand == 1) {
	  $newcoord = $sf1->end   - ($coord - $sf1->hstart);
	  last HOMOL;
      } elsif ($sf1->strand == -1 && $sf1->hstrand == -1) {
	  $newcoord = $sf1->end   - ($sf1->hend - $coord);
	  last HOMOL; 
      } else {
	  $self->throw("ERROR: Wrong strand value in homol (" . $sf1->strand . "/" . $sf1->hstrand . "\n");
      }
  }

    if (defined ($newcoord)) {
#	print STDERR " - Found new coord $newcoord\n";
	return $newcoord;
    } else {
	$self->throw("Couldn't convert $coord\n");
    }
}

sub find_Pair {
    my ($self,$coord) = @_;

    foreach my $p ($self->eachFeaturePair) {
	if ($coord >= $p->hstart && $coord <= $p->hend) {
	    return $p;
	}
    }
}

=head2 convert_cDNA_feature

 Title   : convert_cDNA_feature
 Usage   : my @newfeatures = $self->convert_cDNA_feature($f);
 Function: Converts a feature on the cDNA into an array of 
           features on the genomic (for features that span across introns);
 Example : 
 Returns : @Bio::EnsEMBL::FeaturePair
 Args    : Bio::EnsEMBL::FeaturePair

=cut

sub convert_cDNA_feature {
    my ($self,$feature) = @_;

    $self->throw("Feature is not a Bio::EnsEMBL::SeqFeature") unless
	$feature->isa("Bio::EnsEMBL::SeqFeature");

    my $foundstart = 0;
    my $foundend   = 0;

    my @pairs = $self->eachFeaturePair;
    my @newfeatures;

#    print STDERR "In convert_cDNA_feature: converting " . $feature->start . "\t" . $feature->end . "\t" . $feature->strand ."\n";
#    print STDERR "Finding the start exon\n";

  HOMOL: while (my $sf1 = shift(@pairs)) {

#      print STDERR "Looking at cDNA exon " . $sf1->hstart . "\t" . $sf1->hend . "\t" . $sf1->strand ."\n";

      next HOMOL unless ($feature->start >= $sf1->hstart && $feature->start <= $sf1->hend);

      if ($feature->end >= $sf1->hstart && $feature->end <= $sf1->hend) {
	  $foundend = 1;
      }

      my $startcoord = $self->cDNA2genomic($feature->start);
      my $endcoord;

      if ($sf1->hstrand == 1) {
	  $endcoord   = $sf1->end;
      } else {
	  $endcoord   = $sf1->start;
      }

      if ($foundend) {
	  $endcoord = $self->cDNA2genomic($feature->end);
      }

#      print STDERR "Making new genomic feature $startcoord\t$endcoord\n";

      my $tmpf = new Bio::EnsEMBL::SeqFeature(-seqname => $feature->seqname,
					      -start   => $startcoord,
					      -end     => $endcoord,
					      -strand  => $feature->strand);
      push(@newfeatures,$tmpf);
      last;
  }

    # Now the rest of the pairs until we find the endcoord

    while ((my $sf1 = shift(@pairs)) && ($foundend == 0)) {

	if ($feature->end >= $sf1->hstart && $feature->end <= $sf1->hend) {
	    $foundend = 1;
	}

	my $startcoord;
	my $endcoord;

	if ($sf1->hstrand == 1) {
	    $startcoord = $sf1->start;
	    $endcoord   = $sf1->end;
	} else {
	    $startcoord = $sf1->end;
	    $endcoord   = $sf1->start;
	}

	if ($foundend) {
	    $endcoord = $self->cDNA2genomic($feature->end);
	}

#	print STDERR "Making new genomic feature $startcoord\t$endcoord\n";

	my $tmpf = new Bio::EnsEMBL::SeqFeature(-seqname => $feature->seqname,
						-start   => $startcoord,
						-end     => $endcoord,
						-strand  => $feature->strand);
	push(@newfeatures,$tmpf);
    }
    return @newfeatures;
}


sub convert_FeaturePair {
    my ($self,$pair) = @_;

    my $hstrand = $self->get_hstrand;
    my @newfeatures = $self->convert_cDNA_feature($pair->feature1);
    my @newpairs;

    my $hitpairaln  = new Bio::EnsEMBL::Analysis::PairAlign;
       $hitpairaln->addFeaturePair($pair);

    foreach my $new (@newfeatures) {

#	print(STDERR "New " . $new->start  . "\t" . 
#	                      $new->end    . "\t" . 
#	                      $new->strand . "\n");

	#Now we want to convert these cDNA coords into hit coords

	my $hstart1 = $self->genomic2cDNA($new->start);
	my $hend1   = $self->genomic2cDNA($new->end);

#	print (STDERR "New hit start/end " . $hstart1 . "\t" . 
#	                                     $hend1   . "\n");

	my $hstart2 = $hitpairaln->genomic2cDNA($hstart1);
	my $hend2   = $hitpairaln->genomic2cDNA($hend1);

#	print (STDERR "Feature start/end " . $hstart2 . "\t" . 
#	                                     $hend2   . "\n");

	# We can now put the final feature together

	my $finalstrand = $hstrand * $pair->feature1->strand * $pair->feature2->strand;
#	print ("Final strand is $finalstrand : $hstrand " . $pair->feature1->strand . "\t" . $pair->feature2->strand . "\n");
	my $final1 = new Bio::EnsEMBL::SeqFeature(-start => $new->start,
						  -end   => $new->end,
						  -strand => 1);

        if ($hstart2 > $hend2) {
	   my $tmp = $hstart2;
	   $hstart2 = $hend2;
           $hend2   = $tmp;
        }

	my $final2 = new Bio::EnsEMBL::SeqFeature(-start => $hstart2,
						  -end   => $hend2,
						  -strand => $finalstrand);

	$final1->score($pair->score);
	$final2->score($pair->score);

	my $finalpair = new Bio::EnsEMBL::FeaturePair(-feature1 => $final1,
						      -feature2 => $final2);
	

	push(@newpairs,$finalpair);
	
    }

    return @newpairs;
}


1;








