import cv2
import subprocess as sp
import numpy as np
import sys
import time


def process_frame(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blured = cv2.GaussianBlur(gray, (5,5), 0)
    edges = cv2.Canny(gray, 0, 30)
    edges_3d = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)
    edges_3d[np.logical_or(edges_3d, 0)] = 1
    edges_3d*=np.uint8([255,171,0])
    edges_3d = cv2.GaussianBlur(edges_3d, (5,5), 0)
    return edges_3d



cap = cv2.VideoCapture(0)

while(True):
    # Capture frame-by-frame
    ret, frame = cap.read()

    # Our operations on the frame come here
    gray = process_frame(frame)

    # Display the resulting frame
    cv2.imshow('frame',gray)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# When everything done, release the capture
cap.release()
cv2.destroyAllWindows()
