  #!/bin/bash

. configs/.config

################################################################################

export dir='./input_stream_segments'
export height="0"
export width="0"
export fps="0"
export port="11111"
export output_stream_url=$rtmp_out
export input_stream_url=$rtmp_in
export segment_size="5"
export curr_segment="0"
export ff_loglvl="quiet"

./clearFolders.sh 2> /dev/null

################################################################################

fn_segment() {
  ffmpeg -y -hide_banner -fflags +genpts -loglevel $ff_loglvl -i $input_stream_url \
  -c:v copy  \
  -codec:a copy -start_number 0 -hls_time $segment_size -hls_wrap 5 -hls_list_size 5 -max_muxing_queue_size 1024 \
  -hls_segment_filename "$dir/%d.mp4" \
  -f hls ".m3u8"
}

################################################################################
fn_process() {

  inotifywait -q -e close_write -m --format "%f" $dir |
  while read -r f; do

    filename="$curr_segment.mp4"

    params=$(ffprobe -v error -loglevel $ff_loglvl -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of default=nw=1:nk=1 $input_stream_url)
    width=$(echo $params | cut -d' ' -f1)
    height=$(echo $params | cut -d' ' -f2)
    fps=$(echo $params | cut -d' ' -f3)
    echo "WIDTH = $width"
    echo "HEIGHT = $height"
    echo "FPS = $fps"
    echo "PROCESSING $filename ... "

    ffmpeg -loglevel $ff_loglvl -y -i "$dir/$filename" -vn -sn -c:a copy "audio_tmp.ts"

    python default.py $f $height $width | ffmpeg -loglevel $ff_loglvl -y -r $fps -f image2pipe -i - -c:v libx264 -pix_fmt yuv420p \
    -avoid_negative_ts make_zero -fflags +genpts "video_tmp.mp4"

    ffmpeg -loglevel $ff_loglvl -t $segment_size -i "./video_tmp.mp4" -t $segment_size -i "./input_stream_segments/$filename" -map 0:v:0 -map 1:a:0 -y "./processed_stream_segments/$curr_segment.mp4"

    curr_segment=$((curr_segment+1))
    if (( curr_segment > "4" )); then curr_segment="0"; fi
  done
}

################################################################################
fn_concat_and_push_to_stream() {
  ./concat_and_push_to_stream.sh
}

################################################################################

# fn_get_stream_params

fn_segment &
fn_segmentPID=$!

fn_process &
fn_process_PID=$!

fn_concat_and_push_to_stream &
fn_concat_and_push_to_stream_PID=$!

wait $netcatPID $fn_segmentPID $fn_process_PID $fn_concat_and_push_to_stream_PID
