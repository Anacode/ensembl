# EnsEMBL module for MarkerFeatureAdaptor
# Copyright EMBL-EBI/Sanger center 2003
#
#
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Map::DBSQL::MarkerFeatureAdaptor

=head1 SYNOPSIS


=head1 DESCRIPTION

This object is responisble for all database interaction involving marker
features including the fetching and storing of marker features.

The bulk of this objects methods are inherited from 
Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor


=cut

package Bio::EnsEMBL::Map::DBSQL::MarkerFeatureAdaptor;

use strict;

use Bio::EnsEMBL::Map::MarkerFeature;
use Bio::EnsEMBL::Map::Marker;
use Bio::EnsEMBL::Map::MarkerSynonym;
use Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor;

use vars qw(@ISA);

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseFeatureAdaptor);



=head2 fetch_all_by_Marker

  Arg [1]    : Bio::EnsEMBL::Map::Marker
  Example    : @ms = @{$marker_feature_adaptor->fetch_by_Marker($mrkr)};
  Description: Retrieves a list of MarkerFeatures for a given marker
  Returntype : listref of Bio::EnsEMBL::MarkerFeatures
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_by_Marker {
  my $self = shift;
  my $marker = shift;
  
  my $constraint = 'm.marker_id = ' . $marker->dbID;
  
  return $self->generic_fetch($constraint, @_);
}


=head2 fetch_all_by_Slice_and_priority

  Arg [1]    : Bio::EnsEMBL::Slice $slice
  Arg [2]    : (optional) int $priority
  Arg [3]    : (optional) string $logic_name
  Example    : @feats = @{$mfa->fetch_all_by_Slice_and_priority($slice,80)};
  Description: Retrieves all marker features above a specified threshold 
               priority which overlap the provided slice.
  Returntype : listref of Bio::EnsEMBL::Map::MarkerFeatures in slice coords
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_by_Slice_and_priority {
  my ($self, $slice, $priority, @args) = @_;

  my $constraint = '';
  if(defined $priority) {
    $constraint = "m.priority > $priority";
  }

  return $self->fetch_all_by_Slice_constraint($constraint, @args);
}


=head2 fetch_all_by_RawContig_and_priority

  Arg [1]    : Bio::EnsEMBL::RawContig $contig
  Arg [2]    : (optional) int $priority
  Arg [3]    : (optional) string $logic_name
  Example    : @feats = @{$mfa->fetch_all_by_RawContig_and_priority($ctg, 80)};
  Description: Retrieves all marker features above a specified threshold
               priority which overlap the provided slice.
  Returntype : listref of Bio::EnsEMBL::Map::MarkerFeatures in contig coords
  Exceptions : none
  Caller     : general

=cut

sub fetch_all_by_RawContig_and_priority {
  my ($self, $contig, $priority, @args) = @_;

  my $constraint;
  if(defined $constraint) {
    $constraint = "m.priority > $priority";
  }
  
  return $self->fetch_all_by_RawContig_constraint($constraint, @args);
}



sub fetch_all_by_RawContig_and_score {
  my $self = shift;
  $self->throw('fetch_all_by_RawContig_and_score should not be used to fetch' .
           ' marker features');
}

sub fetch_all_by_Slice_and_score {
  my $self = shift;
  $self->throw('fetch_all_by_Slice_and_score should not be used to fetch' .
	       ' marker_features');
}

sub _columns {
  my $self = shift;

  return ('mf.marker_feature_id', 'mf.marker_id', 
	  'mf.contig_id', 'mf.contig_start', 'mf.contig_end', 
	  'mf.contig_strand', 'mf.analysis_id', 'mf.map_weight',
	  'm.left_primer', 'm.right_primer', 'm.min_primer_dist', 
	  'm.max_primer_dist', 'm.priority', 'ms.marker_synonym_id',
	  'ms.name', 'ms.source');
}

sub _tables {
  my $self = shift;

  return (['marker_feature', 'mf'], #primary table
	  ['marker', 'm'],
	  ['marker_synonym', 'ms']);
}

sub _left_join {
  my $self = shift;

  return ('marker_synonym', 
	  'ON m.display_marker_synonym_id = ms.marker_synonym_id');
}
          
sub _default_where_clause {
  my $self = shift;

  return ('mf.marker_id = m.marker_id');
}

sub _objs_from_sth {
  my $self = shift;
  my $sth  = shift;

  my ($marker_feature_id, $marker_id, 
      $contig_id, $contig_start, $contig_end, $contig_strand,
      $analysis_id, $map_weight,
      $left_primer, $right_primer, $min_primer_dist, $max_primer_dist, 
      $priority, $ms_id, $ms_name, $ms_source);

  #warning: ordering depends on _columns function implementation
  $sth->bind_columns(\$marker_feature_id, \$marker_id, 
      \$contig_id, \$contig_start, \$contig_end, \$contig_strand,
      \$analysis_id, \$map_weight,
      \$left_primer, \$right_primer, \$min_primer_dist, \$max_primer_dist,
      \$priority, \$ms_id, \$ms_name, \$ms_source);

  my @out = ();

  my %marker_cache;
  my %contig_cache;
  my %analysis_cache;
  my $marker_adp = $self->db->get_MarkerAdaptor;
  while($sth->fetch) {

    #create a new marker unless this one has been seen already
    my $marker;
    unless($marker = $marker_cache{$marker_id}) {
      #create a new marker synonym for the display synonym (if defined)
      my $ms;
      if($ms_id) {
	my $ms = Bio::EnsEMBL::Map::MarkerSynonym->new
	  ($ms_id, $ms_source, $ms_name);
      }

      #create a new marker
      $marker = Bio::EnsEMBL::Map::Marker->new
	($marker_id, $marker_adp, 
	 $left_primer, $right_primer, $min_primer_dist, $max_primer_dist, 
	 $priority, [], $ms);
      $marker_cache{$marker_id} = $marker;
    }

    #retrieve the contig from the database
    my $contig;
    unless($contig = $contig_cache{$contig_id}) {
      $contig = $self->db->get_RawContigAdaptor->fetch_by_dbID($contig_id);
      $contig_cache{$contig_id} = $contig;
    }

    #retrieve analysis
    my $analysis;
    unless($analysis = $analysis_cache{$analysis_id}) {
      $analysis = $self->db->get_AnalysisAdaptor->fetch_by_dbID($analysis_id);
      $analysis_cache{$analysis_id} = $analysis;
    }

    #now create a new marker_feature using the marker
    push @out, Bio::EnsEMBL::Map::MarkerFeature->new
      ($marker_feature_id, $self, 
       $contig_start, $contig_end, $contig_strand, $contig, 
       $analysis, $marker_id, $map_weight, $marker);
  }

  return \@out;
}




=head2 store

  Arg [1]    : Bio::EnsEMBL::Map::MarkerFeature
  Example    : $marker_feature_adaptor->store($marker_feature);
  Description: Stores a marker feature in this database and returns the 
               dbID of the newly stored feature on success.  The dbID and
               adaptor will also be set on successful storing.
  Returntype : int
  Exceptions : thrown if not all data needed for storing is populated in the
               marker feature
  Caller     : general

=cut

sub store {
  my $self = shift;
  my $mf = shift;

  #
  # Sanity checking!
  #
  unless($mf && ref $mf && $mf->isa('Bio::EnsEMBL::Map::MarkerFeature')) {
    $self->throw('Incorrect argument [$mf] to store.  Expected ' .
		 'Bio::EnsEMBL::Map::MarkerFeature');
  }

  #don't store this feature if it has already been stored
  return $mf->dbID if($mf->adaptor == $self);
    
  my $marker = $mf->marker;

  unless($marker && ref $marker && $marker->isa('Bio::EnsEMBL::Map::Marker')) {
    $self->throw('Cannot store MarkerFeature without an associated Marker');
  }

  my $marker_id = $marker->dbID;
  unless($marker_id) {
    $self->throw('Associated marker must have dbID to store MarkerFeature');
  }


  my $analysis = $mf->analysis;

  unless($analysis && ref $analysis && 
	 $analysis->isa('Bio::EnsEMBL::Analysis')) {
    $self->throw('Cannot store MarkerFeature without an associated Analysis');
  }

  my $analysis_id = $analysis->dbID;

  unless($analysis_id) {
    $self->throw('Associated analysis must have dbID to store MarkerFeature');
  }

  my $contig = $mf->contig;

  unless($contig && ref $contig && $contig->isa('Bio::EnsEMBL::RawContig')) {
    $self->throw('Cannot store MarkerFeature that is not in contig coords');
  }

  my $contig_id = $contig->dbID;

  unless($contig_id) {
    $self->throw('Attached contig must have dbID to store MarkerFeature');
  }

  #
  # Everything looks ok so store
  #

  my $sth = 
    $self->prepare("INSERT INTO marker_feature (marker_id,
                           contig_id, contig_start, contig_end, contig_strand,
                           analysis_id, map_weight)
                    VALUES (?, ?, ?, ?, ?, ?, ?)");
  $sth->execute($marker_id, 
		$contig_id, $mf->start,$mf->end,$mf->strand,
		$analysis_id,0);

  my $dbID = $sth->{'mysql_insertid'};
                                        
  $mf->dbID($dbID);
  $mf->adaptor($self);

  return $dbID;
}


1;
