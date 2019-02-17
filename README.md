Ugly re-streaming service with OpenCV processing support. The main goal was to wirelessly get TCP audio/video stream as input, make something with video in OpenCV and be able to output synchronized audio/video stream.

To use this you need to run *./start* and run some TCP-streaming script on the camera side. I am using Raspberry Pi Zero, camera module and  [picam](https://github.com/iizukanao/picam) library (code example in *piScript.sh*).

Steps, which script perform:
1. Listening on specified port
2. Segmenting incoming stream and put N-sec chunks into the input_stream_segments folder
3. Splitting those chunks into audio and video tracks
4. Processing video in python script
5. Merging audio and video back and streaming somewhere

TODOS:
1. Segments auto-delete
2. Make python-script process whole segment, not every frame i.e figure out why cpu is at 99%
3. Connect ffmpeg processes in fn_process() with pipes somehow
4. Fix many random bugs  

Libs used:
ffmpeg
opencv-python
inotifytools
netcat
