%-----------------------------------------------
%step 1 - subfunctions for extracting data
%-----------------------------------------------

function [d, samprate, s, SD, aux, t] = extractTechEnData(subjfolder)
    nirsfile = dir(strcat(subjfolder,'/*.nirs'));
    load(strcat(subjfolder,'/',nirsfile(1).name),'-mat');
    samprate = 1/mean(diff(t(:)));
end