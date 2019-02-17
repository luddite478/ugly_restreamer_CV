import cv2
import subprocess as sp
import numpy as np
import sys
import time
from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE,SIG_DFL)

filename=sys.argv[1]
h=sys.argv[2]
w=sys.argv[3]

def process_frame(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blured = cv2.GaussianBlur(gray, (5,5), 0)
    edges = cv2.Canny(gray, 0, 30)
    edges_3d = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)
    edges_3d[np.logical_or(edges_3d, 0)] = 1
    edges_3d*=np.uint8([255,171,0])
    edges_3d = cv2.GaussianBlur(edges_3d, (5,5), 0)
    ret, jpeg = cv2.imencode('.jpg', edges_3d)
    sys.stdout.write(jpeg.tobytes())
    pipe.stdout.flush()

command = [ "ffmpeg",
        '-i', './input_stream_segments/1.avi',
        '-pix_fmt', 'bgr24',
        '-vcodec', 'rawvideo',
        '-an','-sn',
        '-f', 'image2pipe', '-']


pipe = sp.Popen(command, stdout = sp.PIPE, bufsize=10**8)


starttime = time.time()
try:

    while True:
        raw_image = pipe.stdout.read(w*h*3)

        if len(raw_image) != 0:
            image =  np.fromstring(raw_image, dtype='uint8')
            image = image.reshape((h,w,3))
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            ret, jpeg = cv2.imencode('.jpg', gray)
            sys.stdout.write(jpeg.tobytes())
            pipe.stdout.flush()
            process_frame(image)
        else:
            break

    file = open("testfile.txt","w")
    file.write(str(time.time()-starttime)+'\n')
except:
    print('sdfsdf')
    file = open("testfile.txt","w")
    file.write(str(time.time()-starttime)+'\n')
