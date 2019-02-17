import sys
import cv2
import numpy as np
import os

w=int(os.getenv('width', 720))
h=int(os.getenv('height', 480))

while True:
    raw_image = sys.stdin.read(w*h*3)
    if len(raw_image) != 0:
        image = np.fromstring(raw_image, dtype='uint8')
        image = image.reshape((h,w,3))
        image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        ret, jpeg = cv2.imencode('.jpg', image)
        sys.stdout.write(jpeg.tobytes())
        sys.stdout.flush()
    else:
        break
