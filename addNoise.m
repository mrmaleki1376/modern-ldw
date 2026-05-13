
function noisyFrame = addNoise(frame, noiseType, params)
    % This function is used to add different types of noise to a frame
    
    % Inputs:
    %   frame - Image or a video frame
    %   noiseType - withoutnoise, gaussian, saltpepper or speckle
    %   params - noiseParams.mat file containing mean, variance and density
    %   params can be created using makeNoiseParams.m fucntion

    % Outputs:
    %   noisyFrame - A frame with noise applied to it

    % Handle different number of input arguments
    if nargin < 3
        params = struct();
    end

    % Type handling
    if ~isa(frame, 'uint8')
        frame = im2uint8(frame);
    end

    % swtich case for different noise types
    switch lower(noiseType)
        case 'withoutnoise'
            noisyFrame = frame;

        case 'gaussian'
            noisyFrame = imnoise(frame, 'gaussian', params.mean, params.variance);

        case 'saltpepper'
            noisyFrame = imnoise(frame, 'salt & pepper', params.density);

        case 'speckle'
            noisyFrame = imnoise(frame, 'speckle', params.variance);

        otherwise
            error('Unknown noise type: %s', noiseType);
    end
end

%{
Usage Example:

videoReader = VideoReader("video_assets\processed\highwayDashedLeftLine.mp4");

makeNoiseParams('noiseParams.mat', 0, 0.01, 0.1);
noiseParams = load('noiseParams.mat').noiseParams;

figure;

while hasFrame(videoReader)
    cleanFrame = readFrame(videoReader);
    noisyFrame = addNoise(cleanFrame, 'gaussian', noiseParams);

    imshow(noisyFrame);
    title('Noisy Video');
    drawnow;
end

close all;

%}