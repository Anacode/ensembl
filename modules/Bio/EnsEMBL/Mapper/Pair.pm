
#
# Ensembl module for Bio::EnsEMBL::Mapper::Pair
#
# Written by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright GRL and EBI
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Mapper::Pair

=head1 SYNOPSIS

=head1 DESCRIPTION

Two regions mapped between different coordinate systems are
each represented by a Bio::EnsEMBL::Mapper::Unit and joined
together as a Bio::EnsEMBL::Mapper::Pair.

=head1 AUTHOR - Ewan Birney

This module is part of the Ensembl project http://www.ensembl.org

Post general queries to B<ensembl-dev@ebi.ac.uk>

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::Mapper::Pair;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

# new() is written here 

sub new {
  my($class,@args) = @_;

    my $self = {};
    bless $self,$class;

# set stuff in self from @args
    return $self;
}


=head2 from, to

  Arg  1      Bio::EnsEMBL::Mapper::Unit $seqobj
	      from and to represent the two regions
	      which are mapped to each other
  Function    accessor method
  Returntype  Bio::EnsEMBL::Mapper::Unit
  Exceptions  none
  Caller      Bio::EnsEMBL::Mapper::Pair

=cut

sub to {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'to'} = $value;
    }
    return $self->{'to'};

}

sub from {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'from'} = $value;
    }
    return $self->{'from'};

}


=head2 ori

  Arg  1      Bio::EnsEMBL::Mapper::Unit $ori
  Function    accessor method
	      relative orientation of the the
	      two mapped regions
  Returntype  Bio::EnsEMBL::Mapper::Unit
  Exceptions  none
  Caller      Bio::EnsEMBL::Mapper::Pair

=cut

sub ori {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'ori'} = $value;
    }
    return $self->{'ori'};

}

1;
