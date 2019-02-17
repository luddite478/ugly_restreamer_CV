#!/bin/bash

watch_dir='processed_stream_segments'

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

<<<<<<< HEAD
# ffmpeg -y -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -q 1 -c:v libx264 -c:a copy -f mpegts "$output_stream_url" &
ffmpeg -y -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -c:v libx264 -f mpegts udp://0.0.0.0:1234  &
=======
ffmpeg -y -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -c:v libx264 -f flv $output_stream_url &
# ffmpeg -y -re -f concat -loglevel warning -safe 0 -i "${concat_pls:?}" -c:v libx264 yo.mp4 &

>>>>>>> 2021d6f... clean up
ffmpegPID=$!

inotifywait -q -e close_write -m --format "%f" $watch_dir |
while read -r filename; do
    echo "################################################################################"
    echo "###################### FOUND $filename FOR CONCATING ###########################"
    echo "################################################################################"
    fn_concat_feed "$watch_dir/$filename"
done

fn_concat_end

wait "${ffmpegPID:?}"
