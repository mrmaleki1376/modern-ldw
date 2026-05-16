clc;
clear;
close all;

% Read video
videoObj = VideoReader('video_assets\raw\downloaded_highway_01.MOV');

% Create large fullscreen figure
figure('Units','normalized','OuterPosition',[0 0 1 1]);

% LOR threshold
lorThresh = 0.3;

while hasFrame(videoObj)

    % Read current frame
    frame = readFrame(videoObj);
    [heightFrame, widthFrame, ~] = size(frame);

    % Load noise parameters and add Gaussian noise
    noiseParams = load('noiseParams.mat').noiseParams;
    noisyFrame = addNoise(frame, 'gaussian', noiseParams);

    % Detect lane information
    [leftRho, leftTheta, rightRho, rightTheta, ...
     leftXBottom, leftYBottom, leftXTop, leftYTop, ...
     rightXBottom, rightYBottom, rightXTop, rightYTop, ...
     smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(noisyFrame);

    % Create image for visualization
    laneLinesImg = frame;

    %% =========================
    % Calculate LOR
    %% =========================
    lor = calcLOR(leftXBottom, rightXBottom, ...
                  lorThresh, widthFrame/2);

    %% =========================
    % Lane Departure Logic
    %% =========================

    warningText = 'IN LANE';
    warningColor = 'green';
    laneColorLeft = 'green';
    laneColorRight = 'green';

    if lor <= 0

        warningText = 'WARNING: DRIFTING';
        warningColor = 'red';

        laneColorLeft = 'red';
        laneColorRight = 'red';



    end

    %% =========================
    % Add Red Overlay Warning
    %% =========================

    if lor <= 0

        redOverlay = cat(3, ...
            uint8(255 * ones(heightFrame, widthFrame)), ...
            uint8(zeros(heightFrame, widthFrame)), ...
            uint8(zeros(heightFrame, widthFrame)));

        alpha = 0.15;

        laneLinesImg = uint8( ...
            double(laneLinesImg) * (1 - alpha) + ...
            double(redOverlay) * alpha);

    end

    %% =========================
    % Draw Lane Lines
    %% =========================

    % Draw left lane line
    if ~isnan(leftXBottom) && ~isnan(leftXTop)

        laneLinesImg = insertShape( ...
            laneLinesImg, ...
            'Line', ...
            [leftXBottom leftYBottom leftXTop leftYTop], ...
            'Color', laneColorLeft, ...
            'LineWidth', 8);

    end

    % Draw right lane line
    if ~isnan(rightXBottom) && ~isnan(rightXTop)

        laneLinesImg = insertShape( ...
            laneLinesImg, ...
            'Line', ...
            [rightXBottom rightYBottom rightXTop rightYTop], ...
            'Color', laneColorRight, ...
            'LineWidth', 8);

    end

    %% =========================
    % Draw Center Reference Line
    %% =========================

    laneLinesImg = insertShape( ...
        laneLinesImg, ...
        'Line', ...
        [widthFrame/2 heightFrame widthFrame/2 0], ...
        'Color', 'white', ...
        'LineWidth', 4);

    %% =========================
    % Add LOR Text
    %% =========================

    laneLinesImg = insertText( ...
        laneLinesImg, ...
        [50 50], ...
        sprintf('LOR: %.3f', lor), ...
        'FontSize', 40, ...
        'BoxColor', 'yellow', ...
        'TextColor', 'black', ...
        'BoxOpacity', 0.7);

    %% =========================
    % Add Warning Message
    %% =========================

    laneLinesImg = insertText( ...
        laneLinesImg, ...
        [50 130], ...
        warningText, ...
        'FontSize', 40, ...
        'BoxColor', warningColor, ...
        'TextColor', 'white', ...
        'BoxOpacity', 0.7);

    %% =========================
    % Add Bottom Status Bar
    %% =========================

    statusBarHeight = 40;

    if lor <= 0
        barColor = 'red';
        statusText = 'LANE DEPARTURE DETECTED';
    else
        barColor = 'green';
        statusText = 'SAFE DRIVING';
    end

    laneLinesImg = insertShape( ...
        laneLinesImg, ...
        'FilledRectangle', ...
        [0 heightFrame-50 widthFrame 80], ...
        'Color', barColor, ...
        'Opacity', 0.6);

    laneLinesImg = insertText( ...
        laneLinesImg, ...
        [50 heightFrame-statusBarHeight-20], ...
        statusText, ...
        'FontSize', 40, ...
        'BoxOpacity', 0, ...
        'TextColor', 'white');

    %% =========================
    % Visualization
    %% =========================

    clf;

    % Create tiled layout
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

    % Lane detection + warning
    nexttile([1 3]);
    imshow(laneLinesImg);
    title('Lane Detection + LOR Warning');

    drawnow;

end

close all;