function preprocessHyperMulti(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes)

fprintf('\n\t Preprocessing ...\n')
reverseStr = '';
Elapsedtime = tic;

compInfo = inputdlg({'Compile  data? (0=no, 1=yes)','Number of Scans (1-n)',...
    'Compile Z-score? (0=no, 1=yes)','Which channel rejection? (1=none, 2=noisy, or 3=noisy and uncertain)'},...
              'Compile data info', [1 35]); 

for i=1:length(currdir)
    group=currdir(i).name;  
    groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));

    for j=1:length(groupdir)
        subjname = groupdir(j).name;
        subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
        scannames = {};

        for k=1:length(subjdir)
            scanname = subjdir(k).name;
            scannames = [scannames,scanname];

            msg = sprintf('\n\t group %d/%d, subj %d/%d, scan %d/%d ...',i,length(currdir),...
                j,length(groupdir),k,length(subjdir));
            fprintf([reverseStr,msg]);
            reverseStr = repmat(sprintf('\b'),1,length(msg)); 

            scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);
            outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,group,filesep,subjname,filesep,scanname);

            if ~exist(outpath,'dir')

            %1) extract data values
            pp=dir(strcat(scanfolder,filesep,'*_probeInfo.mat'));
            if isempty(pp) && device==1
                error('ERROR: Scan  does not contain a probeInfo object');
            elseif isempty(pp) && device~=1
                coords=[];
            elseif ~isempty(pp) 
                load(fullfile(pp.folder,filesep,pp.name));
                coords=probeInfo.probes.coords_c3;
            end

            if device==1
                [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
                probenumchannels = probeInfo.probes.nChannel0;
                datanumchannels = size(d,2)/2;
                if probenumchannels~=datanumchannels
                    error('ERROR: number of data channels in hdr file does not match number of channels in probeInfo file.');
                end
                [SD, aux, t] = getMiscNirsVars(d, sd_ind, samprate, wavelengths, probeInfo);
            elseif device==2
                [d, samprate, s, SD, aux, t] = extractTechEnData(scanfolder);
            elseif device==3
                [d, samprate, t, SD, aux, trigInfo] = snirfExtract(scanfolder,numaux);
                s = zeros(length(d),1);
                onset = trigInfo.Onset;
                s(find(t==onset(1)),1) = 1;
            end

            if SD.SrcPos==0
                load(strcat(rawdir,filesep,'SD_fix.mat'))
                digfile = strcat(rawdir,filesep,'digpts.txt');
                mni_ch_table = getMNIcoords(digfile, SD);
            else
                digfile = strcat(scanfolder,filesep,'digpts.txt');
                if device>=2 && exist(digfile,'file')
                    mni_ch_table = getMNIcoords(digfile, SD);
                end
            end

            % 2) Trim scans: no=0, trim beginnin=1, trim begin & end=2
            scanNum=k; subj=i; numScans=length(subjdir);
            [d,s,t,aux] = trimData(trim, d, s, t, subj, scanNum, numScans, trimTimes, samprate, device, aux);
            
            %3) identify noisy channels (SNR channel rejection)
            satlength = 2; %in seconds
            QCoDthresh = 0.6 - 0.03*samprate; % >0.6 more stringency
            [d, channelmask] = removeBadChannels(d, samprate, satlength, QCoDthresh);
            
            SD.MeasListAct = [channelmask'; channelmask'];
            SD.MeasListVis = SD.MeasListAct;

            %4) motion filter, convert to hemodynamic changes
            [dconverted, dnormed] = fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords);

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
            qamask = qualityAssessment(squeeze(dconverted(:,1,:)),samprate,qamethod,thresh);
            z_qamask = qualityAssessment(squeeze(dnormed(:,1,:)),samprate,qamethod,thresh);
            
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
            save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            
            oxy(:,~channelmask) = NaN;
            deoxy(:,~channelmask) = NaN;
            totaloxy(:,~channelmask) = NaN;
            z_oxy(:,~channelmask) = NaN;
            z_deoxy(:,~channelmask) = NaN;
            z_totaloxy(:,~channelmask) = NaN;
            save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed_nonoisych.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            
            oxy(:,~totalmask) = NaN;
            deoxy(:,~totalmask) = NaN;
            totaloxy(:,~totalmask) = NaN;
            z_oxy(:,~z_totalmask) = NaN;
            z_deoxy(:,~z_totalmask) = NaN;
            z_totaloxy(:,~z_totalmask) = NaN;
            save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed_nouncertainch.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            if exist('mni_ch_table','var')
                writetable(mni_ch_table,strcat(outpath,filesep,'channel_mnicoords.csv'),'Delimiter',',');
            end
            end
        end
    end
end

preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
qualityReport(dataprefix,1,1,scannames,numchannels,preprocdir);

%6) Compile data into one .mat file
if compInfo{1,1}=='1'
    numScans=str2num(compInfo{2,1});
    zdim=str2num(compInfo{3,1});
    ch_reject=str2num(compInfo{4,1});
    [deoxy3D,oxy3D]= compiledyadicNIRSdata(preprocdir,dataprefix,ch_reject,numScans,zdim);

    save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
end
    
Elapsedtime = toc(Elapsedtime);
fprintf('\n\t Elapsed time: %g seconds\n', Elapsedtime);

end