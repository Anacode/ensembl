#
# Object for storing sequence analysis details
#
# Cared for by Michele Clamp  <michele@sanger.ac.uk>
#
# Copyright Michele Clamp
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Analysis.pm - Stores details of an analysis run

=head1 SYNOPSIS

    my $obj    = new Bio::EnsEMBL::Analysis::Analysis(
        -id              => $id,
        -logic_name      => 'SWIRBlast',
        -db              => $db,
        -db_version      => $db_version,
        -db_file         => $db_file,
        -program         => $program,
        -program_version => $program_version,
        -program_file    => $program_file,
        -gff_source      => $gff_source,
        -gff_feature     => $gff_feature,
        -module          => $module,
        -module_version  => $module_version,
        -parameters      => $parameters,
        -created         => $created
        );

=head1 DESCRIPTION

Object to store details of an analysis run

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::EnsEMBL::Analysis;

use vars qw(@ISA);
use strict;
use Bio::EnsEMBL::Root;

# Inherits from the base bioperl object
@ISA = qw(Bio::EnsEMBL::Root);


=head2 new

  Arg [..]   :  Takes a set of named arguments
  Example    : $analysis = new Bio::EnsEMBL::Analysis::Analysis(
                                -id              => $id,
                                -logic_name      => 'SWIRBlast',
                                -db              => $db,
                                -db_version      => $db_version,
                                -db_file         => $db_file,
                                -program         => $program,
                                -program_version => $program_version,
                                -program_file    => $program_file,
                                -gff_source      => $gff_source,
                                -gff_feature     => $gff_feature,
                                -module          => $module,
                                -module_version  => $module_version,
                                -parameters      => $parameters,
                                -created         => $created );
  Description: Creates a new Analysis object
  Returntype : Bio::EnsEMBL::Analysis
  Exceptions : none
  Caller     : general

=cut

sub new {
  my($class,@args) = @_;
  
  my $self = bless {},$class;
   
  my ($id, $adaptor, $db, $db_version, $db_file, $program, $program_version,
      $program_file, $gff_source, $gff_feature, $module, $module_version,
      $parameters, $created, $logic_name ) = 

	  $self->_rearrange([qw(ID
	  			ADAPTOR
				DB
				DB_VERSION
				DB_FILE
				PROGRAM
				PROGRAM_VERSION
				PROGRAM_FILE
				GFF_SOURCE
				GFF_FEATURE
				MODULE
				MODULE_VERSION
				PARAMETERS
				CREATED
				LOGIC_NAME
				)],@args);

  $self->dbID             ($id);
  $self->adaptor        ($adaptor);
  $self->db             ($db);
  $self->db_version     ($db_version);
  $self->db_file        ($db_file);
  $self->program        ($program);
  $self->program_version($program_version);
  $self->program_file   ($program_file);
  $self->module         ($module);
  $self->module_version ($module_version);
  $self->gff_source     ($gff_source);
  $self->gff_feature    ($gff_feature);
  $self->parameters     ($parameters);
  $self->created        ($created);
  $self->logic_name ( $logic_name );

  return $self; # success - we hope!
}


=head2 adaptor

  Arg [1]    : Bio::EnsEMBL::DBSQL::AnalysisAdaptor $analysis_adaptor
  Example    : none
  Description: get/set for thus objects Adaptor
  Returntype : Bio::EnsEMBL::DBSQL::AnalysisAdaptor
  Exceptions : none
  Caller     : general, set from adaptor on store

=cut

sub adaptor {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_adaptor} = $arg;
    }
    return $self->{_adaptor};
}


=head2 dbID

  Arg [1]    : int $dbID
  Example    : none
  Description: get/set for the database internal id
  Returntype : int
  Exceptions : none
  Caller     : general, set from adaptor on store

=cut

sub dbID {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_dbid} = $arg;
    }
    return $self->{_dbid};
}


=head2 db

  Arg [1]    : string $db
  Example    : none
  Description: get/set for the attribute db
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub db {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_db} = $arg;
    }

    return $self->{_db};
}


=head2 db_version

  Arg [1]    : string $db_version
  Example    : none
  Description: get/set for attribute db_version
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub db_version {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_db_version} = $arg;
    }

    return $self->{_db_version};
}


=head2 db_file

  Arg [1]    : string $db_file
  Example    : none
  Description: get/set for attribute db_file
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub db_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_db_file} = $arg;
    }

    return $self->{_db_file};
}



=head2 program

  Arg [1]    : string $program
  Example    : none
  Description: get/set for attribute program
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub program {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_program} = $arg;
    }

    return $self->{_program};
}


=head2 program_version

  Arg [1]    : string $program_version
  Example    : none
  Description: get/set for attribute program_version
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub program_version {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_program_version} = $arg;
    }

    return $self->{_program_version};
}


=head2 program_file

  Arg [1]    : string $program_file
  Example    : none
  Description: get/set for attribute program_file
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub program_file {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_program_file} = $arg;
    }

    return $self->{_program_file};
}


=head2 module

  Arg [1]    : string $module
  Example    : none
  Description: get/set for attribute module. Usually a RunnableDB perl 
               module that executes this analysis job. 
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub module {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_module} = $arg;
    }

    return $self->{_module};
}


=head2 module_version

  Arg [1]    : string $module_version
  Example    : none
  Description: get/set for attribute module_version
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub module_version {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_module_version} = $arg;
    }

    return $self->{_module_version};
}


=head2 gff_source

  Arg [1]    : string $gff_source
  Example    : none
  Description: get/set for attribute gff_source
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub gff_source {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_gff_source} = $arg;
    }

    return $self->{_gff_source};
}


=head2 gff_feature

  Arg [1]    : string $gff_feature
  Example    : none
  Description: get/set for attribute gff_feature
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub gff_feature {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_gff_feature} = $arg;
    }

    return $self->{_gff_feature};
}


=head2 parameters

  Arg [1]    : string $parameters
  Example    : none
  Description: get/set for attribute parameters. This should be evaluated
               by the module if given or the program that is specified.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub parameters {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_parameters} = $arg;
    }

    return $self->{_parameters};
}


=head2 created

  Arg [1]    : string $created
  Example    : none
  Description: get/set for attribute created time.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub created {
    my ($self,$arg) = @_;

    if (defined($arg)) {
	$self->{_created} = $arg;
    }

    return $self->{_created};
}


=head2 logic_name

  Arg [1]    : string $logic_name
  Example    : none
  Description: Get/set method for the logic_name, the name under 
               which this typical analysis is known.
  Returntype : string
  Exceptions : none
  Caller     : general

=cut

sub logic_name {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ($self->{_logic_name} = $arg);
  $self->{_logic_name};
}


=head2 has_database

  Args       : none
  Example    : none
  Description: tests if the db attribute is set, returns 1 if so,
               0 if not.
  Returntype : int 0,1
  Exceptions : none
  Caller     : general

=cut

sub has_database{
   my ($self,@args) = @_;

   if( defined $self->db ){ return 1; }
   return 0;
}


=head2 compare

  Arg  1     : Bio::EnsEMBL::Analysis $ana
               The analysis to compare to
  Example    : none
  Description: returns 1 if this analysis is special case of given analysis
               returns 0 if they are equal
	       returns -1 if they are completely different
  Returntype : int -1,0,1
  Exceptions : none
  Caller     : unknown

=cut

sub compare {
  my ($self, $ana ) = @_;
  
  $self->throw("Object is not a Bio::EnsEMBL::Analysis") 
    unless $ana->isa("Bio::EnsEMBL::Analysis");
  
  my $detail = 0;

  foreach my $methodName ( 'program', 'program_version', 'program_file',
    'db','db_version','db_file','gff_source','gff_feature', 'module',
    'module_version', 'parameters','logic_name' ) {
    if( defined $self->$methodName() && ! $ana->can($methodName )) {
      $detail = 1;
    } 
    if( defined $self->$methodName() && ! defined $ana->$methodName() ) {
      $detail = 1;
    } 
    # if given anal is different from this, defined or not, then its different
    if( defined $ana->$methodName() &&
          ( $self->$methodName() ne $ana->$methodName() )) {
      return -1;
    }
  }
  if( $detail == 1 ) { return 1 };
  return 0;
}

  

=head2 id

  Arg        : none
  Example    : none
  Description: deprecated function, use dbID instead
  Returntype : none
  Exceptions : none
  Caller     : none

=cut

sub id {
    my ($self,$arg) = @_;
    $self->warn( "Analysis->id is deprecated. Use dbID!" );
    print STDERR caller;
    
    if (defined($arg)) {
	$self->{_dbid} = $arg;
    }
    return $self->{_dbid};
}
  



1;
















