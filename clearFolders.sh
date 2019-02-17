#!/bin/bash

if [ -d input_stream_segments ]; then
  rm input_stream_segments/*.avi
  rm input_stream_segments/*.ts
  rm input_stream_segments/*.m3u8
  rm input_stream_segments/*.mp4
else
  mkdir input_stream_segments;
fi

if [ -d processed_stream_segments ]; then
  rm processed_stream_segments/*.avi
  rm processed_stream_segments/*.ts
  rm processed_stream_segments/*.mp4
else
  mkdir processed_stream_segments;
fi

if [ -f 'audio_tmp.mp2' ]; then rm 'audio_tmp.mp2'; fi
if [ -f 'video_tmp.264' ]; then rm 'video_tmp.264'; fi
