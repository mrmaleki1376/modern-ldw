function [leftRho, leftTheta, rightRho, rightTheta, ...
          leftXBottom, leftYBottom, leftXTop, leftYTop, ...
          rightXBottom, rightYBottom, rightXTop, rightYTop, ...
          smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(inputImg)
%   Input:   inputImg - RGB or grayscale image.
%   Outputs: leftRho, leftTheta, rightRho, rightTheta - Hough parameters.
%            leftXBottom, leftYBottom, leftXTop, leftYTop - left lane endpoints.
%            rightXBottom, rightYBottom, rightXTop, rightYTop - right lane endpoints.
%            smoothImg, maskedEdges, roiImg, roiTopY - debugging outputs.

    % Persistent memory to store the previous smoothed line parameters
    persistent smoothLRho smoothLTheta smoothRRho smoothRTheta

    grayImg = convertToGray(inputImg);
    [origH, origW] = size(grayImg);

    [smoothImg, edgeImg] = preprocessImage(grayImg);
    [roiMask, roiTopY] = createRoiMask(size(grayImg));
    maskedEdges = edgeImg .* roiMask;
    roiImg = grayImg .* uint8(roiMask);

    [rhoCandidates, thetaCandidates] = findLineCandidates(maskedEdges);
    if isempty(rhoCandidates)
        % If everything is lost, output NaNs but preserve history
        leftRho = NaN; leftTheta = NaN; rightRho = NaN; rightTheta = NaN;
        leftXBottom = NaN; leftYBottom = NaN; leftXTop = NaN; leftYTop = NaN;
        rightXBottom = NaN; rightYBottom = NaN; rightXTop = NaN; rightYTop = NaN;
        return;
    end

    % Get raw calculations for this frame using your simple split
    [rawLRho, rawLTheta, rawRRho, rawRTheta] = selectLaneLines(rhoCandidates, thetaCandidates);

    % --- SIMPLIFIED SMOOTHING (Moving Average Filter) ---
    alpha = 0.20; % Control responsiveness. Lower = smoother; Higher = faster reaction.

    % Smooth Left Lane
    if ~isnan(rawLRho)
        if isempty(smoothLRho), smoothLRho = rawLRho; smoothLTheta = rawLTheta; end % Initialize
        smoothLRho   = (alpha * rawLRho)   + ((1 - alpha) * smoothLRho);
        smoothLTheta = (alpha * rawLTheta) + ((1 - alpha) * smoothLTheta);
    end

    % Smooth Right Lane
    if ~isnan(rawRRho)
        if isempty(smoothRRho), smoothRRho = rawRRho; smoothRTheta = rawRTheta; end % Initialize
        smoothRRho   = (alpha * rawRRho)   + ((1 - alpha) * smoothRRho);
        smoothRTheta = (alpha * rawRTheta) + ((1 - alpha) * smoothRTheta);
    end

    % Assign filtered outputs
    leftRho = smoothLRho;   leftTheta = smoothLTheta;
    rightRho = smoothRRho; rightTheta = smoothRTheta;
    % -----------------------------------------------------

    % scale (no resizing used, but keep for generality)
    scale = origW / size(grayImg,2);
    leftRho = leftRho * scale;
    rightRho = rightRho * scale;

    % compute endpoints at bottom (y = image height) and ROI top (y = roiTopY)
    h = size(grayImg,1);
    yBottom = h;
    yTop = max(1, min(h, roiTopY));

    % % Check for line intersection to prevent the crossover effect
    % [~, yIntersect] = findIntersection(leftRho, leftTheta, rightRho, rightTheta);
    % 
    % % If the lines cross below the original yTop but above the bottom,
    % % truncate them right before they touch.
    % if ~isnan(yIntersect) && (yIntersect > yTop) && (yIntersect < yBottom)
    %     yTop = ceil(yIntersect) + 2; % 2-pixel gap buffer
    % end

    leftXBottom = computeX(leftRho, leftTheta, yBottom);
    leftYBottom = yBottom;
    leftXTop    = computeX(leftRho, leftTheta, yTop);
    leftYTop    = yTop;

    rightXBottom = computeX(rightRho, rightTheta, yBottom);
    rightYBottom = yBottom;
    rightXTop    = computeX(rightRho, rightTheta, yTop);
    rightYTop    = yTop;

end % detectLane

% -------------------------------------------------------------------------
% Local helper functions
% -------------------------------------------------------------------------

function [lRho, lTheta, rRho, rTheta] = selectLaneLines(rhoAll, thetaAll)
    % Keep it simple: median split based entirely on left/right angle
    lMask = thetaAll < 0;
    if any(lMask)
        lRho = median(rhoAll(lMask));
        lTheta = median(thetaAll(lMask));
    else
        lRho = NaN; lTheta = NaN;
    end

    rMask = thetaAll > 0;
    if any(rMask)
        rRho = median(rhoAll(rMask));
        rTheta = median(thetaAll(rMask));
    else
        rRho = NaN; rTheta = NaN;
    end
end

% function [xInt, yInt] = findIntersection(rho1, theta1, rho2, theta2)
%     if isnan(rho1) || isnan(rho2) || isnan(theta1) || isnan(theta2)
%         xInt = NaN; yInt = NaN;
%         return;
%     end
%     t1 = deg2rad(theta1);
%     t2 = deg2rad(theta2);
%     det = sin(t1) * cos(t2) - cos(t1) * sin(t2);
%     if abs(det) < 1e-5 
%         xInt = NaN; yInt = NaN;
%     else
%         yInt = (rho1 * cos(t2) - rho2 * cos(t1)) / det;
%         xInt = (rho1 - yInt * sin(t1)) / cos(t1);
%     end
% end

function x = computeX(rho, theta, y)
    if isnan(rho) || isnan(theta)
        x = NaN;
        return;
    end
    thetaRad = deg2rad(theta);
    x = (rho - y * sin(thetaRad)) / cos(thetaRad);
end

function gray = convertToGray(img)
    if size(img,3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end
end

function [smoothed, edges] = preprocessImage(img)
    smoothed = imgaussfilt(img, 2);
    edges = edge(smoothed, 'canny', [0.2, 0.6]);
end

function [mask, topY] = createRoiMask(imgSize)
    h = imgSize(1); w = imgSize(2);
    topY = round(0.45 * h);   
    bottomLeftX  = w * 0.3;  bottomRightX = w * 0.7;
    topLeftX     = w * 0.45; topRightX    = w * 0.55;
    pts = [bottomLeftX, h; bottomRightX, h; topRightX, topY; topLeftX, topY];
    mask = poly2mask(pts(:,1), pts(:,2), h, w);
end

function [rhoVals, thetaVals] = findLineCandidates(edgeMask)
    thetaRange = -78:78;
    [H, theta, rho] = hough(edgeMask, 'Theta', thetaRange);
    peaks = houghpeaks(H, 10, 'Threshold', ceil(0.2 * max(H(:))));
    if isempty(peaks)
        rhoVals = []; thetaVals = [];
        return;
    end
    np = size(peaks, 1);
    rhoVals = zeros(np, 1);
    thetaVals = zeros(np, 1);
    for i = 1:np
        rhoVals(i) = rho(peaks(i, 1));
        thetaVals(i) = theta(peaks(i, 2));
    end
end