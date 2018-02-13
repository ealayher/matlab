function [] = image_similarity(varargin)
% image_similarity.m
%
% Created: 11/25/2015, Evan Layher
% Revised: 02/12/2017, Evan Layher (input options, more efficient)
%
% --- LICENSE INFORMATION --- %
% Modified BSD-2 License - for Non-Commercial Use Only
%
% Copyright (c) 2018, The Regents of the University of California
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are 
% permitted for non-commercial use only provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this list 
%    of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice, this list 
%    of conditions and the following disclaimer in the documentation and/or other 
%    materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
% SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
% OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
% WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% For permission to use for commercial purposes, please contact UCSB?s Office of 
% Technology & Industry Alliances at 805-893-5180 or info@tia.ucsb.edu.
% --------------------------- %
%
% This function compares image files to identify duplicate or similar images
% Identifies similarity based on pixel by pixel comparisons
%
% Input path(s) of files or folders containing image files
% Output: Text file containing list of similar images (e.g. similar_images_p0_t1.txt)
%
% Options:
% [1] Input similarity threshold value: 0-1 (Default: 1)
%     -- Identifies images that have at least the similarity threshold of identical pixels
%     example: image_similarity('IMAGE-FOLDER-NAME', 1);
%
% [2] '-p' Pixel precision (Default: 0)
%     -- Identify similar pixels that have values within the pixel precision value
%     example: image_similarity('IMAGE-FOLDER-NAME', '-p', 0);
%
% [3] Resize images to have equal dimensions: '-r' = resize, '-nr' = do NOT resize (Default: '-nr')
%     -- Input the number of rows and columns (Default: row/column dimensions of the first image)
%     example: image_similarity('IMAGE-FOLDER-NAME', '-r', [256 256]);
%
% [4] '-s'/'-ns' Store images in memory: '-s' = store, '-ns' = do NOT store (Default: '-s')
%     -- Loads all images into memory, then checks for duplicates (Could overload memory)
%     example: image_similarity('IMAGE-FOLDER-NAME', '-s');

clc

% Default options:
similarityThreshold = 1; % 0-1, fraction of how many similar pixels images need to have
resizeImages = false; % True/false: Resizes all images to input dimensions or size of first image
rDim = []; % [], Default row dimension (if empty, then first image dimensions are default)
cDim = []; % [], Default column dimension (if empty, then first image dimensions are default)
storeImages = true; % True/false: Store images in memory (may overload memory if true)
pixPrec = 0; % Pixel precision
pixRead = false; % Do not read in pixel precision value

dirArray   = {}; % Input directories
imageArray = {}; % Valid image files

if nargin > 0
    for i = 1:length(varargin) % Loop through inputs
        checkFile = varargin{i};
        
        if isnumeric(checkFile) % Process number inputs
            if pixRead
                if checkFile(1) >= 0
                    pixPrec = checkFile(1);
                end
                
                pixRead = false; % Do not read in pixel value
                continue
            end
            
            for j = 1:length(checkFile)
                inNum = checkFile(j); % Input number
                
                if inNum < 0 % Invalid number
                    fprintf('INPUT NUMBERS MUST BE POSITIVE: %d\n', inNum)
                    return
                elseif inNum <= 1 % similarity threshold value
                    similarityThreshold = inNum;
                else % Assign to row or column (if missing)
                    if isempty(rDim)
                        rDim = inNum;
                    elseif isempty(cDim)
                        cDim = inNum;
                    end
                end % inNum < 0
            end % for j = 1:length(inputVar)
            
            continue % Skip to next varargin
        end % if isnumeric(inputVar)
        
        if exist(checkFile, 'dir') % Get all files inside of directories
            dirArray{(length(dirArray) + 1)} = checkFile;
        elseif exist(checkFile, 'file') % Check if file
            imageArray{(length(imageArray) + 1)} = checkFile;
        elseif strcmp(checkFile, '-nr') % Check if file
            resizeImages = false; % Do NOT resize images
        elseif strcmp(checkFile, '-ns') % Check if file
            storeImages = false; % Do NOT store images in memory
        elseif strcmp(checkFile, '-p') % Check if file
            pixRead = true; % Read in pixel precision value
        elseif strcmp(checkFile, '-r') % Check if file
            resizeImages = true; % Resize images
        elseif strcmp(checkFile, '-s') % Check if file
            storeImages = true; % Store images in memory
        else
            fprintf('NOT A FILE OR DIRECTORY: %s\n', checkFile)
        end
    end
else % No inputs specified
    fprintf('MUST INPUT IMAGE(S) AND/OR FOLDER(S)\n')
    return
end

if ~isempty(dirArray) % Get all files inside each input directory
    fprintf('SEARCHING FOR IMAGES IN %d FOLDER(S)\n\n', length(dirArray))
    for i = 1:length(dirArray)
        dirName  = dirArray{i};
        dirFiles = dir(dirName);
        
        if ~isempty(dirFiles)
            for j = 1:length(dirFiles)
                imageArray{(length(imageArray) + 1)} = [dirName, '/', dirFiles(j).name];
            end
        else
            fprintf('NO FILES FOUND INSIDE: %s\n', dirName)
        end
    end
end

if isempty(imageArray)
    fprintf('NO VALID IMAGE FILES FOUND\n')
    return
end

fprintf('CHECKING FOR VALID IMAGES: %d\n\n', length(imageArray))
allImages = {}; % Initialize array of images (if storeImages = true)
finalImageArray = {};  % Initialize array of image filenames
for i = 1:length(imageArray) % Loop thru filenames
    checkImage = imageArray{i}; % Filename
    
    try % Check for valid image
        checkPic = imread(checkImage); % Input image
    catch % Invalid image throws error
        fprintf('FILE NOT VALID IMAGE: %s\n', checkImage)
        continue
    end
    
    finalImageArray{(length(finalImageArray) + 1)} = checkImage;
    if resizeImages
        if isempty(rDim)
            rDim = size(checkPic, 1);
        end
        
        if isempty(cDim)
            cDim = size(checkPic, 2);
        end
    end % if i == 1 && resizeImages
    
    if storeImages
        if resizeImages
            allImages{(length(allImages) + 1)} = imresize(checkPic, [rDim cDim]);
        else
            allImages{(length(allImages) + 1)} = checkPic;
        end
    end
end

% Alert user of input parameters
if resizeImages
    fprintf('COMPARING %d IMAGES\nSIMILARITY THRESHOLD: %f\nPIXEL PRECISION: %d\nROW DIMENSION SIZE: %d\nCOLUMN DIMENSION SIZE: %d\n', ...
        length(finalImageArray), similarityThreshold, pixPrec, rDim, cDim)
else
    fprintf('COMPARING %d IMAGES\nSIMILARITY THRESHOLD: %f\nPIXEL PRECISION: %d\n', ...
        length(finalImageArray), similarityThreshold, pixPrec)
end

arraySize = length(finalImageArray);

outputFile = ['similar_images_p', num2str(pixPrec), '_t', num2str(similarityThreshold), '.txt'];
fid = fopen(outputFile, 'w'); % Create output file
if resizeImages
    fprintf(fid, 'Pixel precision: %d\nResized image dimensions: %dx%d\nSimilarity threshold: %f\n', ...
        pixPrec, rDim, cDim, similarityThreshold);
else % Exclude resized image information
    fprintf(fid, 'Pixel precision: %d\nSimilarity threshold: %f\n', ...
        pixPrec, similarityThreshold);
end

for i = 1:arraySize
    pic1 = finalImageArray{i};
    firstIdxComp = i + 1; % Do not duplicate comparisons
    
    if storeImages
        img1 = allImages{i};
    else % Load image individuall
        if resizeImages
            img1 = imresize(imread(pic1), [rDim cDim]); % Load/resize pic1
        else
            img1 = imread(pic1); % Load pic1
        end
    end % if storeImages
    
    img1Dim = size(img1);
    if i < arraySize % Do not compare same images
        firstSkip = true; % Reset value to alert use of skipped image
        mismatchCount = 0; % Reset mismatch count
        
        fprintf('[%d/%d] COMPARING IMAGES: %s\n', i, arraySize, pic1)
        
        for j = firstIdxComp:arraySize
            pic2 = finalImageArray{j};
            
            if storeImages
                img2 = allImages{j};
            else % Load image to compare
                if resizeImages
                    img2 = imresize(imread(pic2), [rDim cDim]); % Load/resize pic1
                else
                    img2 = imread(pic2); % Load pic1
                end
            end % if storeImages
            
            img2Dim = size(img2);
            if img1Dim == img2Dim
                skipImg = false;
            else % Images must have same dimensions
                skipImg = true;
            end
            
            if skipImg % Images must have same dimensions
                if firstSkip
                    fprintf('DIMENSION MISMATCH FOUND: ')
                    firstSkip = false;
                end
                
                mismatchCount = mismatchCount + 1;
                continue
            end
            
            if similarityThreshold == 1 && pixPrec == 1 % Searching for identical images
                if isequal(img1, img2) % Quickly identifies same image
                    simPercent = 1;
                else % Not identical
                    simPercent = 0;
                end
            else % Calculate similarity
                imgDiff = abs(img1 - img2); % Difference at each pixel
                imgElements = numel(imgDiff); % Same pixel values = 0
                imgZeros    = sum(imgDiff(:) <= pixPrec);   % Find zero (common) elements
                simPercent  = imgZeros / imgElements; % Similarity percentage
            end
            
            if simPercent == 1 % Identical images
                fprintf('IDENTICAL IMAGES (%f): %s %s\n', simPercent, pic1, pic2)
                fprintf(fid, [num2str(simPercent), ',', pic1, ',', pic2, '\n']);
            elseif simPercent >= similarityThreshold % Similar images
                fprintf('SIMILAR IMAGES   (%f): %s %s\n', simPercent, pic1, pic2)
                fprintf(fid, [num2str(simPercent), ',', pic1, ',', pic2, '\n']);
            end
        end % for j = firstIdxComp:arraySize
        
        if ~firstSkip % if dimension mismatch found
            fprintf('%d IMAGES\n', mismatchCount) % Print newline at end of sequence
        end
    end % if i < arraySize
end % for i = 1:arraySize
fclose(fid); % Close output file