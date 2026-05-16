% Read video

videoObj = VideoReader('video_assets\raw\downloaded_highway_01.MOV');

% Create large fullscreen figure
figure('Units','normalized','OuterPosition',[0 0 1 1]);

lorThresh = 0.3;

while hasFrame(videoObj)

    % Read current frame
    frame = readFrame(videoObj);
    [heightFrame, widthFrame, channels] = size(frame);

    % Load noise parameters and add Gaussian noise
    noiseParams = load('noiseParams.mat').noiseParams;
    noisyFrame = addNoise(frame, 'gaussian', noiseParams);

    % Detect lane information
    [leftRho, leftTheta, rightRho, rightTheta, ...
     leftXBottom, leftYBottom, leftXTop, leftYTop, ...
     rightXBottom, rightYBottom, rightXTop, rightYTop, ...
     smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(noisyFrame);

    % Create image for lane visualization
    laneLinesImg = frame;

    % Draw left lane line
    if ~isnan(leftXBottom) && ~isnan(leftXTop)
        laneLinesImg = insertShape(laneLinesImg, 'Line', ...
            [leftXBottom leftYBottom leftXTop leftYTop], ...
            'Color', 'green', ...
            'LineWidth', 5);
    end

    % Draw right lane line
    if ~isnan(rightXBottom) && ~isnan(rightXTop)
        laneLinesImg = insertShape(laneLinesImg, 'Line', ...
            [rightXBottom rightYBottom rightXTop rightYTop], ...
            'Color', 'red', ...
            'LineWidth', 5);
    end

    % Calculate LOR
    lor = calcLOR(leftXBottom, rightXBottom, lorThresh, widthFrame/2);

    % Add LOR text on image
    laneLinesImg = insertText(laneLinesImg, ...
        [50 50], ...                         % Text position
        sprintf('LOR: %.3f', lor), ...
        'FontSize', 100, ...
        'BoxColor', 'yellow', ...
        'TextColor', 'black', ...
        'BoxOpacity', 0.7);

    % Clear current figure
    clf;

    % Create tiled layout (2 rows x 4 columns)
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

    % Smoothed image
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

    % Lane detection + LOR
    nexttile;
    imshow(laneLinesImg);
    title('Detected Lane Lines with LOR');

    drawnow;
end

close all;