
#
# Ensembl module for Bio::EnsEMBL::DBSQL::SliceAdaptor
#
# Cared for by Ewan Birney <ensembl-dev@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::DBSQL::SliceAdaptor - Adaptors for slices

=head1 SYNOPSIS
  



=head1 DESCRIPTION

Factory for getting out slices of assemblies. WebSlice is the highly
accelerated version for the web site.

=head1 AUTHOR - Ewan Birney

This modules is part of the Ensembl project http://www.ensembl.org

Email ensembl-dev@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::DBSQL::SliceAdaptor;
use vars qw(@ISA);
use strict;


# Object preamble - inherits from Bio::EnsEMBL::Root
use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::DBSQL::DBAdaptor;


@ISA = ('Bio::EnsEMBL::DBSQL::BaseAdaptor');


# new is inherited from BaseAdaptor



=head2 fetch_by_chr_start_end

  Arg [1]    : string $chr
               the name of the chromosome to obtain a slice for
  Arg [2]    : int $start
               the start basepair of the slice to obtain in chromosomal 
               coordinates
  Arg [3]    : int $end 
               the end basepair of the slice to obtain in chromosomal 
               coordinates
  Example    : $slice = $slice_adaptor->fetch_by_chr_start_end();
  Description: Creates a slice object on the given chromosome and coordinates.
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_chr_start_end {
    my ($self,$chr,$start,$end) = @_;

    unless($chr) {
      $self->throw("chromosome name argument must be defined and not ''");
    }

    unless(defined $end) {   # Why defined?  Is '0' a valid end?
      $self->throw("end argument must be defined\n");
    }

    unless(defined $start) {
      $self->throw("start argument must be defined\n");
    }

    if($start > $end) {
      $self->throw("start must be less than end: parameters $chr:$start:$end");
    }
    
    my $slice;
    my $type = $self->db->assembly_type();

    $slice = Bio::EnsEMBL::Slice->new(
          -chr_name      => $chr,
          -chr_start     => $start,
          -chr_end       => $end,
          -assembly_type => $type,
          -adaptor       => $self
	 );

    return $slice;
}



=head2 fetch_by_contig_name

  Arg [1]    : string $name
               the name of the contig to obtain a slice for
  Arg [2]    : (optional) int $size
               the size of the flanking regions to obtain (aka context size)
  Example    : $slc = $slc_adaptor->fetch_by_contig_name('AB000878.1.1.33983');
  Description: Creates a slice object around the specified contig.  
               If a context size is given, the slice is extended by that 
               number of basepairs on either side of the contig.
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_contig_name {
   my ($self,$name, $size) = @_;

   if( !defined $size ) {$size=0;}

   my ($chr_name,$start,$end) = $self->_get_chr_start_end_of_contig($name);

   $start -= $size;
   $end += $size;

   if($start < 1) {
     $start  = 1;
   }

   return $self->fetch_by_chr_start_end($chr_name, $start, $end);
 }



=head2 fetch_by_fpc_name

  Arg [1]    : string $fpc_name
  Example    : my $slice = $slice_adaptor->fetch_by_fpc_name('NT_004321');
  Description: Creates a Slice on the region of the assembly where 
               the specified FPC (super) contig lies.
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_fpc_name {
    my ($self,$fpc_name) = @_;
    
    my( $p, $f, $l ) = caller; 
    $self->warn( "$f:$l calls deprecated method fetch_by_fpc_name. Please use fetch_by_supercontig_name instead" );

    $self->fetch_by_supercontig_name( $fpc_name ); 
}

sub fetch_by_supercontig_name {
  my ($self,$supercontig_name) = @_;
  
  my $assembly_type = $self->db->assembly_type();
  
  my $sth = $self->db->prepare("
        SELECT chr.name, a.superctg_ori, MIN(a.chr_start), MAX(a.chr_end)
        FROM assembly a, chromosome chr
        WHERE superctg_name = ?
        AND type = ?
        AND chr.chromosome_id = a.chromosome_id
        GROUP by superctg_name
        ");

  $sth->execute( $supercontig_name, $assembly_type );
  
  my ($chr, $strand, $slice_start, $slice_end) = $sth->fetchrow_array;
  
  my $slice;
  
  $slice = new Bio::EnsEMBL::Slice
    (
     -chr_name => $chr,
     -chr_start =>$slice_start,
     -chr_end => $slice_end,
     -strand => $strand,
     -assembly_type => $assembly_type
    );
  
  return $slice;
}


=head2 list_overlapping_supercontigs

  Arg [1]    : Bio::EnsEMBL::Slice $slice
               overlapping given Sice
  Example    : 
  Description: return the names of the supercontigs that overlap given Slice.  
  Returntype : listref string
  Exceptions : none
  Caller     : general

=cut


sub list_overlapping_supercontigs {
   my ($self,$slice) = @_;
   my $sth = $self->db->prepare( "
      SELECT DISTINCT superctg_name
        FROM assembly a, chromosome c
       WHERE c.chromosome_id = a.chromosome_id 
         AND c.name = ?
         AND a.type = ?
         AND a.chr_end >= ?
         AND a.chr_start <= ?
       " );
   $sth->execute( $slice->chr_name(), $slice->assembly_type(),
		  $slice->chr_start(), $slice->chr_end() );

   my $result = [];
   while( my $aref = $sth->fetchrow_arrayref() ) {
     push( @$result, $aref->[0] );
   }

   return $result;
}


=head2 fetch_by_clone_accession

  Arg [1]    : string $clone 
               the embl accession of the clone object to retrieve
  Arg [2]    : (optional) int $size
               the size of the flanking regions to obtain around the clone 
  Example    : $slc = $slc_adaptor->fetch_by_clone_accession('AC000012',1000);
  Description: Creates a Slice around the specified clone.  If a context size 
               is given, the Slice is extended by that number of basepairs on 
               either side of the clone.  Throws if the clone is not golden.
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : thrown if the clone is not in the assembly 
  Caller     : general

=cut

sub fetch_by_clone_accession{
   my ($self,$clone,$size) = @_;

   if( !defined $clone ) {
     $self->throw("Must have clone to fetch Slice of clone");
   }
   if( !defined $size ) {$size=0;}

   my $type = $self->db->assembly_type()
    or $self->throw("No assembly type defined");

   my $sth = $self->db->prepare("SELECT  c.name,
                        a.chr_start,
                        a.chr_end,
                        chr.name 
                    FROM    assembly a, 
                        contig c, 
                        clone  cl,
                        chromosome chr
                    WHERE c.clone_id = cl.clone_id
                    AND cl.name = '$clone'  
                    AND c.contig_id = a.contig_id 
                    AND a.type = '$type'
                    AND chr.chromosome_id = a.chromosome_id
                    ORDER BY a.chr_start"
                    );
   $sth->execute();
 
   my ($contig,$start,$end,$chr_name); 
   my $counter; 
   my $first_start;
   while ( my @row=$sth->fetchrow_array){
       $counter++;
       ($contig,$start,$end,$chr_name)=@row;
       if ($counter==1){$first_start=$start;}      
   }

   if( !defined $contig ) {
       $self->throw("Clone is not on the golden path. Cannot build Slice");
   }
     
   $first_start -= $size;
   $end += $size;

   if($first_start < 1) {
     $first_start = 1;
   }

   my $slice = $self->fetch_by_chr_start_end($chr_name, $first_start, $end);
   return $slice;
}



=head2 fetch_by_transcript_stable_id

  Arg [1]    : string $transcriptid
               The stable id of the transcript around which the slice is 
               desired
  Arg [2]    : (optional) int $size
               The length of the flanking regions the slice should encompass 
               on either side of the transcript (0 by default)
  Example    : $slc = $sa->fetch_by_transcript_stable_id('ENST00000302930',10);
  Description: Creates a slice around the region of the specified transcript. 
               If a context size is given, the slice is extended by that 
               number of basepairs on either side of the 
               transcript.  Throws if the transcript is not golden.
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_transcript_stable_id{
  my ($self,$transcriptid,$size) = @_;

  # Just get the dbID, then fetch slice by that
  my $ta = $self->db->get_TranscriptAdaptor;
  my $transcript_obj = $ta->fetch_by_stable_id($transcriptid);
  my $dbID = $transcript_obj->dbID;
  
  return $self->fetch_by_transcript_id($dbID, $size);
}




=head2 fetch_by_transcript_id

  Arg [1]    : int $transcriptid
               The unique database identifier of the transcript around which 
               the slice is desired
  Arg [2]    : (optional) int $size
               The length of the flanking regions the slice should encompass 
               on either side of the transcript (0 by default)
  Example    : $slc = $sa->fetch_by_transcript_id(24, 1000);
  Description: Creates a slice around the region of the specified transcript. 
               If a context size is given, the slice is extended by that 
               number of basepairs on either side of the 
               transcript. 
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : thrown on incorrect args
  Caller     : general

=cut

sub fetch_by_transcript_id {
  my ($self,$transcriptid,$size) = @_;

  unless( defined $transcriptid ) {
    $self->throw("Must have transcriptid id to fetch Slice of transcript");
  }

  $size = 0 unless(defined $size);
   
  my $ta = $self->db->get_TranscriptAdaptor;
  my $transcript_obj = $ta->fetch_by_dbID($transcriptid);
  
  my %exon_transforms;
  
  my $emptyslice;
  for my $exon ( @{$transcript_obj->get_all_Exons()} ) {
    $emptyslice = Bio::EnsEMBL::Slice->new( '-empty'   => 1,
					    '-adaptor' => $self,
					    '-ASSEMBLY_TYPE' =>
					    $self->db->assembly_type);     
    my $newExon = $exon->transform( $emptyslice );
    $exon_transforms{ $exon } = $newExon;
  }
  
  $transcript_obj->transform( \%exon_transforms );
  
  my $start = $transcript_obj->start() - $size;
  my $end = $transcript_obj->end() + $size;
  
  if($start < 1) {
    $start = 1;
  }
  
  my $slice = $self->fetch_by_chr_start_end($emptyslice->chr_name,
					    $start, $end);
  return $slice;
}



=head2 fetch_by_transcript_stable_id

  Arg [1]    : string $geneid
               The stable id of the gene around which the slice is 
               desired
  Arg [2]    : (optional) int $size
               The length of the flanking regions the slice should encompass 
               on either side of the gene (0 by default)
  Example    : $slc = $sa->fetch_by_transcript_stable_id('ENSG00000012123',10);
  Description: Creates a slice around the region of the specified gene. 
               If a context size is given, the slice is extended by that 
               number of basepairs on either side of the gene. 
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : none
  Caller     : general

=cut

sub fetch_by_gene_stable_id{
   my ($self,$geneid,$size) = @_;

   if( !defined $geneid ) {
       $self->throw("Must have gene id to fetch Slice of gene");
   }
   if( !defined $size ) {$size=0;}

   my ($chr_name,$start,$end) = $self->_get_chr_start_end_of_gene($geneid);

   if( !defined $start ) {
     my $type = $self->db->assembly_type()
       or $self->throw("No assembly type defined");
     $self->throw("Gene is not on the golden path '$type'. " .
		  "Cannot build Slice.");
   }
     
   $start -= $size;
   $end += $size;
   
   if($start < 1) {
     $start = 1;
   }

   return $self->fetch_by_chr_start_end($chr_name, $start, $end);
}



=head2 fetch_by_chr_name

  Arg [1]    : string $chr_name
  Example    : $slice = $slice_adaptor->fetch_by_chr_name('20'); 
  Description: Retrieves a slice on the region of an entire chromosome
  Returntype : Bio::EnsEMBL::Slice
  Exceptions : thrown if $chr_name arg is not supplied
  Caller     : general

=cut

sub fetch_by_chr_name{
   my ($self,$chr_name) = @_;

   unless( $chr_name ) {
       $self->throw("Chromosome name argument required");
   }

   my $chr_start = 1;
   
   #set the end of the slice to the end of the chromosome
   my $ca = $self->db()->get_ChromosomeAdaptor();
   my $chromosome = $ca->fetch_by_chr_name($chr_name);
   my $chr_end = $chromosome->length();

   my $type = $self->db->assembly_type();

   my $slice = Bio::EnsEMBL::Slice->new
     (
      -chr_name      => $chr_name,
      -chr_start     => 1,
      -chr_end       => $chr_end,
      -assembly_type => $type,
      -adaptor       => $self
     );

   return $slice;
}



=head2 fetch_by_mapfrag

 Title   : fetch_by_mapfrag
 Usage   : $slice = $slice_adaptor->fetch_by_mapfrag('20');
 Function: Creates a slice of a "mapfrag"
 Returns : Slice object
 Args    : chromosome name


=cut

sub fetch_by_mapfrag{
   my ($self,$mymapfrag,$flag,$size) = @_;

   $flag ||= 'fixed-width'; # alt.. 'context'
   $size ||= $flag eq 'fixed-width' ? 200000 : 0;
   unless( $mymapfrag ) {
       $self->throw("Mapfrag name argument required");
   }

   my( $chr_start,$chr_end);
  
   #set the end of the slice to the end of the chromosome
   my $ca = $self->db()->get_MapFragAdaptor();
   my $mapfrag = $ca->fetch_by_synonym($mymapfrag);
   return undef unless defined $mapfrag;

   if( $flag eq 'fixed-width' ) {
       my $halfsize = int( $size/2 );
       $chr_start = $mapfrag->seq_start - $halfsize;
       $chr_end   = $mapfrag->seq_start + $size - $halfsize;
   } else {
       $chr_start     = $mapfrag->seq_start - $size;
       $chr_end       = $mapfrag->seq_end   + $size;
   }
   my $type = $self->db->assembly_type();

   my $slice = Bio::EnsEMBL::Slice->new
     (
      -chr_name      => $mapfrag->seq,
      -chr_start     => $chr_start,
      -chr_end       => $chr_end,
      -assembly_type => $type,
      -adaptor       => $self
     );

   return $slice;
}





=head2 _get_chr_start_end_of_contig

 Title   : _get_chr_start_end_of_contig
 Usage   :
 Function: returns the chromosome name, absolute start and absolute end of the 
           specified contig
 Returns : returns chr,start,end
 Args    : contig id

=cut

sub _get_chr_start_end_of_contig {
    my ($self,$contigid) = @_;

   if( !defined $contigid ) {
       $self->throw("Must have contig id to fetch Slice of contig");
   }
   
   my $type = $self->db->assembly_type()
    or $self->throw("No assembly type defined");

   my $sth = $self->db->prepare("SELECT  c.name,
                        a.chr_start,
                        a.chr_end,
                        chr.name 
                    FROM assembly a, contig c, chromosome chr 
                    WHERE c.name = '$contigid' 
                    AND c.contig_id = a.contig_id 
                    AND a.type = '$type'
                    AND chr.chromosome_id = a.chromosome_id"
                    );
   $sth->execute();
   my ($contig,$start,$end,$chr_name) = $sth->fetchrow_array;

   if( !defined $contig ) {
     $self->throw("Contig $contigid is not on the golden path of type $type");
   }

   return ($chr_name,$start,$end);
}

=head2 _get_chr_start_end_of_gene

 Title   : get_Gene_chr_bp
 Usage   : 
 Function: 
 Returns :  
 Args    :


=cut


sub _get_chr_start_end_of_gene {
  my ($self,$geneid) =  @_;
  
  my $type = $self->db->assembly_type()
    or $self->throw("No assembly type defined");
  
  my $sth = $self->db->prepare("SELECT  
   if(a.contig_ori=1,(e.contig_start-a.contig_start+a.chr_start),
                    (a.chr_start+a.contig_end-e.contig_end)),
   if(a.contig_ori=1,(e.contig_end-a.contig_start+a.chr_start),
                    (a.chr_start+a.contig_end-e.contig_start)),
     chr.name
  
                    FROM    exon e,
                        transcript tr,
                        exon_transcript et,
                        assembly a,
                        gene_stable_id gsi,
                        chromosome chr
                    WHERE e.exon_id=et.exon_id 
                    AND et.transcript_id =tr.transcript_id 
                    AND a.contig_id=e.contig_id 
                    AND a.type = '$type' 
                    AND tr.gene_id = gsi.gene_id
                    AND gsi.stable_id = '$geneid'
                    AND a.chromosome_id = chr.chromosome_id" 
                    );
   $sth->execute();

   my ($start,$end,$chr);
   my @start;
   while ( my @row=$sth->fetchrow_array){
      ($start,$end,$chr)=@row;
       push @start,$start;
       push @start,$end;
   }   
   
   my @start_sorted=sort { $a <=> $b } @start;

   $start=shift @start_sorted;
   $end=pop @start_sorted;

   return ($chr,$start,$end);      
}

1;






