function preprocessHyperSingle(dataprefix, currdir, rawdir, motionCorr, numaux)

fprintf('\n\t Preprocessing ...\n')
reverseStr = '';
Elapsedtime = tic;

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

trimQ = 'Would you like to use a csv to trim scans? If yes input 1 and if no input 0.\n';
trim = input(trimQ);

if trim==1
    [trimTs, trimPath] = uigetfile('*.csv','Choose trim time CSV');
    trimTimes = strcat(trimPath,trimTs);
    trimTimes = readtable(trimTimes);
    clear trimPath trimTs
end

for i=1:length(currdir)
    group=currdir(i).name; 
    groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));

    for j=1:length(groupdir)
        subjname = groupdir(j).name;
        msg = sprintf('\n\t group %d/%d, subj %d/%d...',i,length(currdir),j,length(groupdir));
        fprintf([reverseStr,msg]);
        reverseStr = repmat(sprintf('\b'),1,length(msg)); 
        subjfolder = strcat(rawdir,filesep,group,filesep,subjname);
        outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,group,filesep,subjname);

        if ~exist(outpath,'dir')

        %1) extract data values
            pp=dir(strcat(subjfolder,filesep,'*_probeInfo.mat'));
            load(fullfile(pp.folder,filesep,pp.name));
            if ~exist('probeInfo','var') && device==1
                error('ERROR: Scan  does not contain a probeInfo object');
            elseif ~exist('probeInfo','var') && device~=1
                coords=[];
            else
                coords=probeInfo.probes.coords_c3;
            end
            
            if device==1
                [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(subjfolder);
                probenumchannels = probeInfo.probes.nChannel0;
                datanumchannels = size(d,2)/2;
                if probenumchannels~=datanumchannels
                    error('ERROR: number of data channels in hdr file does not match number of channels in probeInfo file.');
                end
            elseif device==2
                [d, samprate, s, SD, aux, t] = extractTechEnData(subjfolder);
            elseif device==3
                [d, samprate, t, SD, aux, trigInfo] = snirfExtract(subjfolder,numaux);
                s = zeros(length(d),1);
                onset = trigInfo.Onset;
                s(find(t==onset(1)),1) = 1;
            end
            digfile = strcat(subjfolder,filesep,'digpts.txt');
            if device>=2 && exist(digfile,'file')
                mni_ch_table = getMNIcoords(digfile, SD);
            end

            %2) Trim beginning of data to 10s before onset, if there is
            %a lot of dead time before that  
            if trim==0
                % 2a) Trim beginning of data based on first trigger
                ssum = sum(s,2);
                stimmarks = find(ssum);
                if length(stimmarks)>=1
                    begintime = stimmarks(1);
                    if begintime>0
                        d = d(begintime:end,:);
                        s = s(begintime:end,:);
                        t = t(begintime:end,:);
                        if device==3
                            auxbegin = round(aux.samprate*begintime/samprate);
                            aux.data = aux.data(auxbegin:end,:,:);
                            aux.time = aux.time(auxbegin:end,:,:);
                        end
                        stimmarks = stimmarks-begintime;
                    end
                end
            else
                % 2b) Trim nirs scan according to a specified begin
                    % and end point. Best used for conversational data.
                stimmarks=0;
                begintime=round(table2array(trimTimes(i,2))*samprate);
                endScan=begintime + round(table2array(trimTimes(i,3))*samprate);

                d = d(begintime:endScan,:);
                s = s(begintime:endScan,:);
                t = t(begintime:endScan,:);
                if device == 3
                    if begintime>0
                        auxbegin = round(aux.samprate*begintime/samprate);
                        auxend = round(aux.samprate*endScan/samprate);
                        aux.data = aux.data(auxbegin:auxend,:,:);
                        aux.time = aux.time(auxbegin:auxend,:,:);
                    end
                end
            end

            %3) identify noisy channels
            satlength = 2; %in seconds
            QCoDthresh = 0.6 - 0.03*samprate;
            [d, channelmask] = removeBadChannels(d, samprate, satlength, QCoDthresh);
            
            if device==1
                [SD, aux, t] = getMiscNirsVars(d, sd_ind, samprate, wavelengths, probeInfo, channelmask);
            elseif device==2 || device==3
                SD.MeasListAct = [channelmask'; channelmask'];
                SD.MeasListVis = SD.MeasListAct;
            end

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
            save(strcat(outpath,filesep,group,'_',subjname,'_preprocessed.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            
            oxy(:,~channelmask) = NaN;
            deoxy(:,~channelmask) = NaN;
            totaloxy(:,~channelmask) = NaN;
            z_oxy(:,~channelmask) = NaN;
            z_deoxy(:,~channelmask) = NaN;
            z_totaloxy(:,~channelmask) = NaN;
            save(strcat(outpath,filesep,group,'_',subjname,'_preprocessed_nonoisych.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            
            oxy(:,~totalmask) = NaN;
            deoxy(:,~totalmask) = NaN;
            totaloxy(:,~totalmask) = NaN;
            z_oxy(:,~z_totalmask) = NaN;
            z_deoxy(:,~z_totalmask) = NaN;
            z_totaloxy(:,~z_totalmask) = NaN;
            save(strcat(outpath,filesep,group,'_',subjname,'_preprocessed_nouncertainch.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');
            if exist('mni_ch_table','var')
                writetable(mni_ch_table,strcat(outpath,filesep,'channel_mnicoords.csv'),'Delimiter',',');
            end
        end
    
    end

end

preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
qualityReport(dataprefix,1,0,{'scan'},numchannels,preprocdir);

Elapsedtime = toc(Elapsedtime);
fprintf('\n\t Elapsed time: %g seconds\n', Elapsedtime);
end
