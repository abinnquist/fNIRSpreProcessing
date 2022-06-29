function preprocessingNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)
rawdir=uigetdir('','Choose Data Directory');

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

if hyperscan
    if multiscan
        preprocessHyperMulti(dataprefix, currdir, rawdir, motionCorr, numaux);
    else
        preprocessHyperSingle(dataprefix, currdir, rawdir, motionCorr, numaux);
    end
else
    if multiscan
        preprocessSoloMulti(dataprefix, currdir, rawdir, motionCorr, numaux);
    else
        preprocessSoloSingle(dataprefix, currdir, rawdir, motionCorr, numaux);
    end
end
