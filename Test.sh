#!/bin/bash
#
# TOOLS INSTALLATION ###########################################################
#
#conda install -c bioconda mbgc -y
#conda install -c bioconda naf -y
#conda install -c bioconda geco3 -y
#
# GET AND UNCOMPRESS DATASETS ##################################################
#
cp datasets/BDB.fa.lzma .
cp datasets/VDB.fa.lzma .
lzma -d BDB.fa.lzma;
lzma -d VDB.fa.lzma;
#
# BENCHMARK ####################################################################
#
declare -a DATASETS=("BDB.fa" "VDB.fa");
#
for DS in "${DATASETS[@]}"
  do
  #
  # ============================================================================
  # RUNNING FOR EACH DATASET
  #
  printf "Running dataset %s\n" "$DS";
  grep ">" $DS > headers_DS; grep -v ">" $DS | tr -d '\n' > dna_DS;
  #
  # ----------------------------------------------------------------------------
  # BENCHMARK FOR NAF
  #
  printf "Running NAF ...\n";
  F2="out_naf"; 
  printf "Level\tBytes\tC_Sec\tD_sec\tHeader_flaw\tDNA_flaw\n";
  #
  for((x=1;x<=22;++x)); 
    do 
    (/usr/bin/time -f "%e" ennaf --temp-dir test --level $x -o $DS-$x.naf $DS 1> report_stdout_naf_$x ) 2> report_stderr_naf_$x;
    (/usr/bin/time -f "%e" unnaf -o $F2 $DS-$x.naf 1> report_stdout_unnaf_$x ) 2> report_stderr_unaf_$x; 
    grep ">" $F2 > headers2; 
    grep -v ">" $F2 | tr -d '\n' > dna2; 
    BYTES=`ls -la $DS-$x.naf | awk '{ print $5;}'`;
    CSECS=`cat report_stderr_naf_$x | tail -n 1`;
    DSECS=`cat report_stderr_unaf_$x | tail -n 1`;
    HCORR=`cmp headers_DS headers2 | wc -l`;
    DCORR=`cmp dna_DS dna2 | wc -l`;
    printf "%d\t%lld\t%s\t%s\t%s\t%s\n" "$x" "$BYTES" "$CSECS" "$DSECS" "$HCORR" "$DCORR"; 
    rm -f headers2 dna2; 
    done;
  #
  # ----------------------------------------------------------------------------
  # BENCHMARK FOR MBGC
  #
  LEVEL="2";
  printf "Running MBGC (Level=$LEVEL)...\n";
  F2="out_mbgc";
  printf "Threads\tBytes\tC_Sec\tD_sec\tHeader_flaw\tDNA_flaw\n";
  #
  for((x=1;x<=8;++x));
    do
    rm -f $DS-$x.mbgc;
    (/usr/bin/time -f "%e" mbgc -c $LEVEL -t $x -i $DS $DS-$x.mbgc 1> report_stdout_mbgc_$x ) 2> report_stderr_mbgc_$x 
    (/usr/bin/time -f "%e" mbgc -t $x -d $DS-$x.mbgc $F2 1> report_stdout_dmbgc_$x ) 2> report_stderr_dmbgc_$x
    grep ">" $F2/$DS > headers2;
    grep -v ">" $F2/$DS | tr -d '\n' > dna2;
    BYTES=`ls -la $DS-$x.mbgc | awk '{ print $5;}'`;
    CSECS=`cat report_stderr_mbgc_$x | tail -n 1`;
    DSECS=`cat report_stderr_dmbgc_$x | tail -n 1`;
    HCORR=`cmp headers_DS headers2 | wc -l`;
    DCORR=`cmp dna_DS dna2 | wc -l`;
    printf "%d\t%lld\t%s\t%s\t%s\t%s\n" "$x" "$BYTES" "$CSECS" "$DSECS" "$HCORR" "$DCORR";
    rm -f headers2 dna2;
    done;
  #
  done
# ==============================================================================
#

