#!/bin/sh
#####################################################-*-mode:shell-script-*-
##                                                                       ##
##                     Carnegie Mellon University                        ##
##                      Copyright (c) 2005-2008                          ##
##                        All Rights Reserved.                           ##
##                                                                       ##
##  Permission is hereby granted, free of charge, to use and distribute  ##
##  this software and its documentation without restriction, including   ##
##  without limitation the rights to use, copy, modify, merge, publish,  ##
##  distribute, sublicense, and/or sell copies of this work, and to      ##
##  permit persons to whom this work is furnished to do so, subject to   ##
##  the following conditions:                                            ##
##   1. The code must retain the above copyright notice, this list of    ##
##      conditions and the following disclaimer.                         ##
##   2. Any modifications must be clearly marked as such.                ##
##   3. Original authors' names are not deleted.                         ##
##   4. The authors' names are not used to endorse or promote products   ##
##      derived from this software without specific prior written        ##
##      permission.                                                      ##
##                                                                       ##
##  CARNEGIE MELLON UNIVERSITY AND THE CONTRIBUTORS TO THIS WORK         ##
##  DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING      ##
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT   ##
##  SHALL CARNEGIE MELLON UNIVERSITY NOR THE CONTRIBUTORS BE LIABLE      ##
##  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES    ##
##  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN   ##
##  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,          ##
##  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF       ##
##  THIS SOFTWARE.                                                       ##
##                                                                       ##
###########################################################################
##                                                                       ##
##  Author: Alok Parlikar (aup@cs.cmu.edu) Jan 2013                      ##
##                                                                       ##
###########################################################################
##                                                                       ##
## Uses SPTK for extracting F0 and Voicing Information                   ##
##                                                                       ##
###########################################################################
###########################################################################
##                                                                       ##
##  Author: Pallas13 (edsondasilvaguedes0@gmail) 2025                    ##
##                                                                       ##
###########################################################################
##                                                                       ##
## Uses DiffSPTK for extracting F0 and Voicing Information  		 ##
##          (Basead in SPTK F0 extraction script)                        ##
###########################################################################

LANG=C; export LANG

if [ ! "$ESTDIR" ]
then
   echo "environment variable ESTDIR is unset"
   echo "set it to your local speech tools directory e.g."
   echo '   bash$ export ESTDIR=/home/awb/projects/speech_tools/'
   echo or
   echo '   csh% setenv ESTDIR /home/awb/projects/speech_tools/'
   exit 1
fi

if [ ! "$FESTVOXDIR" ]
then
   echo "environment variable FESTVOXDIR is unset"
   echo "set it to your local festvox directory e.g."
   echo '   bash$ export FESTVOXDIR=/home/awb/projects/festvox/'
   echo or
   echo '   csh% setenv FESTVOXDIR /home/awb/projects/festvox/'
   exit 1
fi

F0MIN=50
F0MAX=200
F0MEAN=110

VERSION=$($SPTKDIR/mgcep -h | grep version)

if [ ! "$VERSION" = ' SPTK: version 4.3' ]
                then
                        echo "Your SPTK verion is $VERSION, is need SPTK-4.3"
                        echo "git clone https://github.com/sp-nitech/SPTK"
                        echo "cd SPTK"
                        echo "mkdir build"
                        echo "cmake ../"
                        echo "make -j$(nproc)"
                        echo "export SPTK=$(PWD)"
                        exit 1
fi

X2X=$SPTKDIR/x2x

if [ ! -d diffsptk_f0 ]
then
   mkdir diffsptk_f0
fi
if [ ! -d v ]
then
   mkdir v
fi

if [ -f etc/f0.params ]
then
   . etc/f0.params
fi

if [ ! -f etc/silence ]
then
   $ESTDIR/../festival/bin/festival -b festvox/build_clunits.scm "(find_silence_name)"
fi
SILENCE=`awk '{print $1}' etc/silence`

PROMPTFILE=etc/txt.done.data
if [ $# = 1 ]
then
   PROMPTFILE=$1
fi

cat $PROMPTFILE |
awk '{print $2}' |
while read i
do
    fname=$i
    
    if [ "$SAMPFREQ" = "" ]
    then
	    # Use the first wav file to determine sampling frequency
	SAMPFREQ=$($ESTDIR/bin/ch_wave -info wav/$fname.wav  | grep 'Sample rate' | cut -d ' ' -f 3)
	SAMPKHZ=$(echo "$SAMPFREQ 0.001" | awk '{printf("%0.3f\n",$1*$2)}')	
	FRAMELEN=$(echo | awk "{print int(0.025*$SAMPFREQ)}")
	FRAMESHIFT=$(echo | awk "{print int(0.005*$SAMPFREQ)}")

    fi

    echo $fname F0 extraction with DiffSPTK
    TMP=sptkf0_tmp.$$

        python bin/get_f0_diffsptk.py --sample_rate $SAMPFREQ --f0_max $F0MAX --f0_min $F0MIN --frame_period $FRAMESHIFT --input wav/$fname.wav --output $TMP.float
        cat $TMP.float | \
	$X2X +aa | \
        awk '{if ($1 > 0.0) print $1,1;  else print 0,0}'  | \
	$ESTDIR/bin/ch_track -itype ascii -otype est_binary -s 0.005 -o diffsptk_f0/$fname.f0
	$FESTVOXDIR/src/general/smooth_f0 -o f0/$fname.f0 diffsptk_f0/$fname.f0 -otype ssff -lab lab/$fname.lab -silences $SILENCE -interpolate -postsmooth -postwindow 0.025
        # We can sometimes -1 as a f0, so stop that with a big hammer
        $ESTDIR/bin/ch_track f0/$fname.f0 |
        awk '{if ($1 > 0.0) print $1,$2; else print 0,0}' |
        $ESTDIR/bin/ch_track -itype ascii -otype est_binary -s 0.005 -o $fname.f0
        mv $fname.f0 f0/$fname.f0
	$ESTDIR/bin/ch_track diffsptk_f0/$fname.f0 | awk '{print $2}' > v/$fname.v
    rm -rf $TMP.*
done


