
[~,numscans]=size(oxy3D);
if hyperscan
    [~,numchannels,nsubs]=size(oxy3D(1).sub1);

    lostChans1=zeros(numchannels,numscans);
    lostChans2=zeros(numchannels,numscans);
    lostSubChans1=nan(nsubs,numscans);
    lostSubChans2=nan(nsubs,numscans);
    lostsubxch1=nan(nsubs,numchannels,numscans);
    lostsubxch2=nan(nsubs,numchannels,numscans);

    for sc=1:numscans
        lostChans1(:,sc)=sum(isnan(oxy3D(sc).sub1(1,:,:)),3)';
        lostChans2(:,sc)=sum(isnan(oxy3D(sc).sub2(1,:,:)),3)';

        lostsubxch1(:,:,sc)=squeeze(isnan(oxy3D(sc).sub1(1,:,:)))';
        lostsubxch2(:,:,sc)=squeeze(isnan(oxy3D(sc).sub2(1,:,:)))';

        lostSubChans1(:,sc)=squeeze(sum(isnan(oxy3D(sc).sub1(1,:,:))));
        lostSubChans2(:,sc)=squeeze(sum(isnan(oxy3D(sc).sub2(1,:,:))));
    end
    lostChans=lostChans1+lostChans2;
    Channel=1:numchannels; Channel=Channel';
    lostChans=array2table(lostChans,'VariableNames',snames);
    lostChans=[array2table(Channel),lostChans];

    Dyad=1:nsubs;Dyad=Dyad';Dyad=[Dyad;Dyad];
    Subject=[repelem(1,nsubs)';repelem(2,nsubs)'];
    lostSubChans=[lostSubChans1;lostSubChans2];
    lostSubChans=array2table(lostSubChans,'VariableNames',snames);
    lostSubChans=[array2table(Dyad),array2table(Subject),lostSubChans];

    for sc=1:numscans
        oxy3D(sc).lostsubxch1=lostsubxch1(:,:,sc);
        oxy3D(sc).lostsubxch2=lostsubxch2(:,:,sc);
        deoxy3D(sc).lostsubxch1=lostsubxch1(:,:,sc);
        deoxy3D(sc).lostsubxch2=lostsubxch2(:,:,sc);
    end
else
    [~,numchannels,nsubs]=size(oxy3D(1).subdata);
    lostChans=zeros(numchannels,numscans);
    lostSubChans=nan(nsubs,numscans);
    lostsubxch=nan(nsubs,numchannels,numscans);

    for sc=1:numscans
        lostChans(:,sc)=sum(isnan(oxy3D(sc).subdata(1,:,:)),3)';
        lostsubxch(:,:,sc)=squeeze(isnan(oxy3D(sc).subdata(1,:,:)))';
        lostSubChans(:,sc)=squeeze(sum(isnan(oxy3D(sc).subdata(1,:,:))));
    end
    Channel=1:numchannels; Channel=Channel';
    lostChans=array2table(lostChans,'VariableNames',snames);
    lostChans=[array2table(Channel),lostChans];

    Subject=1:nsubs;Subject=Subject';
    lostSubChans=array2table(lostSubChans,'VariableNames',snames);
    lostSubChans=[array2table(Subject),lostSubChans];

    for sc=1:numscans
        oxy3D(sc).lostsubxch=lostsubxch(:,:,sc);
        deoxy3D(sc).lostsubxch=lostsubxch(:,:,sc);
    end
end

if ch_reject==2
    qaoutpaths=strcat(preprocdir,filesep,'QAreport_allsubj_cleanchannels.csv');
    qaoutpath=strcat(preprocdir,filesep,'QAreport_allchans_cleanchannels.csv');
elseif ch_reject==3
    qaoutpaths=strcat(preprocdir,filesep,'QAreport_allsubj_cleanandcertainchannels.csv');
    qaoutpath=strcat(preprocdir,filesep,'QAreport_allchans_cleanandcertainchannels.csv');
end
writetable(lostChans,qaoutpath,'Delimiter',',');
writetable(lostSubChans,qaoutpaths,'Delimiter',',');
