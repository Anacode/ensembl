=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package XrefParser::RefSeqCoordinateParser;

use strict;
use warnings;
use Carp;
use DBI;

use base qw( XrefParser::BaseParser );
use Bio::EnsEMBL::Registry;

sub run_script {

  my ($self, $ref_arg) = @_;
  my $source_id    = $ref_arg->{source_id};
  my $species_id   = $ref_arg->{species_id};
  my $file         = $ref_arg->{file};
  my $verbose      = $ref_arg->{verbose};

  if((!defined $source_id) or (!defined $species_id) or (!defined $file) ){
    croak "Need to pass source_id, species_id and file as pairs";
  }
  $verbose |=0;

  my $peptide_source_id = $self->get_source_id_for_source_name('RefSeq_peptide', 'otherfeatures');
  my $mrna_source_id = $self->get_source_id_for_source_name('RefSeq_mRNA', 'otherfeatures');

  my $user = "ensro";
  my $host;
  my $port = 3306;
  my $dbname;
  my $pass;
  my $transcript_score_threshold = 0.90;
  my $tl_transcript_score_threshold = 0.90;
  my $project;

# Grep the project name, should be ensembl or ensemblgenomes
  if($file =~ /project[=][>](\S+?)[,]/){
    $project = $1;
  }

# If specified, get core database connection details
  if($file =~ /host[=][>](\S+?)[,]/){
    $host = $1;
  }
  if($file =~ /port[=][>](\S+?)[,]/){
    $port =  $1;
  }
  if($file =~ /dbname[=][>](\S+?)[,]/){
    $dbname = $1;
  }
  if($file =~ /pass[=][>](\S+?)[,]/){
    $pass = $1;
  }
  if($file =~ /user[=][>](\S+?)[,]/){
    $user = $1;
  }

  my $ofuser = 'ensro';
  my $ofhost;
  my $ofport = 3306;
  my $ofdbname;
  my $ofpass;

# If specified, get otherfeatures database connection details
  if($file =~ /ofhost[=][>](\S+?)[,]/){
    $ofhost = $1;
  }
  if($file =~ /ofuser[=][>](\S+?)[,]/){
    $ofuser = $1;
  }
  if($file =~ /ofport[=][>](\S+?)[,]/){
    $ofport =  $1;
  }
  if($file =~ /ofdbname[=][>](\S+?)[,]/){
    $ofdbname = $1;
  }
  if($file =~ /ofpass[=][>](\S+?)[,]/){
    $ofpass = $1;
  }
 
  my $registry = "Bio::EnsEMBL::Registry";

  #get the species name
  my %id2name = $self->species_id2name;
  my $species_name = $id2name{$species_id}[0];

  my $core_dba;
  my $otherf_dba;

  if ($project eq 'ensembl') {
# Can use user-defined database
      if (defined $host) {
          $core_dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
              '-host'     => $host,
              '-user'     => $user,
              '-pass'     => $pass,
              '-dbname'   => $dbname,
              '-species'  => $species_name.$host,
              '-group'    => 'core',
       );
      } else {
# Else, database should be on staging
      $registry->load_registry_from_multiple_dbs(
          {
              -host    => 'ens-staging1',
              -user    => 'ensro',
          },
          {
              -host     => 'ens-staging2',
              -user     => 'ensro',
          },
       );
      $core_dba = $registry->get_DBAdaptor($species_name,'core');
      }
      if (defined $ofhost) {
# Can use user-defined database
          $otherf_dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
              '-host'     => $ofhost,
              '-user'     => $ofuser,
              '-pass'     => $ofpass,
              '-dbname'   => $ofdbname,
              '-species'  => $species_name.$ofhost,
              '-group'    => 'otherfeatures',
       );
      } else {
# Else database should be on staging
      $registry->load_registry_from_multiple_dbs( 
	  {
	      -host    => 'ens-staging1',
	      -user    => 'ensro',
	  },
	  {
	      -host     => 'ens-staging2',
	      -user     => 'ensro',
	  },
       );
      $otherf_dba = $registry->get_DBAdaptor($species_name, 'otherfeatures') if !defined($ofhost);
    }
      

  } elsif ($project eq 'ensemblgenomes') {
      $registry->load_registry_from_multiple_dbs( 
	  {
	      -host     => 'mysql-eg-staging-1.ebi.ac.uk',
	      -port     => 4160,
	      -user     => 'ensro',
	  },
	  {
	      -host     => 'mysql-eg-staging-2.ebi.ac.uk',
	      -port     => 4275,
	      -user     => 'ensro',
	  },
 
      );
      $core_dba = $registry->get_DBAdaptor($species_name,'core');
      $otherf_dba = $registry->get_DBAdaptor($species_name, 'otherfeatures');     

  } else {
      die("Missing or unsupported project value. Supported values: ensembl, ensemblgenomes");
  }

  my $sa = $core_dba->get_SliceAdaptor();
  my $sa_of = $otherf_dba->get_SliceAdaptor();
  my $chromosomes_of = $sa_of->fetch_all('chromosome', undef, 1);

# Fetch analysis object for refseq
  my $aa_of = $otherf_dba->get_AnalysisAdaptor();
  my $logic_name;
  foreach my $ana(@{ $aa_of->fetch_all() }) {
    if ($ana->logic_name =~ /refseq_import/) {
      $logic_name = $ana->logic_name;
    }
  }
  if (!defined $logic_name) {
    die("Could not find logic_name for refseq in otherfeatures database");
  }

  foreach my $chromosome_of (@$chromosomes_of) {
    my $chr_name = $chromosome_of->seq_region_name();
    my $genes_of = $chromosome_of->get_all_Genes($logic_name, undef, 1);

    while (my $gene_of = shift @$genes_of) {
      my $transcripts_of = $gene_of->get_all_Transcripts();

# Create a range registry for all the exons of the refseq transcript
      foreach my $transcript_of (sort { $a->start() <=> $b->start() } @$transcripts_of) {
        my %transcript_result;
        my %tl_transcript_result;
        my $id = $transcript_of->stable_id();
        if ($id =~ /^XM_/) { next; }
        my $exons_of = $transcript_of->get_all_Exons();
        my $rr1 = Bio::EnsEMBL::Mapper::RangeRegistry->new();
        my $tl_exons_of = $transcript_of->get_all_translateable_Exons();
        my $rr3 = Bio::EnsEMBL::Mapper::RangeRegistry->new();

        foreach my $exon_of (@$exons_of) {
          my $start_of = $exon_of->seq_region_start();
          my $end_of = $exon_of->seq_region_end();
          $rr1->check_and_register( 'exon', $start_of, $end_of );
        }

        foreach my $tl_exon_of (@$tl_exons_of) {
          my $tl_start_of = $tl_exon_of->seq_region_start();
          my $tl_end_of = $tl_exon_of->seq_region_end();
          $rr3->check_and_register( 'exon', $tl_start_of, $tl_end_of );
        }

# Fetch slice in core database which overlaps refseq transcript
        my $chromosome = $sa->fetch_by_region('chromosome', $chr_name, $transcript_of->seq_region_start, $transcript_of->seq_region_end);
        my $transcripts = $chromosome->get_all_Transcripts(1);

# Create a range registry for all the exons of the ensembl transcript
        foreach my $transcript(@$transcripts) {
          my $exons = $transcript->get_all_Exons();
          my $rr2 = Bio::EnsEMBL::Mapper::RangeRegistry->new();
          my $rr4 = Bio::EnsEMBL::Mapper::RangeRegistry->new();
          my $exon_match = 0;
          my $tl_exons = $transcript->get_all_translateable_Exons();
          my $tl_exon_match = 0;

          foreach my $exon (@$exons) {
            my $start = $exon->seq_region_start();
            my $end = $exon->seq_region_end();
            my $overlap = $rr1->overlap_size('exon', $start, $end);
            $exon_match += $overlap/($end - $start + 1);
            $rr2->check_and_register('exon', $start, $end);
          }

          foreach my $tl_exon (@$tl_exons) {
            my $tl_start = $tl_exon->seq_region_start();
            my $tl_end = $tl_exon->seq_region_end();
            my $tl_overlap = $rr3->overlap_size('exon', $tl_start, $tl_end);
            $tl_exon_match += $tl_overlap/($tl_end - $tl_start + 1);
            $rr4->check_and_register('exon', $tl_start, $tl_end);
          }

          my $exon_match_of = 0;
          my $tl_exon_match_of = 0;

# Look for oeverlap between the two sets of exons
          foreach my $exon_of (@$exons_of) {
            my $start_of = $exon_of->seq_region_start();
            my $end_of = $exon_of->seq_region_end();
            my $overlap_of = $rr2->overlap_size('exon', $start_of, $end_of);
            $exon_match_of += $overlap_of/($end_of - $start_of + 1);
          }

          foreach my $tl_exon_of (@$tl_exons_of) {
            my $tl_start_of = $tl_exon_of->seq_region_start();
            my $tl_end_of = $tl_exon_of->seq_region_end();
            my $tl_overlap_of = $rr4->overlap_size('exon', $tl_start_of, $tl_end_of);
            $tl_exon_match_of += $tl_overlap_of/($tl_end_of - $tl_start_of + 1);
          }

# Comparing exon matching with number of exons to give a score
          my $score = ( ($exon_match_of + $exon_match)) / (scalar(@$exons_of) + scalar(@$exons) );
          my $tl_score = 0;
          if (scalar(@$tl_exons_of) > 0) {
            $tl_score = ( ($tl_exon_match_of + $tl_exon_match)) / (scalar(@$tl_exons_of) + scalar(@$tl_exons) );
          }
          if ($transcript->biotype eq $transcript_of->biotype) {
            $transcript_result{$transcript->stable_id} = $score;
            $tl_transcript_result{$transcript->stable_id} = $tl_score;
          }
        }

        my $best_score = 0;
        my $best_tl_score = 0;
        my $best_id;
        my ($score, $tl_score);
# Comparing the scores based on coding exon overlap
# If there is a stale mate, chose best exon overlap score
        foreach my $tid (keys(%transcript_result)) {
          $score = $transcript_result{$tid};
          $tl_score = $tl_transcript_result{$tid};
          if ($score > $transcript_score_threshold || $tl_score > $tl_transcript_score_threshold) {
            if ($tl_score >= $best_tl_score) {
              if ($tl_score > $best_tl_score) {
                $best_id = $tid;
                $best_score = $score;
                $best_tl_score = $tl_score;
              } elsif ($tl_score == $best_tl_score) {
                if ($score > $best_score) {
                  $best_id = $tid;
                  $best_score = $score;
                }
              }
            }
          }
        }

# If a best match was defined for the refseq transcript, store it as direct xref for ensembl transcript
        if ($best_id) {
          my ($acc, $version) = split(/\./, $id);
          my $xref_id = $self->add_xref({ acc => $acc,
                                          version => $version,
                                          label => $id,
                                          desc => '',
                                          source_id => $mrna_source_id,
                                          species_id => $species_id,
                                          info_type => 'DIRECT' });
          $self->add_direct_xref($xref_id, $best_id, "Transcript", "");

# Also store refseq protein as direct xref for ensembl translation, if translation exists
          my $ta_of = $otherf_dba->get_TranscriptAdaptor();
          my $t_of = $ta_of->fetch_by_stable_id($id);
          my $tl_of = $t_of->translation();
          my $ta = $core_dba->get_TranscriptAdaptor();
          my $t = $ta->fetch_by_stable_id($best_id);
          my $tl = $t->translation();
          if (defined $tl && defined $tl_of) {
            if ($tl_of->seq eq $tl->seq) {
              ($acc, $version) = split(/\./, $tl_of->stable_id());
              my $tl_xref_id = $self->add_xref({ acc => $acc,
                                              version => $version,
                                              label => $acc,
                                              desc => '',
                                              source_id => $peptide_source_id,
                                              species_id => $species_id,
                                              info_type => 'DIRECT' });
              $self->add_direct_xref($tl_xref_id, $tl->stable_id(), "Translation", "");
            }
          }
        }
      }
    }
  }
  return 0;
}

1;
