% Read video
videoObj = VideoReader('video_assets\processed\highwayDashedLeftLine.mp4');

% Create large fullscreen figure
figure('Units','normalized','OuterPosition',[0 0 1 1]);

while hasFrame(videoObj)

    frame = readFrame(videoObj);

    noiseParams = load('noiseParams.mat').noiseParams;
    noisyFrame = addNoise(frame, 'gaussian', noiseParams);

    [leftRho, leftTheta, rightRho, rightTheta, ...
     leftXBottom, leftYBottom, leftXTop, leftYTop, ...
     rightXBottom, rightYBottom, rightXTop, rightYTop, ...
     smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(noisyFrame);

    clf;

    % Compact layout
    t = tiledlayout(2,3, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    % Original frame
    nexttile;
    imshow(frame);
    title('Original Frame');

    % Noisy frame
    nexttile;
    imshow(noisyFrame);
    title('Noisy Frame');

    % Smooth image
    nexttile;
    imshow(smoothImg, []);
    title('Smooth Image');

    % Masked edges
    nexttile;
    imshow(maskedEdges, []);
    title('Masked Edges');

    % ROI image
    nexttile([1 2]);   % make ROI image larger
    imshow(roiImg);
    title('ROI Image');

    drawnow;
end

close all;