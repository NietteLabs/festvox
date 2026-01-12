#!/bin/bash

function extract_deb() {

    libfst_dev="download/libfst-dev/libfst-dev.deb"
    libfst="download/libfst/libfst.deb"

    #source: https://stackoverflow.com/questions/45355277/how-can-i-decompress-an-archive-file-having-zst-or-tar-zst
    for deb in $libfst $libfst_dev; do
        ar -x "$deb" data.tar.zst
        tar --use-compress-program=unzstd -xvf data.tar.zst -C prefix/
        rm data.tar.zst
    done

}

function setup() {
    mkdir model/
    mkdir data/
    mkdir tools/
    mkdir prefix/
    mkdir download/{libfst,libfst-dev} -p

    ARCH=$(uname -m)

    case "$ARCH" in
    x86_64)
        ARCH_DEB="amd64"
        ;;
    armv7l)
        ARCH_DEB="armhf"
        ;;
    aarch64)
        ARCH_DEB="arm64"
        ;;
    *)
        echo "$ARCH not support for get openfst package, is need compile OpenFST"
        exit 0
        ;;
    esac

    wget https://launchpad.net/ubuntu/+archive/primary/+files/libfst26_1.8.4-3_"$ARCH_DEB".deb -O download/libfst/libfst.deb
    wget https://launchpad.net/ubuntu/+archive/primary/+files/libfst-dev_1.8.4-3_"$ARCH_DEB".deb -O download/libfst-dev/libfst-dev.deb

    extract_deb
    git clone https://github.com/danijel3/Phonetisaurus tools/phonetisaurus
    git clone https://github.com/mitlm/mitlm.git tools/mitlm
    git clone https://github.com/kpu/kenlm tools/kenlm
}

function compile_all() {
    CPU=$(nproc)
    DIR_PREFIX=$PWD/prefix/
    echo "Compile Phonetisaurus"
    cd tools/phonetisaurus/ || exit
    ./configure --with-openfst-includes="$DIR_PREFIX"/usr/include/fst/ --with-openfst-libs="$DIR_PREFIX"/usr/lib/x86_64-linux-gnu --prefix "$HOME"/.local/
    make -j"$CPU" install

    cd ../../

    echo "Compile MitLM"
    cd tools/mitlm --prefix "$HOME"/.local/ || exit
    autoreconf -i
    ./configure --prefix "$HOME"/.local/
    make -j"$CPU" install

    cd ../../

    echo "Compile KenLM"
    cd tools/kenlm || exit
    ./configure --prefix "$HOME"/.local/
    make -j"$CPU" install

    cd ../../

}

function train_model() {
    dic=$1
    order=$2
    lm=$3

    if [[ -z "$dic" ]]; then
        echo "ERROR: Lexicon not set in input."
        exit 1
    fi

    if [[ -z "$lm" ]]; then
        echo "Set KenLM for build n-gram model."
        lm="kenlm"
    fi

    if [[ -z $order ]]; then

        line_dic=$(wc -l <"$dic")

        # Previne error for build ngram model in smail lexicons
        # https://github.com/danijel3/Phonetisaurus/pull/3
        if (("$line_dic" <= "1000")); then
            echo "Set order number to 4."
            order=4
        else
            echo "Set order number to 6."
            order=6
        fi

    fi

    python3 tools/phonetisaurus/src/scripts/phonetisaurus-train --lexicon "$dic" --lm "$lm" --ngram_order "$order" --dir_prefix model/ --verbose
}

function get_predict() {
    wordlist=$1
    output=$2

    if [[ -z "$wordlist" ]]; then
        echo "ERROR: Wordlist not set in input."
        exit 1
        if [[ ! -f "$wordlist" ]]; then
            echo "ERROR: Wordlist not found"
            exit 1
        fi
    fi

    if [[ -z "$output" ]]; then
        echo "INFO: Set output for output.dic"
        output=output.dic
    fi

    python3 tools/phonetisaurus/src/scripts/phonetisaurus-apply --model model/model.fst --word_list "$dic" >"$output"

}

help_m() {
    echo "bash ./phonetisaurus.sh setup - (Setup files and create folders)"
    echo "bash ./phonetisaurus.sh compile_all - (Compile all tools include all ngram builder tools)"
    echo "bash ./phonetisaurus.sh train lexicon ngram_order lm - (Train model for G2P)"
    echo "bash ./phonetisaurus.sh get_predict wordlist output_dic (Generante new pronunciations for wordlist)"
}

case "$1" in
setup)
    setup
    ;;
compile)
    compile_all
    ;;
train)
    train_model "$1" "$2" "$3"
    ;;
test)
    get_predict "$1" "$2"
    ;;
help)
    help_m
    ;;
*)
    help_m
    ;;
esac
