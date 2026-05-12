% This function is used to add different types of noise to a frame %

function noisyFrame = addNoise(frame, noiseType, params)

    switch noiseType
        case 'gaussian'
            noisyFrame = imnoise(frame, 'gaussian', params.mean, params.variance);

        case 'saltpepper'
            noisyFrame = imnoise(frame, 'salt & pepper', params.density);

        case 'speckle'
            noisyFrame = imnoise(frame, 'speckle', params.variance);

    end
end

%{

videoReader = VideoReader("dataset\videos\processed\highwayDashedLeftLine.mp4");

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