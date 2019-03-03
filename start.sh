#!/bin/bash

. configs/.config

################################################################################

export input_dir='./input_stream_segments'
export output_dir='./processed_stream_segments'
export status="idle"
export height="0"
export width="0"
export fps="0"
export port="11111"
export output_stream_url=$rtmp_out
export input_stream_url=$rtmp_in
export segment_size="5"
export curr_segment="0"
export ff_loglvl="quiet"
export hardware_acceleration=$1
export time_window="4000"

if [[ $hardware_acceleration == "GPU" ]]; then
export ff_decoder="h264_cuvid"
export ff_encoder="h264_nvenc"
elif [[ $hardware_acceleration == "CPU" ]]; then
export ff_decoder="h264"
export ff_encoder="libx264"
else
echo specify hardware_acceleration: GPU OR CPU
exit 1
fi

./clearFolders.sh 2> /dev/null

################################################################################

fn_wait_next_n_sec_for_new_file_if_no_file_restart() {
  while [[ status == "idle" ]]; do
    last_segment_processed_time=$1
    now=$(date +%s%3N)

    if [[ $(($now - $last_segment_processed_time)) -gt $time_window ]]; then
      printf "\n\n LAST SEGMENT RECEIVED MORE THAN 4 SEC AGO, RESTARTING ... \n\n"
      exec "./start.sh $hardware_acceleration"
    fi
    sleep 0.05
  done
}

################################################################################

fn_segment() {
  ffmpeg -y -hide_banner -fflags +genpts -loglevel $ff_loglvl -i $input_stream_url \
  -c:v copy  \
  -codec:a copy -start_number 0 -hls_time $segment_size -hls_wrap 5 -hls_list_size 5 -max_muxing_queue_size 1024 \
  -hls_segment_filename "$input_dir/%d.mp4" \
  -f hls ".m3u8"
}

################################################################################
fn_process() {

inotifywait -q -e close_write -m --format "%f" $input_dir |
while read -r f; do
  start=$(date +%s%3N)
  status="processing"

  filename="$curr_segment.mp4"

  params=$(ffprobe -v error -loglevel $ff_loglvl -select_streams v:0 -show_entries stream=width,height,r_frame_rate -of default=nw=1:nk=1 "$input_dir/$filename")
  width=$(echo $params | cut -d' ' -f1)
  height=$(echo $params | cut -d' ' -f2)
  fps=$(echo $params | cut -d' ' -f3)

  if [[ $width == "0" ]] || [[ $height == "0" ]]; then
    printf "\n\n BAD SEGMENT WITH WIDTH $width , HEIGHT $height and FPS $fps, RESTARTING"
    exec "./start.sh $hardware_acceleration"
  fi
  printf "PROCESSING $filename ... \nWIDTH = $width HEIGHT = $height FPS = $fps"

  if [[ $hardware_acceleration == "GPU" ]]; then
    ./app "$input_dir/$filename" $width $height $fps $ff_decoder $ff_encoder $ff_loglvl
  else
    time python default.py "$input_dir/$filename" $height $width | ffmpeg -loglevel $ff_loglvl -y -r $fps -f image2pipe -i - -c:v $ff_encoder -pix_fmt yuv420p \
    -avoid_negative_ts make_zero -fflags +genpts "video_tmp.mp4"
  fi

  ffmpeg -loglevel warning -t $segment_size -i "./video_tmp.mp4" -t $segment_size -i "$input_dir/$filename" -map 0:v:0 -map 1:a:0 -c:v $ff_encoder -qp 1 -y "$output_dir/$curr_segment.mp4"

  curr_segment=$((curr_segment+1))
  if (( curr_segment > "4" )); then curr_segment="0"; fi
  status="idle"

  end=$(date +%s%3N)
  printf "\n\n fn_process runtime: $((end-start)) \n\n"

  fn_wait_next_n_sec_for_new_file_if_no_file_restart $end
done
}

################################################################################
fn_concat_and_push_to_stream() {
./concat_and_push_to_stream.sh
}

################################################################################

fn_segment &
fn_segmentPID=$!

fn_process &
fn_process_PID=$!

fn_concat_and_push_to_stream &
fn_concat_and_push_to_stream_PID=$!

wait $netcatPID $fn_segmentPID $fn_process_PID $fn_concat_and_push_to_stream_PID
