%-----------------------------------------------
%step 4 - our filtering pipeline
%-----------------------------------------------
 %Note: depending on you correction choice raw data is converted at
 %differnt times (i.e., raw > OD > Hb)
function [dconverted, dnormed]= fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords, t)
    %depends on Homer2 package
    warning off; %sometimes hmrIntensity2Conc gives a warning we don't care about here
    %see hmrMotionArtifact in Homer2 documentation for parameter description
    
    if contains(num2str(motionCorr),["1","3"])
        [tInc,tIncCh] = hmrMotionArtifactByChannel(d, samprate, SD, ones(length(d),1), 1, 1, 5, 2);
        if contains(num2str(motionCorr),"1")
            dfiltered = BaselineVolatilityCorrection(d, samprate, SD, tIncCh);
        end
        if contains(num2str(motionCorr),"3")
            [dfiltered,~,~] = hmrMotionCorrectPCA_Ch( SD, d, tInc, tIncCh, 0.9);
        end
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
    
    if contains(num2str(motionCorr),["2","5","6"])
        dod = hmrIntensity2OD( d );
        
        [repInf(:,1),repInf(:,2)]=find(isinf(dod)); %If an Inf value shows up
        if ~isempty(repInf)
            for r=1:height(repInf)
                if ~isinf(dod(repInf(r,1)-1,repInf(r,2)))
                    dod(repInf(r,1),repInf(r,2))=dod(repInf(r,1)-1,repInf(r,2));
                elseif ~isinf(dod(repInf(r,1)+1,repInf(r,2)))
                    dod(repInf(r,1),repInf(r,2))=dod(repInf(r,1)+1,repInf(r,2));
                end
            end
        end

        if contains(num2str(motionCorr),"2")
            if ~isempty(coords)
                dod = spatialPCFilter(dod, coords);
            end
        end
        if contains(num2str(motionCorr),"6") % Short-channel Regression
            [dod, ~] = hmrSSR(dod, SD, 0, t);
        end
        if contains(num2str(motionCorr),"5") % Wavelet 
            [dod] = hmrMotionCorrectWavelet(dod,SD,1.5);
        end
        dod = hmrBandpassFilt(dod,samprate,0.008,0.2);
        ppf = [6 6];
        dconverted = hmrOD2Conc( dod, SD, ppf );
    end
    
    if contains(num2str(motionCorr),["4","7"])
        dfiltered=d;
        %see hmrIntensity2Conc in Homer2 documentation for parameter description
        [dconverted, ~] = hmrIntensity2Conc(dfiltered, SD, samprate, 0.008, 0.2, [6, 6]);
    end
     
    if contains(num2str(motionCorr),"4")
        dconverted = hmrMotionCorrectCbsi(dconverted,SD);
    end
    
    dnormed = zscore(dconverted);
    warning on;
end