import cv2
import subprocess as sp
import numpy as np
import sys

file_path=sys.argv[1]
h=int(sys.argv[2])
w=int(sys.argv[3])

def process_frame_test_bw(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    bw_3d = cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)
    ret, jpeg = cv2.imencode('.jpg', bw_3d)
    sys.stdout.write(jpeg.tobytes())
    pipe.stdout.flush()

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
        "-loglevel", "warning",
        '-i', file_path,
        '-pix_fmt', 'bgr24',
        '-vcodec', 'rawvideo',
        '-an','-sn',
        '-f', 'image2pipe', '-']

pipe = sp.Popen(command, stdout = sp.PIPE, bufsize=10**8)


while True:
    raw_image = pipe.stdout.read(w*h*3)
    if len(raw_image) > 0:
        image =  np.fromstring(raw_image, dtype='uint8')
        image = image.reshape((h,w,3))
        # if image is not None:
        #     cv2.imshow('Video', image)
        #
        # if cv2.waitKey(1) & 0xFF == ord('q'):
        #     break
        process_frame_test_bw(image)
        pipe.stdout.flush()
    else:
        break

    pipe.stdout.flush()

cv2.destroyAllWindows()
