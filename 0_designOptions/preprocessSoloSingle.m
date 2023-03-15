function preprocessSoloSingle(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes, compInfo)

fprintf('\n\t Preprocessing ...\n')
reverseStr = '';
Elapsedtime = tic;

for i=1:length(currdir)
    subjname=currdir(i).name;
    
    msg = sprintf('\n\t subj %d/%d ...',i,length(currdir));
    fprintf([reverseStr,msg]);
    reverseStr = repmat(sprintf('\b'),1,length(msg));   
    
    subjfolder = strcat(rawdir,filesep,subjname);
    outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,subjname);

    if ~exist(outpath,'dir')

    scdir=dir(subjfolder);
    scdir=scdir(~startsWith({scdir.name},'.'));
    if ~isempty(scdir)

    %1) extract data values
        pp=dir(strcat(subjfolder,filesep,'*_probeInfo.mat'));
        if isempty(pp) && device==1
            error('ERROR: Scan  does not contain a probeInfo object');
        elseif isempty(pp) && device~=1
            coords=[];
        elseif ~isempty(pp) 
            load(fullfile(pp.folder,filesep,pp.name));
            coords=probeInfo.probes.coords_c3;
        end

        if device==1
            [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(subjfolder);
            probenumchannels = probeInfo.probes.nChannel0;
            datanumchannels = size(d,2)/2;
            if probenumchannels~=datanumchannels
                error('ERROR: number of data channels in hdr file does not match number of channels in probeInfo file.');
            end
            [SD, aux, t] = getMiscNirsVars(d, sd_ind, samprate, wavelengths, probeInfo);
        elseif device==2
            [d, samprate, s, SD, aux, t] = extractTechEnData(subjfolder);
        elseif device==3
            [d, samprate, t, SD, aux, trigInfo] = snirfExtract(subjfolder,numaux);
            s = zeros(length(d),1);
            if ~isempty(trigInfo)
                onset = trigInfo.Onset;
                s(find(t==onset(1)),1) = 1;
            end
        end
        if SD.SrcPos==0
            load(strcat(rawdir,filesep,'SD_fix.mat'))
            digfile = strcat(rawdir,filesep,'digpts.txt');
            mni_ch_table = getMNIcoords(digfile, SD);
        else
            digfile = strcat(subjfolder,filesep,'digpts.txt');
            if device>=2 && exist(digfile,'file')
                mni_ch_table = getMNIcoords(digfile, SD);
            end
        end

        % 2) Trim scans
        sInfo(1,1)=i; sInfo(2,1)=1; sInfo(3,1)=1; sInfo(4,1)=length(subjdir);
        [d,s,t,aux] = trimData(trim, d, s, t, trimTimes, samprate, numaux, aux, numaux, sInfo);

        %3) identify noisy channels
        satlength = 2; %in seconds
        QCoDthresh = 0.6 - 0.03*samprate;
        [d, channelmask] = removeBadChannels(d, samprate, satlength, QCoDthresh);

        SD.MeasListAct = [channelmask'; channelmask'];
        SD.MeasListVis = SD.MeasListAct;
        
        %4) motion filter, convert to hemodynamic changes
        [dconverted, dnormed] = fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords, t);

        %5) final data quality assessment, remove uncertain channels
        % default is to use Pearson's correlation to check how impactful
        % remaining spikes are - can change to "ps" as well if you're
        % using phase synchrony in your analyses instead
        % default QA threshold is 0.1 - amount of measurement error
        % to be allowed in data (out of 1)
        % right now quality assessment is only run on the oxy values
        %TO DO?: in future implementation with GUI, ask usr which signal
        %they plan on analyzing (z scored or no, chromophore)
        qamethod = 'corr';
        thresh = 0.1;
        qamask = qualityAssessment(dconverted(:,1,:),samprate,qamethod,thresh);
        z_qamask = qualityAssessment(dnormed(:,1,:),samprate,qamethod,thresh);

        %6) Output results
        mkdir(outpath)
            
        totalmask = channelmask;
        totalmask(~qamask) = 0;
        z_totalmask = channelmask;
        z_totalmask(~z_qamask) = 0;

        numchannels = size(dconverted,3);
        oxy = zeros(size(dconverted,1), numchannels);
        deoxy = zeros(size(dconverted,1), numchannels);
        totaloxy = zeros(size(dconverted,1), numchannels);
        z_oxy = zeros(size(dnormed,1), numchannels);
        z_deoxy = zeros(size(dnormed,1), numchannels);
        z_totaloxy = zeros(size(dnormed,1), numchannels);
        new_d = zeros(size(dconverted,1), numchannels*2);
        for c = 1:numchannels
            oxy(:,c) = dconverted(:,1,c);
            deoxy(:,c) = dconverted(:,2,c);
            totaloxy(:,c) = dconverted(:,3,c);
            z_oxy(:,c) = dnormed(:,1,c);
            z_deoxy(:,c) = dnormed(:,2,c);
            z_totaloxy(:,c) = dnormed(:,3,c);
            new_d(:,(c*2)-1) = oxy(:,c);
            new_d(:,c*2) = deoxy(:,c);
        end
        save(strcat(outpath,filesep,subjname,'_preprocessed.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');

        oxy(:,~channelmask) = NaN;
        deoxy(:,~channelmask) = NaN;
        totaloxy(:,~channelmask) = NaN;
        z_oxy(:,~channelmask) = NaN;
        z_deoxy(:,~channelmask) = NaN;
        z_totaloxy(:,~channelmask) = NaN;
        save(strcat(outpath,filesep,subjname,'_preprocessed_nonoisych.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');

        oxy(:,~totalmask) = NaN;
        deoxy(:,~totalmask) = NaN;
        totaloxy(:,~totalmask) = NaN;
        z_oxy(:,~z_totalmask) = NaN;
        z_deoxy(:,~z_totalmask) = NaN;
        z_totaloxy(:,~z_totalmask) = NaN;
        save(strcat(outpath,filesep,subjname,'_preprocessed_nouncertainch.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
        if exist('mni_ch_table','var')
            writetable(mni_ch_table,strcat(outpath,filesep,'channel_mnicoords.csv'),'Delimiter',',');
        end
    else
        % Output: empty
        mkdir(outpath)
    end
    end
end

preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
if compInfo{1,1}=='1' || compInfo{3,1}=='1'
    IDlength=str2num(compInfo{2,1});
    %Gets the scan names for all subjects
    [~, ~, snames] = countScans(currdir, dataprefix, 0, 1, IDlength);   

    %6.1) Quality Check
    if compInfo{1,1}=='1'
        qualityReport(dataprefix,0,0,numchannels,preprocdir,snames);
    end

    %6.2) Compile data into one .mat file
    if compInfo{3,1}=='1'
        zdim=str2num(compInfo{5,1});
        ch_reject=str2num(compInfo{6,1});
        [deoxy3D,oxy3D]= compileNIRSdata(preprocdir,dataprefix,0,ch_reject,1,zdim,snames);
    
        save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
    end
end
    
Elapsedtime = toc(Elapsedtime);
fprintf('\n\t Elapsed time: %g seconds\n', Elapsedtime);
end