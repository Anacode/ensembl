# EnsEMBL module for conversion of objects between EnsEMBL and other project, such as BioPerl
#
# Created and Cared for by Juguang Xiao <juguang@fugu-sg.org>
#
# Copyright Juguang Xiao
# 
# You may distribute this module under the same terms as perl itself
#
# POD documentation
#

=head1 NAME

Bio::EnsEMBL::Utils::Converter, a converter factory

=head1 SYNOPSIS

    my $converter = Bio::EnsEMBL::Utils::Converter->new(
        -in => 'Bio::SeqFeature::Generic',
        -out => 'Bio::EnsEMBL::SimpleFeature'
    );

    my ($fearture1, $feature2);
    my $ens_simple_features = $converter->convert([$feature1, $feature2]);
    my @ens_simple_features = @{$ens_simple_features};

=head1 DESCRIPTION
    
    Module to converter the business objects between EnsEMBL and any other projects, currently BioPerl.

=head1 FEEDBACK


=head1 AUTHOR - Juguang Xiao

Juguang Xiao <juguang@fugu-sg.org>

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut

# Let the code begin ...


package Bio::EnsEMBL::Utils::Converter;

use strict;
use vars qw(@ISA);

use Bio::EnsEMBL::Root;

@ISA =qw(Bio::EnsEMBL::Root);

=head2 new
  Title   : new
  Usage   : 
        my $converter = Bio::EnsEMBL::Utils::Converter->new(
            -in => 'Bio::SeqFeature::Generic',
             -out => 'Bio::EnsEMBL::SimpleFeature'
         );

  Function: constructor for converter object
  Returns : L<Bio::EnsEMBL::Utils::Converter>
  Args    : 
    in - the module name of the input.
    out - the module name of the output.
    analysis - a Bio::EnsEMBL::Analysis object, if converting other objects to EnsEMBL features.
    contig - a Bio::EnsEMBL::RawContig object, if converting other objects to EnsEMBL features.

=cut

sub new {
    my ($caller, @args) = @_;
    my $class = ref($caller) || $caller;
    
    if($class =~ /Bio::EnsEMBL::Utils::Converter::(\S+)/){
        my $self = $class->SUPER::new(@args);
        $self->_initialize(@args);
        return $self;
    }else{
        my %params = @args;
        @params{map {lc $_} keys %params} = values %params;
        my $module = $class->_guess_module($params{-in}, $params{-out});

        return undef unless($class->_load_module($module));
        return "$module"->new(@args);
    }
}

# This would be invoked by sub-module's _initialize.

sub _initialize {
    my ($self, @args) = @_;
    
    my ($in, $out) = $self->_rearrange([qw(IN OUT)], @args);

    $self->in($in);
    $self->out($out);
}

=head2 _guess_module
  Usage   : $module = $class->_guess_module(
    'Bio::EnsEMBL::SimpleFeature',
    'Bio::EnsEMBL::Generic'
  );
=cut

sub _guess_module {
    my ($self, $in, $out) = @_;
    if($in =~ /^Bio::EnsEMBL::(\S+)/ and $out =~ /^Bio::EnsEMBL::(\S+)/){
        $self->throw("Cannot convert between EnsEMBL objects.\n[$in] to [$out]");
    }elsif($in =~ /^Bio::EnsEMBL::(\S+)/){
        return 'Bio::EnsEMBL::Utils::Converter::ens_bio';
    }elsif($out =~ /^Bio::EnsEMBL::(\S+)/){
        return 'Bio::EnsEMBL::Utils::Converter::bio_ens';
    }else{
        $self->throw("Cannot convert between non-EnsEMBL objects.\n[$in] to [$out]");
    }
}

=head2 convert
    Title   : convert
    Usage   : my $array_ref = $converter->convert(\@input);
    Function: does the actual conversion
    Returns : an array ref of converted objects
    Args    : an array ref of converting objects

=cut

sub convert{
    my ($self, $input) = @_;

    $input || $self->throw("Need a ref of array of input objects to convert");
    
    my $output_module = $self->out;
    $self->throw("Cannot load [$output_module] perl module") 
        unless $self->_load_module($output_module);

    unless(ref($input) eq 'ARRAY'){
        $self->warn("The input is supposed to be an array ref");
        return $self->_convert_single($input);
    }

    my @output = ();
    foreach(@{$input}){
        push(@output, $self->_convert_single($_));
    }

    return \@output;
}

sub _converter_single{
    my ($self, $input) = @_;
    $self->throw("Not implemented. Please check the instance subclass");
}

=head2 in

  Title     : in
  Useage    : $self->in
  Function  : get and set for in
  Return    : 
  Args      : 

=cut 

sub in {
    my($self, $arg) = @_;
    if(defined($arg)){
        $self->{_in} = $arg;
    }
    return $self->{_in};
}

=head2 out

  Title     : out
  Useage    : $self->out
  Function  : get and set for out
  Return    : 
  Args      : 

=cut 

sub out {
    my($self, $arg) = @_;
    if(defined($arg)){
        $self->{_out} = $arg;
    }
    return $self->{_out};
}

=head2 analysis

  Title     : analysis
  Useage    : $self->analysis
  Function  : get and set for analysis
  Return    : L<Bio::EnsEMBL::Analysis>
  Args      : L<Bio::EnsEMBL::Analysis>

=cut 

sub analysis {
    my($self, $arg) = @_;
    if(defined($arg)){
        $self->throws("A Bio::EnsEMBL::Analysis object expected.") unless(defined $arg);
        $self->{_analysis} = $arg;
    }
    return $self->{_analysis};
}

=head2 contig

  Title     : contig
  Useage    : $self->contig
  Function  : get and set for contig
  Return    : L<Bio::EnsEMBL::RawContig>
  Args      : L<Bio::EnsEMBL::RawContig>

=cut 

sub contig {
    my($self, $arg) = @_;
    if(defined($arg)){
        $self->throws("A Bio::EnsEMBL::RawContig object expected.") unless(defined $arg);
        $self->{_contig} = $arg;
    }
    return $self->{_contig};
}

sub _getset {
    my ($self, $tag, $value, $type) = @_;
    
    $tag || $self->throw("a tag needed");
    
    if(defined($value)){
        $self->{_$tag} = $value;
    }
    return $self->{_$tag};
}

sub getset{
    my ($self, $arg) = @_;
    return $self->_getset('getset', $arg);
}

=head2 _load_module
  This method is copied from Bio::Root::Root
=cut

sub _load_module {
    my ($self, $name) = @_;
    my ($module, $load, $m);
    $module = "_<$name.pm";
    return 1 if $main::{$module};

    # untaint operation for safe web-based running (modified after a fix
    # a fix by Lincoln) HL
    if ($name !~ /^([\w:]+)$/) {
        $self->throw("$name is an illegal perl package name");
    }

    $load = "$name.pm";
    my $io = Bio::Root::IO->new();
    # catfile comes from IO
    $load = $io->catfile((split(/::/,$load)));
    eval {
        require $load;
    };
    if ( $@ ) {
        $self->throw("Failed to load module $name. ".$@);
    }
    return 1;
}

1;
