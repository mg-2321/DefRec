%function [ result ] = calConInterval( input, topN )
function [ result ] = calConInterval( input)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%topw = 50;
%topw = min(50, length(input));
%topw = min(topN, length(input));
%temp = sort(input, 'descend'); % from max to min

%input2 = temp([1: topw]);
%input2 = input;

inputmean = mean(input);
inputstd = std(input);

z95 = 1.96;
z99 = 2.57;

result.meanA = inputmean;
result.stdA = inputstd;
result.ci95A = z95 * inputstd / (sqrt(length(input)));
result.ci99A = z99 * inputstd / (sqrt(length(input)));
result.maxA = max(input);
result.len = length(input);

%{
inputmean = mean(input2);
inputstd = std(input2);


result.mean50 = inputmean;
result.std50 = inputstd;
result.ci9550 = z95 * inputstd / (sqrt(length(input2)));
result.ci9950 = z99 * inputstd / (sqrt(length(input2)));
%}

end

