#!/bin/bash

. config/.config

################################################################################

echo $rtmp_out
export dir='./input_stream_segments'
export height="0"
export width="0"
export fps="0"
export port="11111"
export output_stream_url=$rtmp_out
export input_stream_url=$rtmp_in
export segment_size="10"
export curr_segment="0"
export ff_loglvl="quiet"

./clearFolders.sh 2> /dev/null

printf "\n FOLDERs \n"
  ls input_stream_segments
  ls processed_stream_segments
printf "  fodlers end\n \n"

fn_segment() {
  printf "\n enter segments \n"
  ls input_stream_segments
  echo "<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>"
  ffmpeg -y -loglevel warning -fflags +genpts -loglevel debug -i $input_stream_url \
  -c:v copy  \
  -codec:a copy -start_number 0 -hls_time 10 -hls_wrap 10 -hls_list_size 5 -max_muxing_queue_size 1024 \
  -f hls ".m3u8"
}

fn_process() {
  inotifywait -q -e close_write -m --format "%f" $dir |
  while read -r f; do
    printf "\n input_stream_segments: \n"
    ls input_stream_segments

    printf "\n\n INOTIFY-WAIT: NEW FILE $f \n\n"

    filename="$curr_segment.ts"
    printf "filename: $filename"
  done
}



fn_segment &
fn_segmentPID=$!

fn_process &
fn_process_PID=$!

wait $fn_segmentPID $fn_process_PID 
