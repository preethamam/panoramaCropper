function croppedImage = panoramaCropper(input, stitchedImage)
    
%%***********************************************************************%
%*                           Panorama Cropper                           *%
%*        Crops a fully stitched panorama with black/white background.  *%
%*                                                                      *%
%* Code author: Preetham Manjunatha                                     *%
%* Github link: https://github.com/preethamam
%* Date: 11/24/2021                                                     *%
%************************************************************************%
%
%************************************************************************%
%
% Usage: croppedImage = panoramaCropper(input, stitchedImage)
% Inputs: input.canvas_color            - Background canvas color: 'black'
%                                         | 'white'
%         input.blackRange              - Threshold value > 0 and 
%                                         < some number close to 0 (e.g, 5, 10).     
%         input.whiteRange              - Threshold value close to 255  
%                                         (e.g, 254, 250, 236,...)
%         input.showCropBoundingBox     - Display the cropping bounding box
% 
% Outputs: croppedImage - Final cropped image

%------------------------------------------------------------------------------------
% The following function was inspired by the:
% https://ppwwyyxx.com/blog/2016/How-to-Write-a-Panorama-Stitcher/
% https://www.pyimagesearch.com/2018/12/17/image-stitching-with-opencv-and-python/
% translated and simplied by Preetham Manjunatha.
%------------------------------------------------------------------------------------
%
% It has tested extensively on multiple images, although MATLAB for loops
% are slow, produces accurate crops when the input.blackRange
% and input.whiteRange are intutively passed to the function.
% Assumes panorama is surrounded by black or white canvas.
%------------------------------------------------------------------------------------

    % Initilize the variables
    w = size(stitchedImage,2);
    h = size(stitchedImage,1);
    
    % Convert the stitched image to grayscale and threshold it
    % such that all pixels greater than zero are set to 255
    % (foreground) while all others remain 0 (background)
    gray = rgb2gray(stitchedImage);
    if strcmp(input.canvas_color,'black')
        BW = imbinarize(gray, input.blackRange/255);
    else
        BW = imbinarize(gray, input.whiteRange/255);
        BW = imcomplement(BW);
    end

    % Find all external contours in the threshold image then find
    % the *largest* contour which will be the contour/outline of
    % the stitched image
    BW2 = imfill(BW, 'holes');
    
    % Canvas outer indices
    canvas_outer_indices = BW2 == 0;

    % Normalize the image to -1 and others
    stitched = double(stitchedImage);
    stitched(repmat(canvas_outer_indices,1,1,3)) = -255;
    stitched = stitched / 255.0;

    % Get the crop indices
    maxarea = 0;
    height  = zeros(1,w);
    left    = zeros(1,w); 
    right   = zeros(1,w);
            
    ll = 0;
    rr = 0;
    hh = 0; 
    nl = 0;
    
    for line = 1:h
        for k = 1:w
            p = stitched(line,k,:);
            m = max(max(p(1), p(2)), p(3));
            if m < 0 
                height(k) =  0; 
            else 
                height(k) = height(k) + 1; % find Color::NO
            end
        end
            
        for k = 1:w
            left(k) = k;            
            while (left(k) > 1 && (height(k) <= height(left(k) - 1)))
                left(k) = left(left(k) - 1);
            end
        end
                
        for k = w - 1:-1:1
            right(k) = k;
            while (right(k) < w - 1 && (height(k) <= height(right(k) + 1)))
                right(k) = right(right(k) + 1);
            end
        end
                
        for k = 1:w
            val = (right(k) - left(k) + 1) * height(k);
            if(maxarea < val)
                maxarea = val;
                ll = left(k); 
                rr = right(k);
                hh = height(k); 
                nl = line;
            end
        end
    end
    
    % Crop indexes
    cropH = hh + 1;
    cropW = rr - ll + 1;
    offsetx = ll;
    offsety = nl - hh + 1;

    % Cropped image
    croppedImage = stitchedImage(offsety : offsety + cropH, offsetx : offsetx + cropW,:);  

    % Show tight bounding box
    if (input.showCropBoundingBox)
        figure(1); 
        imshow(stitchedImage);
        hold on
        rectangle('Position',[offsetx offsety cropW cropH], 'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle', '--')
        hold off
    end
end