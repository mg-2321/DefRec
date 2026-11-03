clear; clc; close all;


%dirname = '/home/hugo/experiment/PowerSDN/Spoof/';
%cases = {'case24', 'case30', 'caseRTS96i'};
%cases = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop-1','case2737sop-3'};
cases = {'case2737sop-3'};
%xticknames = {'IEEE\n24bus', 'IEEE\n30bus', 'IEEE\nRTS96', 'Poland 2737bus\narea 1', 'Poland 2737bus\narea 2', 'Poland 2737bus\narea 3'};
%xticknames = {'IEEE\\24bus', 'IEEE\\30bus', 'IEEE RTS96', 'Poland 2737bus area 1', 'Poland 2737bus area 2', 'Poland 2737bus area 3'};
%analysis = 'pf';
analysis = 'accuracy';

for loop1 = 1 : length(cases)
    
    resultfile = sprintf('../%s-%s.mat', cases{loop1}, analysis);
    curhandle = load(resultfile);

    ratio = abs(curhandle.rz ./ curhandle.rz1);
    %ratio = abs(curhandle.rz([1:97], :) ./ curhandle.rz1);
    result = calConInterval(ratio(:));

    fprintf('%s se accuracy: %d %.6f %.6f %.6f %.6f \n', cases{loop1}, result.len, result.meanA, result.stdA, result.ci95A, result.ci99A);

    result = calConInterval(curhandle.latency);
    fprintf('%s se latency: %d %.6f %.6f %.6f %.6f \n', cases{loop1}, result.len, result.meanA, result.stdA, result.ci95A, result.ci99A);

end
