"""
%%***********************************************************************%
%*                           Panorama Cropper                           *%
%*        Crops a fully stitched panorama with black/white background.  *%
%*                                                                      *%
%* Code author: Preetham Manjunatha                                     *%
%* Github link: https://github.com/preethamam
%* Date: 11/24/2021                                                     *%
%************************************************************************%

%---------------------------------------------------------------------------------
% The following function was inspired by the:
% https://ppwwyyxx.com/blog/2016/How-to-Write-a-Panorama-Stitcher/
% https://www.pyimagesearch.com/2018/12/17/image-stitching-with-opencv-and-python/
% translated and simplied by Preetham Manjunatha.
%---------------------------------------------------------------------------------
%
% It has tested extensively on multiple images, although for loops
% are slow, produces accurate crops when the input.blackRange
% and input.whiteRange are intutively passed to the function.
% Assumes panorama is surrounded by black or white canvas.
%---------------------------------------------------------------------------------
"""


import cv2 as cv
import numpy as np
import imutils
import glob
from numba import jit


def crop_stitched_image (stitched, canvas_color = 'black'):

    # Print cropping
    print("[INFO] cropping...")
    
    # Initilize the variables
    w = stitched.shape[1]
    h = stitched.shape[0]
    
    # Convert the stitched image to grayscale and threshold it
    # such that all pixels greater than zero are set to 255
    # (foreground) while all others remain 0 (background)
    gray = cv.cvtColor(stitched, cv.COLOR_BGR2GRAY)
    if canvas_color == 'black':
        thresh = cv.threshold(gray, 5, 255, cv.THRESH_BINARY)[1]
    else:
        thresh = cv.threshold(gray, 254, 255, cv.THRESH_BINARY_INV)[1]   
    
    # Find all external contours in the threshold image then find
    # the *largest* contour which will be the contour/outline of
    # the stitched image
    cnts = cv.findContours(thresh.copy(), cv.RETR_EXTERNAL, cv.CHAIN_APPROX_NONE)
    cnts = imutils.grab_contours(cnts)
    c = max(cnts, key=cv.contourArea)
    
    # Mask or stencil
    stencil_inner = np.zeros(stitched.shape, dtype=np.uint8)
    cv.fillPoly(stencil_inner, pts =[c], color=(255,255,255)) 
    stencil_outer = ~stencil_inner
    
    # Canvas outer indices
    canvas_outer_indices = np.where(stencil_outer == [255])

    # Normalize the image to -1 and others
    stitched = np.asarray(stitched, dtype=np.float32)    
    stitched[canvas_outer_indices] = -255
    stitched = stitched / 255.0


    @jit(nopython=True)
    def bulkRun():
        maxarea = 0
        height = np.zeros((w)).astype(np.int32) 
        left = np.zeros((w)).astype(np.int32) 
        right= np.zeros((w)).astype(np.int32) 
                
        ll = 0
        rr = 0 
        hh = 0 
        nl = 0
    
        for line in range(h):
            for k in range(w):
                p = stitched[line][k]
                m = max(max(p[0], p[1]), p[2])
                height[k] =  0 if m < 0 else height[k] + 1	#find Color::NO
                
    
            for k in range(w):
                left[k] = k;            
                while ((left[k] > 0) and (height[k] <= height[left[k] - 1])):
                    left[k] = left[left[k] - 1]
                    
            for k in range(w - 1, -1, -1):
                right[k] = k
                while ((right[k] < w - 1) and (height[k] <= height[right[k] + 1])):
                    right[k] = right[right[k] + 1]
                    
            for k in range(w):
                val = (right[k] - left[k] + 1) * height[k]
                if(maxarea < val):
                    maxarea = val
                    ll = left[k] 
                    rr = right[k]
                    hh = height[k] 
                    nl = line
        
        return ll, rr, hh, nl
    
    ll, rr, hh, nl = bulkRun()
    
    cropH = hh + 1
    cropW = rr - ll + 1
    offsetx = ll
    offsety = nl - hh + 1
    
    stitched *= 255

    return stitched[offsety : offsety + cropH, offsetx : offsetx + cropW].astype(np.uint8)

#%% Main routine
def main():

    # Read stitched image
    image = cv.imread('result_26.jpg')

    # write the output stitched and cropped image to disk
    # stitched_cropped = crop_stitched_image (image, 'white')
    stitched_cropped = crop_stitched_image (image, 'black')
    cv.imwrite('cropped.jpg', stitched_cropped)
        
    print("Done")

if __name__ == '__main__':
    main()
    cv.destroyAllWindows()
