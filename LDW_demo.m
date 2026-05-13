% Read video
videoObj = VideoReader('video_assets\processed\highwayDashedLeftLine.mp4');

% Create figure
figure;

% Read and display frames
while hasFrame(videoObj)
    frame = readFrame(videoObj);

    noiseParams.mean = 0;
    noiseParams.variance = 0.01;
    noiseParams.density = 0.1;
    
    noisyFrame = addNoise(frame, 'gaussian',noiseParams);

    imshow(noisyFrame);

    title('Video Playback');

    drawnow;
end

close all;