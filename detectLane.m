function [leftRho, leftTheta, rightRho, rightTheta, ...
          leftXBottom, leftYBottom, leftXTop, leftYTop, ...
          rightXBottom, rightYBottom, rightXTop, rightYTop, ...
          smoothImg, maskedEdges, roiImg, roiTopY] = detectLane(inputImg)
%   Input:   inputImg - RGB or grayscale image.
%   Outputs: leftRho, leftTheta, rightRho, rightTheta - Hough parameters.
%            leftXBottom, leftYBottom, leftXTop, leftYTop - left lane endpoints.
%            rightXBottom, rightYBottom, rightXTop, rightYTop - right lane endpoints.
%            smoothImg, maskedEdges, roiImg, roiTopY - debugging outputs.

    grayImg = convertToGray(inputImg);
    [origH, origW] = size(grayImg);

    [smoothImg, edgeImg] = preprocessImage(grayImg);
    [roiMask, roiTopY] = createRoiMask(size(grayImg));
    maskedEdges = edgeImg .* roiMask;
    roiImg = grayImg .* uint8(roiMask);

    [rhoCandidates, thetaCandidates] = findLineCandidates(maskedEdges);
    if isempty(rhoCandidates)
        % return NaNs for all outputs
        leftRho = NaN; leftTheta = NaN; rightRho = NaN; rightTheta = NaN;
        leftXBottom = NaN; leftYBottom = NaN; leftXTop = NaN; leftYTop = NaN;
        rightXBottom = NaN; rightYBottom = NaN; rightXTop = NaN; rightYTop = NaN;
        return;
    end
    
  

    [leftRho, leftTheta, rightRho, rightTheta] = selectLaneLines(...
        rhoCandidates, thetaCandidates, roiTopY);

    % scale (no resizing used, but keep for generality)
    scale = origW / size(grayImg,2);
    leftRho = leftRho * scale;
    rightRho = rightRho * scale;

    % compute endpoints at bottom (y = image height) and ROI top (y = roiTopY)
    h = size(grayImg,1);
    yBottom = h;
    yTop = max(1, min(h, roiTopY));

    % computeX function defined below
    leftXBottom = computeX(leftRho, leftTheta, yBottom);
    leftYBottom = yBottom;
    leftXTop    = computeX(leftRho, leftTheta, yTop);
    leftYTop    = yTop;

    rightXBottom = computeX(rightRho, rightTheta, yBottom);
    rightYBottom = yBottom;
    rightXTop    = computeX(rightRho, rightTheta, yTop);
    rightYTop    = yTop;

    % --------------------------------------------------------------
    % Nested helper functions
    % --------------------------------------------------------------
    function x = computeX(rho, theta, y)
        % compute x coordinate of a line (rho, theta) at given y row
        if isnan(rho) || isnan(theta)
            x = NaN;
            return;
        end
        thetaRad = deg2rad(theta);
        x = (rho - y * sin(thetaRad)) / cos(thetaRad);
    end

    function gray = convertToGray(img)
        if size(img,3)==3, gray = rgb2gray(img); else, gray = img; end
    end

    function [smoothed, edges] = preprocessImage(img)
        smoothed = imgaussfilt(img, 0.8);
        edges = edge(smoothed, 'canny', [0.2, 0.6]);
        %        edges = edge(smoothed, 'canny', [0.2, 0.6]);

    end

    function [mask, topY] = createRoiMask(imgSize)
    h = imgSize(1); w = imgSize(2);
    topY = round(0.55 * h);   % keep vertical height unchanged
    
    % bottomLeftX  = w * 0.3;   % 
    % bottomRightX = w * 0.7;   
    % topLeftX     = w * 0.35;  %
    % topRightX    = w * 0.65;
    %For Urban
    bottomLeftX  = w * 0.2;   % 
    bottomRightX = w * 0.8;   
    topLeftX     = w * 0.4;  %
    topRightX    = w * 0.6;  
    pts = [bottomLeftX, h; bottomRightX, h; topRightX, topY; topLeftX, topY];
    mask = poly2mask(pts(:,1), pts(:,2), h, w);
    end

    function [rhoVals, thetaVals] = findLineCandidates(edgeMask)
        thetaRange = -78:78;
        [H, theta, rho] = hough(edgeMask, 'Theta', thetaRange);
        peaks = houghpeaks(H, 10, 'Threshold', ceil(0.3*max(H(:))));
        if isempty(peaks)
            rhoVals = []; thetaVals = []; return;
        end
        np = size(peaks,1);
        rhoVals = zeros(np,1); thetaVals = zeros(np,1);
        for i=1:np
            rhoVals(i) = rho(peaks(i,1));
            thetaVals(i) = theta(peaks(i,2));
        end
    end

    function [lRho, lTheta, rRho, rTheta] = selectLaneLines(rhoAll, thetaAll, topY)
    % Left lane: average ALL candidates with theta < 0
        lMask = thetaAll < 0;
        if any(lMask)
            lRho = mean(rhoAll(lMask));
            lTheta = mean(thetaAll(lMask));
        else
            lRho = NaN; lTheta = NaN;
        end

        % Right lane: average ALL candidates with theta > 0
        rMask = thetaAll > 0;
        if any(rMask)
            rRho = mean(rhoAll(rMask));
            rTheta = mean(thetaAll(rMask));
        else
            rRho = NaN; rTheta = NaN;
        end
       
    end
end % detectLane