#!/software/bin/perl

=head1 NAME


=head1 SYNOPSIS

.pl [arguments]

Required arguments:

  --dbname, db_name=NAME              database name NAME
  --host, --dbhost, --db_host=HOST    database host HOST
  --port, --dbport, --db_port=PORT    database port PORT
  --user, --dbuser, --db_user=USER    database username USER
  --pass, --dbpass, --db_pass=PASS    database passwort PASS

Optional arguments:

  --conffile, --conf=FILE             read parameters from FILE
                                      (default: conf/Conversion.ini)

  --logfile, --log=FILE               log to FILE (default: *STDOUT)
  --logpath=PATH                      write logfile to PATH (default: .)
  --logappend, --log_append           append to logfile (default: truncate)
  --loglevel=LEVEL                    define log level (default: INFO)

  -i, --interactive=0|1               run script interactively (default: true)
  -n, --dry_run, --dry=0|1            don't write results to database
  -h, --help, -?                      print help (this message)

=head1 DESCRIPTION


=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Patrick Meidl <meidl@ebi.ac.uk>, Ensembl core API team

=head1 CONTACT

Please post comments/questions to the Ensembl development list
<ensembl-dev@ebi.ac.uk>

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use FindBin qw($Bin);
use Bio::EnsEMBL::Utils::ConfParser;
use Bio::EnsEMBL::Utils::Logger;
use Bio::EnsEMBL::Utils::ScriptUtils qw(dynamic_use path_append);

# parse configuration and commandline arguments
my $conf = new Bio::EnsEMBL::Utils::ConfParser(
  -SERVERROOT => "$Bin/../../..",
  -DEFAULT_CONF => "$Bin/default.conf"
);

$conf->parse_options(
  'sourcehost|source_host=s' => 1,
  'sourceport|source_port=n' => 1,
  'sourceuser|source_user=s' => 1,
  'sourcepass|source_pass=s' => 0,
  'sourcedbname|source_dbname=s' => 1,
  'targethost|target_host=s' => 1,
  'targetport|target_port=n' => 1,
  'targetuser|target_user=s' => 1,
  'targetpass|target_pass=s' => 0,
  'targetdbname|target_dbname=s' => 1,
  'dumppath|dump_path=s' => 1,
  'biotypes=s@' => 0,
  'dbtype=s' => 1,
  'slice_name=s' => 1,
  'cache_impl=s' => 1,
);

# set default logpath
unless ($conf->param('logpath')) {
  $conf->param('logpath', path_append($conf->param('dumppath'), 'log'));
}
# log to a subdirectory to prevent clutter
$conf->param('logpath', path_append($conf->param('logpath'),
  'dump_by_seq_region'));  

# get log filehandle and print heading and parameters to logfile
my $logger = new Bio::EnsEMBL::Utils::Logger(
  -LOGFILE      => $conf->param('logfile'),
  -LOGAUTO      => $conf->param('logauto'),
  -LOGAUTOBASE  => $conf->param('logautobase') || 'dump_by_seq_region',
  -LOGAUTOID    => $conf->param('logautoid'),
  -LOGPATH      => $conf->param('logpath'),
  -LOGAPPEND    => $conf->param('logappend'),
  -LOGLEVEL     => $conf->param('loglevel'),
  -IS_COMPONENT => 1,
);

# build cache
my $cache_impl = $conf->param('cache_impl');

dynamic_use($cache_impl);

my $cache = $cache_impl->new(
  -LOGGER       => $logger,
  -CONF         => $conf,
);

my $dbtype = $conf->param('dbtype');
my $slice_name = $conf->param('slice_name');
my $i = 0;
my $size = 0;
($i, $size) = $cache->build_cache($dbtype, $slice_name);

# set flag to indicate everything went fine
my $success_file = $conf->param('logpath')."/dump_by_seq_region.$dbtype.$slice_name.success";
open(TMPFILE, '>', $success_file) and close TMPFILE
  or die "Can't open $success_file for writing: $!";

# log success
$logger->info("Done with $dbtype $slice_name (genes: $i, filesize: $size, runtime: ".$logger->runtime." ".$logger->date_and_mem."\n");


