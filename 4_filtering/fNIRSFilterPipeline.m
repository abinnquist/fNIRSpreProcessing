%-----------------------------------------------
%step 4 - our filtering pipeline
%-----------------------------------------------
 
function [dconverted, dnormed]= fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords)
    %depends on Homer2 package
    warning off; %sometimes hmrIntensity2Conc gives a warning we don't care about here
    %see hmrMotionArtifact in Homer2 documentation for parameter description
    
    if any(or(motionCorr==1,motionCorr==3))
        [tInc,tIncCh] = hmrMotionArtifactByChannel(d, samprate, SD, ones(length(d),1), 1, 1, 5, 2);
        dfiltered = BaselineVolatilityCorrection(d, samprate, SD, tIncCh);
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
    
    if motionCorr==2
        dod = hmrIntensity2OD( d );
        if ~isempty(coords)
            dod = spatialPCFilter(dod, coords);
        end
        dod = hmrBandpassFilt(dod,samprate,0.008,0.2);
        ppf = [6 6];
        if length(ppf)~=length(SD.Lambda)
            disp( sprintf('Warning: ppf must be a vector with the same number of elements as SD.Lambda\n    Using default values of [6 6]') );
            ppf = [6 6];
        end
        dconverted = hmrOD2Conc( dod, SD, ppf );
    end
    
    if any(or(motionCorr==0,motionCorr==4))
        dfiltered=d;
        %see hmrIntensity2Conc in Homer2 documentation for parameter description
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
     
    if any(or(motionCorr==3,motionCorr==4))
        dconverted = hmrMotionCorrectCbsi(dconverted,SD);
    end
    
    dnormed = zscore(dconverted);
    warning on;
end