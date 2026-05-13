

function makeNoiseParams(fileName, meanValue, varianceValue, densityValue)
    % This function creates a noise parameters data structure as a .mat
    % object

    % Inputs:
    %   fileName - Name of the .mat file
    %   meanVal - Parameter mean value (e.g. 0.5, leave 0 for saltpepper or speckle noise)
    %   varianceValue - Parameter variance value (e.g. 0.01, leave 0 for saltpepper noise)
    %   densityValue - Parameter density value (e.g. 0.1, leave 0 for gaussian or speckle noise)

    % Output: a saved .mat file

    noiseParams.mean = meanValue;
    noiseParams.variance = varianceValue;
    noiseParams.density = densityValue;

    save(fileName, 'noiseParams');
end

% Usage Example: makeNoiseParams('noiseParams.mat', 0, 0.01, 0.1) %