function [lor] = calcLOR(X12, X22, Th, Xm)
% This function calculates the Lateral Ofset Ratio
% X12 == > The point of intersection of the left line with the x-axis
% X22 == > The point of intersection of the right line with the x-axis
% Th  == > Threshold of the departure
% Xm  == > Center of the image in the x-axis
% lor == > Lateral Ofset Ratio

lor = (min(abs(X12-Xm), abs(X22-Xm)) - Th * Xm) / (Th * Xm);

end

