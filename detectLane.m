clear; clc; close all;

videoFile = 'highwaySolidLines.mp4';   % change to your video
showLive = true;                           % live display of lane overlay
showROIView = true;                        % display ROI video in second window
saveOutput = true;                         % save main lane overlay video
saveROI = true;                            % <-- NEW: save ROI masked video separately
bufferSize = 3;                            % smoothing frames

%  Noise selection
disp('Select noise type:');
disp('1. No noise');
disp('2. Gaussian noise');
disp('3. Salt & Pepper noise');
disp('4. Speckle noise');
noiseChoice = input('Enter choice (1/2/3/4): ');

% Determine noise name for filename 
switch noiseChoice
    case 1
        noiseName = 'withoutNoise';
    case 2
        noiseName = 'gaussian';
    case 3
        noiseName = 'saltpepper';
    case 4
        noiseName = 'speckle';
    otherwise
        error('Invalid choice. Please restart and enter 1, 2, 3 or 4.');
end

%  Noise parameters
noiseParams.mean = 0;
noiseParams.variance = 0.01;
noiseParams.density = 0.01;

%  Setup video IO for main output 
[vReader, vWriter, videoPlayer, outFile] = setupVideoIO(videoFile, saveOutput, showLive, noiseName);
if isempty(vReader)
    error('Could not open video file.');
end

% <-- NEW: Setup ROI video writer
roiWriter = [];
if saveROI
    [p, n, e] = fileparts(videoFile);
    roiOutFile = fullfile(p, [n, '_', noiseName, '_ROI', e]);
    fprintf('ROI output video: %s\n', roiOutFile);
    if exist(roiOutFile, 'file') == 2
        delete(roiOutFile);
    end
    roiWriter = VideoWriter(roiOutFile, 'MPEG-4');
    roiWriter.FrameRate = vReader.FrameRate;
    open(roiWriter);
end

% Second video player for ROI view (optional)
roiPlayer = [];
roiFig = [];
if showROIView
    try
        roiPlayer = vision.VideoPlayer('Position', [750, 100, 640, 360]);
        roiPlayer.Name = 'ROI (Masked Image)';
    catch
        warning('Vision.VideoPlayer not available for ROI; using figure.');
        roiPlayer = [];
        roiFig = figure('Name', 'ROI View');
    end
end

% Initialize smoothing buffers
[rhoBuf, thetaBuf] = initBuffers(bufferSize);

%  Process each frame
frame = 0;
while hasFrame(vReader)
    rgb = readFrame(vReader);
    frame = frame + 1;

    % Apply noise if needed 
    if noiseChoice == 1
        processedFrame = rgb;
    else
        processedFrame = addNoise(rgb, noiseName, noiseParams);
    end

    % Detect lanes AND get ROI debugging outputs
    [lRho, lTheta, rRho, rTheta, ...
     ~, ~, ~, ~, ...               % ignore endpoints (5-8)
     ~, ~, ~, ~, ...               % ignore more endpoints (9-12) 
     smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(processedFrame);

    % Smooth lane parameters 
    [sLrho, sLtheta, sRrho, sRtheta, rhoBuf, thetaBuf] = ...
        smoothParams(lRho, lTheta, rRho, rTheta, rhoBuf, thetaBuf);

    % Draw lanes on the processed frame 
    annotated = drawLane(processedFrame, sLrho, sLtheta, sRrho, sRtheta, roiTopY);

    % Display lane overlay in main player
    if showLive && ~isempty(videoPlayer)
        step(videoPlayer, annotated);
    elseif showLive && isempty(videoPlayer)
        imshow(annotated); title(sprintf('Lane Overlay - Frame %d', frame)); drawnow;
    end

    % ROI image (convert to RGB for colour video writers/players)
    roiRGB = repmat(uint8(roiImg), [1,1,3]);

    % Display ROI in second player if enabled
    if showROIView
        if ~isempty(roiPlayer)
            step(roiPlayer, roiRGB);
        elseif ~isempty(roiFig) && ishandle(roiFig)
            figure(roiFig);
            imshow(roiRGB); title(sprintf('ROI (Masked) - Frame %d', frame)); drawnow;
        end
    end

    % Save main lane overlay video
    if saveOutput && ~isempty(vWriter)
        writeVideo(vWriter, annotated);
    end

    % <-- NEW: Save ROI video
    if saveROI && ~isempty(roiWriter)
        writeVideo(roiWriter, roiRGB);
    end

    if mod(frame,100)==0
        fprintf('Frame %d processed\n',frame);
    end
end

% Cleanup
cleanUp(videoPlayer, vWriter, saveOutput, showLive, outFile, frame);
if saveROI && ~isempty(roiWriter)
    close(roiWriter);
    fprintf('ROI video saved.\n');
end
if showROIView && ~isempty(roiPlayer)
    release(roiPlayer);
    delete(roiPlayer);
end
if ~isempty(roiFig) && ishandle(roiFig)
    close(roiFig);
end

% Force-close the main video player window
if showLive && ~isempty(videoPlayer)
    try
        delete(videoPlayer);
    catch
    end
end

% ========== LOCAL SUPPORT FUNCTIONS (unchanged except drawLane is included) ==========
function [vR, vW, vP, outF] = setupVideoIO(fname, saveOut, showLive, noiseName)
    if ~exist(fname, 'file')
        error('File not found: %s', fname);
    end
    vR = VideoReader(fname);
    [p, n, e] = fileparts(fname);
    outF = fullfile(p, [n, '_', noiseName, '_output', e]);
    fprintf('Output video: %s\n', outF);
    vW = []; vP = [];
    if exist(outF, 'file') == 2
        delete(outF);
        fprintf('Deleted previous output file: %s\n', outF);
    end
    if saveOut
        vW = VideoWriter(outF, 'MPEG-4');
        vW.FrameRate = vR.FrameRate;
        open(vW);
    end
    if showLive
        try
            vP = vision.VideoPlayer('Position', [100,100,640,360]);
        catch
            warning('Vision.VideoPlayer not available; live display disabled.');
        end
    end
end

function [rb, tb] = initBuffers(n)
    rb = struct('left', NaN(1,n), 'right', NaN(1,n));
    tb = struct('left', NaN(1,n), 'right', NaN(1,n));
end

function [slr, slt, srr, srt, rhoBuf, thetaBuf] = smoothParams(lr, lt, rr, rt, rhoBuf, thetaBuf)
    rhoBuf.left   = [lr,   rhoBuf.left(1:end-1)];
    thetaBuf.left = [lt,   thetaBuf.left(1:end-1)];
    rhoBuf.right  = [rr,   rhoBuf.right(1:end-1)];
    thetaBuf.right= [rt,   thetaBuf.right(1:end-1)];
    
    slr = median(rhoBuf.left,   'omitnan');
    slt = median(thetaBuf.left, 'omitnan');
    srr = median(rhoBuf.right,  'omitnan');
    srt = median(thetaBuf.right, 'omitnan');
    
    if isnan(slr); slr = lr; slt = lt; end
    if isnan(srr); srr = rr; srt = rt; end
end

function showAndSave(img, fr, player, writer, showLive, saveOut)
    if showLive && ~isempty(player)
        try
            step(player, img);
        catch
            imshow(img); title(sprintf('Frame %d',fr)); drawnow;
        end
    end
    if saveOut && ~isempty(writer)
        writeVideo(writer, img);
    end
    if mod(fr,100)==0
        fprintf('Frame %d processed\n',fr);
    end
end

function cleanUp(player, writer, saveOut, showLive, outFile, fr)
    if showLive && ~isempty(player)
        try; release(player); catch; end
    end
    if saveOut && ~isempty(writer)
        close(writer);
        fprintf('Output saved: %s\n', outFile);
    end
    fprintf('Done. %d frames processed.\n', fr);
end

% DRAW LANE FUNCTION
function overlay = drawLane(img, leftRho, leftTheta, rightRho, rightTheta, roiTopY, lineWidth)
    if nargin<7 || isempty(lineWidth); lineWidth = 3; end
    if nargin<6 || isempty(roiTopY); roiTopY = 1; end
    if size(img,3)==1; overlay = repmat(img,[1,1,3]); else; overlay = img; end

    rows = size(overlay,1); cols = size(overlay,2);
    roiTopY = max(1, min(rows, roiTopY));

    if ~isnan(leftRho) && ~isnan(leftTheta)
        overlay = drawOne(overlay, leftRho, leftTheta, [255,0,0], rows, cols, roiTopY, lineWidth);
    end
    if ~isnan(rightRho) && ~isnan(rightTheta)
        overlay = drawOne(overlay, rightRho, rightTheta, [0,255,0], rows, cols, roiTopY, lineWidth);
    end

    function out = drawOne(in, rho, theta, col, h, w, yStart, thick)
        rad = deg2rad(theta); s = sin(rad); c = cos(rad);
        y1 = round(yStart); x1 = (rho - y1*s)/c;
        y2 = h; x2 = (rho - y2*s)/c;
        x1 = max(1, min(w, round(x1))); y1 = max(1, min(h, round(y1)));
        x2 = max(1, min(w, round(x2))); y2 = max(1, min(h, round(y2)));
        pts = bresenham(x1,y1,x2,y2);
        half = floor(thick/2);
        out = in;
        for k = 1:size(pts,1)
            cx = pts(k,1); cy = pts(k,2);
            for dx = -half:half
                for dy = -half:half
                    if (dx^2+dy^2) <= (thick/2)^2
                        nx = cx+dx; ny = cy+dy;
                        if nx>=1 && nx<=w && ny>=1 && ny<=h
                            out(ny,nx,1)=col(1); out(ny,nx,2)=col(2); out(ny,nx,3)=col(3);
                        end
                    end
                end
            end
        end
    end

    function pts = bresenham(x1,y1,x2,y2)
        dx = abs(x2-x1); dy = abs(y2-y1);
        sx = sign(x2-x1); sy = sign(y2-y1);
        err = dx-dy;
        x=x1; y=y1; pts = [x,y];
        while ~(x==x2 && y==y2)
            e2 = 2*err;
            if e2 > -dy; err = err-dy; x = x+sx; end
            if e2 < dx;  err = err+dx; y = y+sy; end
            pts = [pts; x,y];
        end
    end
end