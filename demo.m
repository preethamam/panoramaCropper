clc; close all; clear;

input.canvas_color = 'white';  %'black'| 'white'
input.blackRange = 5;
input.whiteRange = 250;
input.showCropBoundingBox = 1;

% Filenames
F1 = 'road.jpg';
F2 = 'swamp.png';
F3 = 'home.jpg';
F4 = 'result_15.jpg';
F5 = 'result_26.jpg';
F6 = 'out_6_NSH.jpg';
F7 = 'out_4_GrandCanyon1.jpg';


% Read image
stitchedImage = imread(F1);

% function call back
croppedImage = panoramaCropper(input, stitchedImage);

figure;
imshow(croppedImage)