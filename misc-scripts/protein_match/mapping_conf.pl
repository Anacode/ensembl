=head1 mappping_conf.pl

=head2 Description

This script gives the basic configuration needed by the mapping. This configuration script will be used by each script of the mapping. 

For some documentatio, see below.

=head2 Contact

Emmanuel Mongin (mongin@ebi.ac.uk)

=cut





BEGIN {
package main;

%mapping_conf = ( 

             #################
             #General options#
             #################

	     #The mapping to known genes is assymetrical. This is due to the fact that's our gene prediction is quite fragmented compared to the manually curated genes       	 
            
	     #'query_idt'  => 40,
             'query_idt'    => 40,

             #'target_idt  => 10,
             'target_idt'  => 10,

             

             #Location of the statistic file (only neede if you run get_stats.pl)
             #'statistic'  => '/work1/mongin/mapping/stats.txt',
             'statistic_file'  => '',        


             ################################ 
	     # Files location (Input/Output)#
             ################################


             #Location of the query peptide file (eg: Ensembl predicted protein) 
             #'query'        => '/work1/mongin/mapping/primary/ensembl110.pep',
             'query'       => '',   
             
             #Location of the sptr file, this file will be used as an 
	     #input to grep the specific sp entries to the organism 
	     #using grep_sp_entries.pl. This file is supposed to be 
	     #in SP format
	   
	      'total_sptr'  => '',

             #Location of the sptr file in fasta format containing the entries specific to the organism
	     #'sptr_fa'      => '/work1/mongin/mapping/primary/HS.f',
	     'sptr_fa'      => '',
	     
             #Location of the sptr file in Swiss-Prot format containing the entries specific to the organism
	     #'sptr_swiss'      => '/ecs2/work1/lec/briggsae_peptides/briggsae.test',
	     'sptr_swiss' => '',	     

             #Location of the file containing all refseq and all SP in fasta format (This file will be produced by running prepare_proteome.pl)
            
	     'pmatch_input_fa'    => '',

             #Output file containing the mapping of SP and refseq sequences to external databases
           
             'x_map_out'  => '',

             #Output file from pmatch.pl and input file for maps2db.pl
             #'pmatch_out'  => '/work1/mongin/mapping/outputs/pmatch_human1.txt',
             'pmatch_out'  => '',


             #Location of the Refseq (proteins) file in fasta format
	     #'refseq_fa'    => '/work1/mongin/mapping/primary/refseq.fa',
	     'refseq_fa'    => '',
	     
             #Location of the Refseq (proteins) file in Genbank format
	     #'refseq_gnp'    => '/work1/mongin/mouse/mapping/primary/mouse.gnp',
	     'refseq_gnp'  => '',

             ############################################
             #Organism specific files for the X_mapping #
             ############################################
                  
                  #######
                  #Human#
                  #######

                  #ens1 and ens4, location of files used for Hugo mapping (http://www.gene.ucl.ac.uk/public-files/nomen/),                   th is files will be used only for human
	          #'ens1'      => '/work1/mongin/mapping/primary/ens1.txt',
	          'ens1'      => '',

	          #'ens4'      => '/work1/mongin/mapping/primary/ens4.txt',
	          'ens4'      => '',

                  #Location of the file in .gnp format for the NCBI prediction
                  #'refseq_pred' => '',
                  'refseq_pred' => '',

                  #Location of the file for GO mapping (gene_association.goa)
                  #'go' => '',
                  'go' => '',
                  
                  #######
                  #Mouse#
                  #######

                  #The files needed for the mouse X_mapping can be obatained there: ftp://ftp.informatics.jax.org/pub/reports/   
                  #2 files are needed MRK_SwissProt.rpt and MRK_LocusLink.rpt
                  
                   #File containing MGI/SP mapping (MRK_SwissProt.rpt)
                   #'mgi_sp'  => '/work1/mongin/mouse/mapping/primary/MRK_SwissProt.rpt',                 
                   'mgi_sp'  => '',
                  
                   #File containing MGI/LocusLink mapping (MRK_LocusLink.rpt)
                   #'mgi_locus'  => '/work1/mongin/mouse/mapping/primary/MRK_LocusLink.rpt',                   
                   'mgi_locus'  => '',
                                      

                   ###########
                   #Anopheles#
                   ###########
                    
                   #File containing the submitted genes, see ensembl-genename/scripts for utility scripts
                   'submitted_genes' => '',

                   #########
                   #elegans#
                   #########
                   
                   #File containing the wormbase names: ftp.sanger.ac.uk/pub/databases/wormpep/wormpep.table
                   'eleg_nom' => '',

                   ###########
                   #zebrafish#
                   ###########
                   #Files containing the ZFIN names for zebrafish, available at: /nfs/team71/zfish/kj2/zebrafish/ZFIN  zfin_dblinks.txt and zfin_genes.txt
                   'zeb_gene' => '',
                
                   'zeb_dblink' => '',

                   ############
                   #drosophila#
                   ############

                   'dros_ext_annot' => '',


		   ##########
		   #briggsae#
                   ##########
		 #get from wormbase ftp site ftp://ftp.wormbase.org/pub/wormbase/briggsae
		   'briggsae_hybrid' => '',

 
             ###################
             #Database handling#
             ###################

             #DB name
             #'db' => 'proteintest',
             'db' => '',

             #Host name
             #'host' => 'ecs1d',
             'host' => '',

             #User
             'dbuser' => '',

             #Password
             'password' => '',
             
             #Port
             'port' => '',

             #####################
             #Executable location#
             #####################

             #Location for pmatch binaries
             #'pmatch' => '/nfs/disk65/ms2/bin/pmatch'
             'pmatch' => '',

             

             ##############################
             #Organism related information#
             ##############################

             #Name of the organism studied. Current keywords used(or planned to be used): human, drosophila, mouse, elegans, anopheles, zebrafish
             #You can adapt the other scripts given the organisms (eg: do some specific x_mapping for a given organism)
             #'organism' => 'human'
             'organism' => '',
             

             #OX (Organism taxonomy cross-reference) number
             #'ox' => '9606', human
             #'ox' => '10090', mouse
             #'ox' => '7227', drosophilla
	     #'ox' => '6239' elegans
	     #'ox' => '6238' briggsae 	 
             'ox'  => '',

	     
             


                  

             
	     ##################	 
	     #obslete options# 
             ##################

	     'check'      => '', #obslete option? 	 
 );



}

1;





