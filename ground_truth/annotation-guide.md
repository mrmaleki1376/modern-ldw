# Ground Truth Annotation Guide
There are several data structures for composing ground truth data. While JSON is a great universal format, using MATLAB's built-in labeling tool seems better for this project requirements. The native supported object notation is the `.mat` format that can be created using **MATLAB Ground Truth Labeler App**. Here is an step-by-step instruction.

1. Open the `MATLAB Ground Truth Labeler` app from the `Apps` tab and the `Automotive` section.
2. Click on `Import` -> `Add Signals`.
3. Load the video file and use `Add Source` button to create the signal.
4. Define a new ROI Label, set its Type to `Line`, and name it `laneBoundary`.
5. For each frame, click to place points along the lines. The `Line` type creates a connected polyline automatically.
6. After annotating all the frames, export the labels by clicking `Export` -> `To File`. The app will save a `.mat` file containing a `gTruth` object with all annptations.

## Usage Example

```matlab
% Load the ground truth data
groundTruthData = load('highwayDashedLeftLine.mat');

% Extract the lane points for evaluation
groundTruthObject = groundTruthData.gTruth;
lanePoints = groundTruthObject.ROILabelData.LaneBoundary{frameIndex};

% The output will be a cell containg data points.
```