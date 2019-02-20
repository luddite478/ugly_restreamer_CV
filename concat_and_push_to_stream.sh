#!/bin/bash

watch_dir=${output_dir:2}

# Next 3 functions are from https://trac.ffmpeg.org/wiki/Concatenate

fn_concat_init() {
    concat_pls=`mktemp -u -p . concat.XXXXXXXXXX.txt`
    concat_pls="${concat_pls#./}"
    mkfifo "${concat_pls:?}"
}

fn_concat_feed() {
    echo "Concating ${1:?} to the ouput stream ... "
    {
        >&2 echo "removing ${concat_pls:?}"
        rm "${concat_pls:?}"
        concat_pls=
        >&2 fn_concat_init
        echo 'ffconcat version 1.0'
        echo "file '${1:?}'"
        echo "file '${concat_pls:?}'"
    } >"${concat_pls:?}"
    echo
}

fn_concat_end() {
    echo "fn_concat_end"
    {
        >&2 echo "removing ${concat_pls:?}"
        rm "${concat_pls:?}"
    } >"${concat_pls:?}"
    echo
}

fn_concat_init

ffmpeg -y -loglevel warning -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -c:v $ff_encoder -f flv $output_stream_url &
# ffmpeg -y -loglevel warning -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -c:v $ff_encoder oupt.mp4 &

ffmpegPID=$!

inotifywait -q -e close_write -m --format "%f" $watch_dir |
while read -r filename; do
    printf "\n\n FOUND $filename FOR CONCATING \n\n"
    fn_concat_feed "$watch_dir/$filename"
done

fn_concat_end

wait "${ffmpegPID:?}"
