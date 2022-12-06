%-----------------------------------------------
%step 4 - our filtering pipeline
%-----------------------------------------------
 %Note: depending on you correction choice raw data is converted at
 %differnt times (i.e., raw > OD > Hb)
function [dconverted, dnormed]= fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords, t)
    %depends on Homer2 package
    warning off; %sometimes hmrIntensity2Conc gives a warning we don't care about here
    %see hmrMotionArtifact in Homer2 documentation for parameter description
    
    if any(or(motionCorr==1,motionCorr==3))
        [tInc,tIncCh] = hmrMotionArtifactByChannel(d, samprate, SD, ones(length(d),1), 1, 1, 5, 2);
        if motionCorr==1
            dfiltered = BaselineVolatilityCorrection(d, samprate, SD, tIncCh);
        else
            [dfiltered,~,~] = hmrMotionCorrectPCA_Ch( SD, d, tInc, tIncCh, 0.9);
        end
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
    
    if motionCorr==2 || motionCorr==5 || motionCorr==6
        dod = hmrIntensity2OD( d );
        if motionCorr==2
            if ~isempty(coords)
                dod = spatialPCFilter(dod, coords);
            end
        elseif motionCorr==5
            [dod] = hmrMotionCorrectWavelet(dod,SD,1.5);
        elseif motionCorr==6 %In progress
            [dod, ~] = hmrSSR(dod, SD, 0, t);
        end
        dod = hmrBandpassFilt(dod,samprate,0.008,0.2);
        ppf = [6 6];
        dconverted = hmrOD2Conc( dod, SD, ppf );
    end
    
    if any(or(motionCorr==4,motionCorr==7))
        dfiltered=d;
        %see hmrIntensity2Conc in Homer2 documentation for parameter description
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
     
    if motionCorr==4
        dconverted = hmrMotionCorrectCbsi(dconverted,SD);
    end
    
    dnormed = zscore(dconverted);
    warning on;
end