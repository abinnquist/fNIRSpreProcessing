% This script will plot either each subject or each dyad for visual
% inspection after preprocessing to see if any motion or other problem
% remains in the data. You can plot every subject/dyad OR specify which
% ones you want to plot with subs2vis.
%
% You will be asked which subjects/dyads you want to visualize. You can
% select all by entering 1:n (i.e., 1:67 if you have 67 subs/dyads) OR any
% combo (i.e., 1:6,52,63). 
%
% NOTE 1: If you notice what looks to be motion (i.e., large quick spikes)
% you may want to use a different motion correction OR change the cutoff
% for what you determine to be motion.
%
% NOTE 2: If you notice very large magnitude channels (i.e., 10 neg. power of 4 or 5) 
% compared to the rest of the channels (10 neg. power of 6) you may want to 
% use reduceMagChans.m to reduce the magnitude of the signal for those channels 
% This can be done after preprocessing as I believe it's NOT a motion problem.
%       The problem may be due to the gain being to low/high during collection
%       OR a weak signal that still collected good data. Not sure if it is a
%       perfect fix BUT it only reduces those high magnitude channels and 
%       does not change the pattern of activation over time.
%
% NOTE 3: If you ran two types of motion correction you can compare the 
% difference by turning on compare in properties. You must have two different 
% motion corrections compiled to plot the difference.

%% Properties to change
% Make sure to change the protperties specific to your study
scn2vis=1; %Which scan you want to visualize
hyper=1; % 1=hyperscanned, 0=single subject
compare=1; %0=off, 1=on
plotallChans=1; %1=plot all channels on one pane, 0=plot each channel seperately
dataprefix='SD';
datapath='C:\Users\Mike\Desktop\SD_nirs';

%% plot all 
% Load in compiled data. Make sure to change this to your data location
load(strcat(datapath,filesep,dataprefix,'_compile.mat'),'oxy3D')
lenConvo=round(480*oxy3D(1).samprate); %Whatever frame length you want to visualize 
if hyper
    [~, nchans, nsubs]=size(oxy3D(scn2vis).sub1);
else
    [~, nchans, nsubs]=size(oxy3D(scn2vis).subdata);
end

%Take note of subjects or dyads that look great and those that have high
%magnitude channels. Make a short list for later comparison.
visInfo = inputdlg({'Which subject/dyads to visualize? (1-n)','What channels (if all put 1:n)?'},'Vis Info', [1 75]); 
subs2vis=str2num(cell2mat(visInfo(1))); %You can specify which subjects/dyads to plot (i.e., 1:nsubs OR 36:40 OR [1,6,23,50])

if str2num(cell2mat(visInfo(2)))
    nchans=str2num(cell2mat(visInfo(2)));
else
    nchans=1:nchans;
end

%Loop to get the correct matrix for plotting channels
sqN=round(sqrt(length(nchans)));
while sqN*6 < length(nchans)
    sqN=sqN+1;
end
if length(nchans) < 17 && length(nchans) > 9
    wd=4;
elseif length(nchans) <=9 && length(nchans) > 6
    wd=3;
elseif length(nchans) <=5
    wd=2;
else
    wd=6;
end

if plotallChans
    for s=subs2vis
        if hyper
            figure()
            tiledlayout(2,1)
            nexttile
            plot(oxy3D(scn2vis).sub1(1:lenConvo,nchans,s))
            title(strcat('Subject 1, Dyad: ',num2str(s)))
            nexttile
            plot(oxy3D(scn2vis).sub2(1:lenConvo,nchans,s))
            title(strcat('Subject 2, Dyad: ',num2str(s)))
        else
            figure()
            plot(oxy3D(scn2vis).subdata(1:lenConvo,nchans,s))
            title(strcat('Subject: ',num2str(s)))
            legend()
        end
    end
else
    if hyper
        for s=subs2vis
            figName=strcat('Dyad_',num2str(s),' Sub1');
            figure('Name',figName)
            ha = tight_subplot(sqN,wd,[.01 .01],[.02 .02],[.02 .02]);
            ch=1;
            for channel = nchans
                curData = oxy3D(scn2vis).sub1(1:lenConvo,channel,s);
                axes(ha(ch))
                plot(curData, 'LineWidth',1)
                h = gca;
                axis on
                yl = legend(num2str(channel),'location','northoutside','FontSize',6);
                set(h,'YTickLabel',[]);
                h.XLabel.Visible = 'off';
                set(h,'XTickLabel',[]);
                xlim([0 lenConvo])
                ch=ch+1;
            end
            figName2=strcat('Dyad_ ',num2str(s),' Sub2');
            figure('Name',figName2)
            ha = tight_subplot(sqN,wd,[.01 .01],[.02 .02],[.02 .02]);
            ch=1;
            for channel = nchans
                curData = oxy3D(scn2vis).sub2(1:lenConvo,channel,s);
                axes(ha(ch))
                plot(curData, 'LineWidth',1)
                h = gca;
                axis on
                yl = legend(num2str(channel),'location','northoutside','FontSize',6);
                set(h,'YTickLabel',[]);
                h.XLabel.Visible = 'off';
                set(h,'XTickLabel',[]);
                xlim([0 lenConvo])
                ch=ch+1;
            end
        end
    else
        for s=subs2vis
            figName=strcat('Sub_',num2str(s));
            figure('Name',figName)
            ha = tight_subplot(sqN,wd,[.001 .01],[.01 .01],[.02 .02]);
            ch=1;
            for channel = nchans
                curData = oxy3D(scn2vis).subdata(1:lenConvo,channel,s);
                axes(ha(ch))
                plot(curData, 'LineWidth',1)
                h = gca;
                axis on
                yl = legend(num2str(channel),'location','northoutside','FontSize',6);
                set(h,'YTickLabel',[]);
                h.XLabel.Visible = 'off';
                set(h,'XTickLabel',[]);
                xlim([0 lenConvo])
                ch=ch+1;
            end
        end
    end
end

%% Visually compare two different types of motion correction
if compare
    oldOxy=oxy3D;
    newdata=uigetdir('','Choose Data with New Motion Correction');
    load(strcat(newdata,filesep,dataprefix,'_compile.mat'),'oxy3D')
    compInfo = inputdlg({'Which subject/dyads to compare visually? (1-n)'},'Vis. comp. Info', [1 75]); 
    % Only used if comparing
    subs2comp=str2num(cell2mat(compInfo(1))); %Any number of subjects to compare original vs. new motion corr
    
    for s=subs2comp
        if hyper
            figure()
            tiledlayout(4,1)
            nexttile
            plot(oldOxy(scn2vis).sub1(1:lenConvo,:,s))
            title(strcat('Current Correction, S1, Dyad: ',num2str(s)))
            nexttile
            plot(oxy3D(scn2vis).sub1(1:lenConvo,:,s))
            title(strcat('New Correction, S1, Dyad: ',num2str(s)))
            nexttile
            plot(oldOxy(scn2vis).sub2(1:lenConvo,:,s))
            title(strcat('Current Correction, S2, Dyad: ',num2str(s)))
            nexttile
            plot(oxy3D(scn2vis).sub2(1:lenConvo,:,s))
            title(strcat('New Correction, S2, Dyad: ',num2str(s)))
        else
            figure()
            tiledlayout(2,1)
            nexttile
            plot(oldOxy(scn2vis).subdata(1:lenConvo,:,s))
            title(strcat('Current Correction, Subject: ',num2str(s)))
            nexttile
            plot(oxy3D(scn2vis).subdata(1:lenConvo,:,s))
            title(strcat('New Correction, Subject: ',num2str(s)))
        end
    end
end
