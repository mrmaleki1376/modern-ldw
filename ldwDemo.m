% Read video
videoObj = VideoReader('video_assets\raw\downloaded_highway_02.MOV');

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

    % Create a separate image to draw detected lane lines
    laneLinesImg = frame;

    % Draw left lane line
    if ~isnan(leftXBottom) && ~isnan(leftXTop)
        laneLinesImg = insertShape(frame, 'Line', ...
            [leftXBottom leftYBottom leftXTop leftYTop], ...
            'Color', 'green', 'LineWidth', 5);
    end

    % Draw right lane line
    if ~isnan(rightXBottom) && ~isnan(rightXTop)
        laneLinesImg = insertShape(laneLinesImg, 'Line', ...
            [rightXBottom rightYBottom rightXTop rightYTop], ...
            'Color', 'red', 'LineWidth', 5);
    end

    clf;

    % Updated layout (2x4)
    t = tiledlayout(2,4, ...
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
    nexttile;
    imshow(roiImg);
    title('ROI Image');

    % Lane lines image
    nexttile;
    imshow(laneLinesImg);
    title('Detected Lane Lines');

    drawnow;
end

close all;