# EnsEMBL module for MarkerFeature
# Copyright EMBL-EBI/Sanger center 2002
#
#
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Map::MarkerFeature

=head1 SYNOPSIS


=head1 DESCRIPTION

Represents a marker feature in the EnsEMBL database.  A marker feature is a 
marker which has been mapped to the genome by ePCR.  Each marker has one
marker feature per mapped location.

=cut

package Bio::EnsEMBL::Map::MarkerFeature;

use strict;
use vars qw(@ISA);

use Bio::EnsEMBL::SeqFeature;

@ISA = qw(Bio::EnsEMBL::SeqFeature);



=head2 new

  Arg [1]    : (optional) int $dbID
  Arg [2]    : (optional) Bio::EnsEMBL::Adaptor $adaptor
  Arg [3]    : (optional) int $start 
  Arg [4]    : (optional) int $end
  Arg [5]    : (optional) Bio::EnsEMBL ::RawContig or ::Slice $contig
  Arg [6]    : (optional) Bio::EnsEMBL::Analysis
  Arg [7]    : (optional) int $marker_id
  Arg [8]    : (optional) int $map_weight
  Arg [9]    : (optional) Bio::EnsEMBL::Map::Marker $marker 
  Example    : $marker = Bio::EnsEMBL::Map::MarkerFeature->new(123, $adaptor,
							       100, 200, 
							       $ctg, 123);
  Description: Creates a new MarkerFeature
  Returntype : Bio::EnsEMBL::Map::MarkerFeature
  Exceptions : none
  Caller     : general

=cut

sub new {
  my ($caller, $dbID, $adaptor, $start, $end, $contig, $analysis,
      $marker_id, $map_weight, $marker) = @_;
  
  my $class = ref($caller) || $caller;

  return bless( {
		 'dbID'        => $dbID,
		 'adaptor'     => $adaptor,
		 '_gsf_start'  => $start,
		 '_gsf_end'    => $end,
		 '_gsf_strand' => 0,
		 '_gsf_seq'    => $contig,
		 '_analysis'    => $analysis,
		 'marker_id'   => $marker_id,
		 'marker'      => $marker,
                 'map_weight'  => $map_weight }, $class);
}




=head2 dbID

  Arg [1]    : (optional) int $dbID
  Example    : $dbID = $marker_feature->dbID;
  Description: Getter/Setter for the dbID of this MarkerFeature
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub dbID {
  my $self = shift;

  if(@_) {
    $self->{'dbID'} = shift;
  }

  return $self->{'dbID'};
}



=head2 adaptor

  Arg [1]    : (optional) Bio::EnsEMBL::Map::DBSQL::MarkerFeatureAdaptor $adp
  Example    : $adaptor = $marker_feature->adaptor;
  Description: Getter/Setter for the adaptor which provides database
               database interaction for this MarkerFeature
  Returntype : Bio::EnsEMBL::Map::DBSQL::MarkerFeatureAdaptor
  Exceptions : none
  Caller     : general

=cut

sub adaptor {
  my $self = shift;
  
  if(@_) {
    $self->{'adaptor'} = shift;
  }
  
  return $self->{'adaptor'};
}



=head2 _marker_id

  Arg [1]    : (optional) int $marker_id
  Example    : none
  Description: PRIVATE Getter/Setter for the internal identifier of the marker
               associated with this marker feature
  Returntype : int
  Exceptions : none
  Caller     : internal

=cut

sub _marker_id {
  my $self = shift;

  if(@_) {
    $self->{'marker_id'} = shift;
  }

  return $self->{'marker_id'};
}



=head2 marker

  Arg [1]    : (optional) Bio::EnsEMBL::Map::Marker $marker
  Example    : $marker = $marker_feature->marker;
  Description: Getter/Setter for the marker associated with this marker feature
               If the marker has not been set and the database is available
               the marker will automatically be retrieved (lazy-loaded).
  Returntype : Bio::EnsEMBL::Map::Marker
  Exceptions : none
  Caller     : general

=cut

sub marker {
  my $self = shift;
  
  if(@_) {
    $self->{'marker'} = shift;
  } elsif(!$self->{'marker'} && $self->{'adaptor'} && $self->{'marker_id'}) {
    #lazy load the marker if it is not already loaded
    my $ma = $self->{'adaptor'}->db->get_MarkerAdaptor;
    $self->{'marker'} = $ma->fetch_by_dbID($self->{'marker_id'});
  }
      
  return $self->{'marker'};
}



=head2 map_weight

  Arg [1]    : (optional) int $map_weight
  Example    : $map_weight = $marker_feature->map_weight;
  Description: Getter/Setter for the map weight of this marker.  This is the
               number of times that this marker has been mapped to the genome.
               E.g.  a marker iwth map weight 3 has been mapped to 3 locations
               in the genome.
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub map_weight {
  my $self = shift;

  if(@_) {
    $self->{'map_weight'} = shift;
  }

  return $self->{'map_weight'};
}

1;
