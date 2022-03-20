%-----------------------------------------------
%step 4 - our filtering pipeline
%-----------------------------------------------
 
function [dconverted, dnormed]= fNIRSFilterPipeline(d, SD, samprate, motionCorr)
    %depends on Homer2 package
    warning off; %sometimes hmrIntensity2Conc gives a warning we don't care about here
    %see hmrMotionArtifact in Homer2 documentation for parameter description
    [tInc,tIncCh] = hmrMotionArtifactByChannel(d, samprate, SD, ones(length(d),1), 0.5, 0.5, 5, 2);
    
    if any(or(motionCorr==1,motionCorr==3))
        %4/21/2020
        dfiltered = BaselineVolatilityCorrection(d, samprate, SD, tIncCh);
    end
    
    if motionCorr==2
        [dfiltered,~,~] = hmrMotionCorrectPCA_Ch(SD, d, tInc, tIncCh, .8);
    end
    
    if any(or(motionCorr==0,motionCorr==4))
        dfiltered=d;
    end
    %see hmrIntensity2Conc in Homer2 documentation for parameter description
    [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    
    if any(or(motionCorr==3,motionCorr==4))
        dconverted = hmrMotionCorrectCbsi(dconverted,SD);
    end
    
    dnormed = zscore(dconverted);
    warning on;
end