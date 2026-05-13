% This function is used to add different types of noise to a frame %

function noisyFrame = addNoise(frame, noiseType, params)

    if nargin < 3
        params = struct();
    end

    if ~isa(frame, 'uint8')
        frame = im2uint8(frame);
    end

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

videoReader = VideoReader("video_assets\processed\highwayDashedLeftLine.mp4");

noiseParams.mean = 0;
noiseParams.variance = 0.01;
noiseParams.density = 0.2;

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