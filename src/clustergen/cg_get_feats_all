#!/bin/bash
#MIT License
#Copyright (c) 2025 NietteLabs
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
###########################################################################
##                                                                       ##
##  Author: Pallas13 (edsondasilvaguedes0@gmail) 2025                    ##
##                                                                       ##
###########################################################################
# Extraction feats and mcep for all phones of festival/coeffs, using parallel for multiples process.

if command -v parallel >&2; then
    echo parallel is available
else
    echo parallel is not available, please install in your system
    exit 0
fi

CPUS="$(nproc)"
make_all_feats() {
    DATABASE=$1
    rm festival/coeffs/cg_all.{feats,mcep}
    awk '{print $2}' "$DATABASE" | parallel -j"$CPUS" --bar --progress cat festival/coeffs/{}.feats >>festival/coeffs/cg_all.feats
    awk '{print $2}' "$DATABASE" | parallel -j"$CPUS" --bar --progress cat festival/coeffs/{}.mcep >>festival/coeffs/cg_all.mcep
    cut --complement -f2 -d" " festival/coeffs/cg_all.feats | sort -g >festival/coeffs/cg_all_sorted.feats
    cat festival/coeffs/cg_all.mcep | sort -g >festival/coeffs/cg_all_sorted.mcep
}

make_units() {
    cat festival/coeffs/cg_all_sorted.{feats,mcep} | cut --complement -f2 -d" " | cut -f1 -d" " | sort -u >festival/disttabs/unittypes
}

make_feats_by_units() {
    UNIT=$1
    SED="/^$UNIT/p"
    TMP=tmp_"$UNIT"_$$
    cat festival/coeffs/cg_all_sorted.feats | cut --complement -f2 -d" " | sed -n $SED | sort >festival/feats/"$UNIT".feats.unsorted
    cat festival/coeffs/cg_all_sorted.mcep | sed -n $SED | sort >festival/feats/"$UNIT".mcep.unsorted
    LINE_FEATS=$(echo "$(wc -l <festival/feats/"$UNIT".feats.unsorted)" - 1 | bc)
    LINE_MCEP=$(echo "$(wc -l <festival/feats/"$UNIT".mcep.unsorted)" - 1 | bc)

    seq 0 "$LINE_FEATS" >$TMP.header.feats
    seq 0 "$LINE_MCEP" >$TMP.header.mcep

    paste -d" " $TMP.header.feats festival/feats/"$UNIT".feats.unsorted >festival/feats/"$UNIT".feats
    paste -d" " $TMP.header.mcep festival/feats/"$UNIT".mcep.unsorted | cut --complement -f1,2 -d" " | $ESTDIR/bin/ch_track -itype ascii -otype est_binary -s 0.005 -o festival/disttabs/"$UNIT".mcep

    $ESTDIR/bin/ch_track -c 0 festival/disttabs/"$UNIT".mcep -otype ascii -o $$.f0
    cut -d " " -f 2- festival/feats/"$UNIT".feats >$$.mcep
    paste -d " " $$.f0 $$.mcep >festival/feats/"$UNIT"_f0.feats
    rm -f $$.f0 $$.mcep

    rm $TMP.*
}

export -f make_feats_by_units

make_all_feats $1
make_units
cat festival/disttabs/unittypes | parallel -j"$CPUS" --bar --progress make_feats_by_units {}
