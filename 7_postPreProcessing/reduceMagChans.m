%% Properties to change
hyper=1; % 1=hyperscanned, 0=single subject
convoLen=[3051,4577,4577,1525,2893]; %IN: 3000, OUT&NEU: 4500, REST: 1800, VIDS: 2893
%convoLen=[4500,4500,1100]; %BOND&OUT: 4500, REST: 1100
%convoLen=[2440,6100,2440,1500]; %BOND&OUT: 4500, REST: 1100
datapath='C:\Users\Mike\Desktop\IPC_nirs';
dataprefix='IPC';

%% Load in compiled data. Make sure to change this to your data location
load(strcat(datapath,filesep,dataprefix,'_compile.mat'),'oxy3D','deoxy3D')

[~,numscans]=size(oxy3D);
if hyper
    [~, nchans, nsubs]=size(oxy3D(1).sub1);
    endScan=nan(nsubs,2,numscans);
else
    [~, nchans, nsubs]=size(oxy3D(1).subdata);
    endScan=nan(nsubs,numscans);
end

% Grabs length of each scan
for sc=1:numscans
    for sb=1:nsubs
        if hyper
            sb1=oxy3D(sc).sub1(:,:,sb);
            for ch=1:nchans
                if ~isnan(sb1(1,ch))
                    endZ=find(sb1(:,ch)==0);
                    if ~isempty(endZ)
                        endScan(sb,1,sc)=endZ(1,1);
                    end
                    break
                end
            end

            sb2=oxy3D(sc).sub2(:,:,sb);
            for ch=1:nchans
                if ~isnan(sb2(1,ch))
                    endZ=find(sb2(:,ch)==0);
                    if ~isempty(endZ)
                        endScan(sb,2,sc)=endZ(1,1);
                    end
                    break
                end
            end
        else
            sb1=oxy3D(sc).subdata(:,:,sb);
            for ch=1:nchans
                if ~isnan(sb1(1,ch))
                    endZ=find(sb1(:,ch)==0);
                    if ~isempty(endZ)
                        endScan(sb,sc)=endZ(1,1);
                    end
                    break
                end
            end
        end
    end
end

%For scans that don't have an end
for sc=1:numscans
    if hyper
        for s=1:2
            for sb=1:nsubs
                if isnan(endScan(sb,s,sc))
                    endScan(sb,s,sc)=convoLen(sc);
                end
            end
        end
    else
        for sb=1:nsubs
            if isnan(endScan(sb,sc))
                endScan(sb,sc)=convoLen(sc);
            end
        end
    end
end
endScan=endScan-1; %Since it finds the first zero in the data

%% Check for existing channels of large magnitude (i.e., "loud" channels)
% Instead of visually inspecting every scan use below to catch channels
% outside of the norm (i.e. 1.8 standard deviations in magnitude). Then
% reduce those channels to the same magnitide as the rest. You can also
% cross-reference with visual inspection to see the change in reduction.

for scn2vis=1:numscans
    chanDist1=nan(nsubs,nchans,2);
    if hyper
        chanDist2=nan(nsubs,nchans,2);
        lenConvo=endScan(:,:,scn2vis);
        endR=lenConvo-50;
    else
        lenConvo=endScan(:,scn2vis);
        endR=lenConvo-50;
    end
    %To get the max and min of each scan
    for sb=1:nsubs
        for ch=1:nchans
            if hyper
                if ~isempty(oxy3D(scn2vis).sub1(1:endR(sb,1),ch,sb))
                    chanDist1(sb,ch,1)=max(oxy3D(scn2vis).sub1(1:endR(sb,1),ch,sb));
                    chanDist1(sb,ch,2)=min(oxy3D(scn2vis).sub1(1:endR(sb,1),ch,sb));
                end
                if ~isempty(oxy3D(scn2vis).sub1(1:endR(sb,2),ch,sb))
                    chanDist2(sb,ch,1)=max(oxy3D(scn2vis).sub2(1:endR(sb,2),ch,sb));
                    chanDist2(sb,ch,2)=min(oxy3D(scn2vis).sub2(1:endR(sb,2),ch,sb));
                end
            else
                if ~isempty(oxy3D(scn2vis).subdata(1:endR(sb,1),ch,sb))
                    chanDist1(sb,ch,1)=max(oxy3D(scn2vis).subdata(1:endR(sb,1),ch,sb));
                    chanDist1(sb,ch,2)=min(oxy3D(scn2vis).subdata(1:endR(sb,1),ch,sb));
                end
            end
        end
    end
    
    for ex=1:2
        meanSig1(1,ex)=nanmean(nanmean(chanDist1(:,:,ex)));
        stdSig1(1,ex)=nanstd(nanstd(chanDist1(:,:,ex)));
        if hyper
            meanSig2(1,ex)=nanmean(nanmean(chanDist2(:,:,ex)));
            stdSig2(1,ex)=nanstd(nanstd(chanDist2(:,:,ex)));
        end
    end
    
    redMag1=nan(nsubs,nchans,2);
    if hyper
        redMag2=nan(nsubs,nchans,2);
    end
    for sb=1:nsubs
        redMag1(sb,:,1)=chanDist1(sb,:,1) > meanSig1(1,1)+(stdSig1(1,1)*1.8);
        redMag1(sb,:,2)=chanDist1(sb,:,2) < meanSig1(1,2)-(stdSig1(1,2)*1.8);
        if hyper
            redMag2(sb,:,1)=chanDist2(sb,:,1) > meanSig2(1,1)+(stdSig2(1,1)*1.8);
            redMag2(sb,:,2)=chanDist2(sb,:,2) < meanSig2(1,2)-(stdSig2(1,2)*1.8);
        end
    end
    newRed(:,:,1)=redMag1(:,:,1)+redMag1(:,:,2);
    if hyper
        newRed(:,:,2)=redMag2(:,:,1)+redMag2(:,:,2);
    end
    newRed=logical(newRed);
    
    scanRed1=nan(max(lenConvo(:,1)),nchans,nsubs);
    if hyper
        scanRed2=nan(max(lenConvo(:,2)),nchans,nsubs);
        for sb=1:nsubs
            scanRed1(1:lenConvo(sb,1),:,sb)=oxy3D(scn2vis).sub1(1:lenConvo(sb,1),:,sb); 
            scanRed2(1:lenConvo(sb,2),:,sb)=oxy3D(scn2vis).sub2(1:lenConvo(sb,2),:,sb);
        end
    else
        for sb=1:nsubs
            scanRed1(1:lenConvo(sb,1),:,sb)=oxy3D(scn2vis).subdata(1:lenConvo(sb,1),:,sb); 
        end
    end
    
    for sb=1:nsubs
        if hyper
            scanRed1(:,newRed(sb,:,1),sb)=scanRed1(:,newRed(sb,:,1),sb)/100;
            scanRed2(:,newRed(sb,:,2),sb)=scanRed2(:,newRed(sb,:,2),sb)/100;
        else
            scanRed1(:,newRed(sb,:,1),sb)=scanRed1(:,newRed(sb,:,1),sb)/100;
        end
    end
    
    %One more time to catch smaller magnitude outliers
    redMag1=nan(nsubs,nchans,2);
    if hyper
        redMag2=nan(nsubs,nchans,2);
    end
    for sb=1:nsubs
        redMag1(sb,:,1)=chanDist1(sb,:,1) > meanSig1(1,1)+(stdSig1(1,1)*1.5);
        redMag1(sb,:,2)=chanDist1(sb,:,2) < meanSig1(1,2)-(stdSig1(1,2)*1.5);
        if hyper
            redMag2(sb,:,1)=chanDist2(sb,:,1) > meanSig2(1,1)+(stdSig2(1,1)*1.5);
            redMag2(sb,:,2)=chanDist2(sb,:,2) < meanSig2(1,2)-(stdSig2(1,2)*1.5);
        end
    end
    newRed2(:,:,1)=redMag1(:,:,1)+redMag1(:,:,2);
    if hyper
        newRed2(:,:,2)=redMag2(:,:,1)+redMag2(:,:,2);
    end
    newRed2=logical(newRed2);
    newRed3=newRed2-newRed; newRed3=logical(newRed3);
    
    for sb=1:nsubs
        scanRed1(:,newRed3(sb,:,1),sb)=scanRed1(:,newRed3(sb,:,1),sb)/10;
        if hyper
            scanRed2(:,newRed3(sb,:,2),sb)=scanRed2(:,newRed3(sb,:,2),sb)/10;
        end
    end
    if hyper
        oxy3D(scn2vis).sub1R=scanRed1;
        oxy3D(scn2vis).sub2R=scanRed2;
    else
        oxy3D(scn2vis).subR=scanRed1;
    end
end
save(strcat(datapath,filesep,dataprefix,'_compileR.mat'),'oxy3D','deoxy3D')

