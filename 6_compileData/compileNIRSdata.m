%Compiles the dyadic data for n scans.
%NOTE: Even if you don't have the scan make sure you have an empty folder
%so the script does not error out.
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compileNIRSdata(preprocdir,dataprefix,hyperscan,ch_reject,numScans,zdim,snames)

%find all of the preprocessed folders
currdir=dir(strcat(preprocdir,filesep,dataprefix,'*'));

if hyperscan
    nSubs=length(dir(strcat(preprocdir,filesep,currdir(1).name,filesep,dataprefix,'*')));
    
    for sj=1:nSubs
        subN=strcat('sub',num2str(sj));
        tN=strcat('t',num2str(sj));
        sN=strcat('triggers',num2str(sj));
        auxN=strcat('aux',num2str(sj));
    
        for sc=1:numScans
            z_oxyC=nan(1,1,nSubs); z_deoxyC=nan(1,1,nSubs);
            tC=nan(1,1,nSubs); sC=nan(1,1,nSubs);
            auxC=nan(1,1,nSubs); 
    
            for i=1:length(currdir)
                dyad=currdir(i).name; %define dyad
                dyaddir=dir(strcat(preprocdir,filesep,dyad,filesep,dataprefix,'*'));
                subject=dyaddir(sj).name;
                
                if numScans==1
                    subfiles=dir(strcat(dyaddir(sj).folder,filesep,subject,filesep,dataprefix,'*.mat')); 
                else
                    subfolder=dir(strcat(dyaddir(sj).folder,filesep,subject,filesep,dataprefix,'*')); 
                    subfiles=dir(strcat(subfolder(sj).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                end

                if zdim && ~isempty(subfiles) %In case you are missing scans
                    load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux')
                    [length_convo, numchans]=size(z_oxy);
                    z_deoxyC(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                    z_oxyC(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                elseif ~zdim && ~isempty(subfiles)
                    load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy','t','s','samprate','aux')
                    [length_convo, numchans]=size(oxy);
                    z_deoxyC(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                    z_oxyC(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                end
                if exist('aux','var')
                    [lenAux,nAux]=size(aux);
                    auxC(1:lenAux,1:nAux,i)=aux(1:lenAux,:);
                end
                tC(1:length_convo,1,i)=t;
                if ~isempty(s)
                    sC(1:length_convo,1,i)=s(:,1);
                end
            end  
            deoxy3D(sc).name=snames{sc};
            deoxy3D(sc).(subN)=z_deoxyC;
            deoxy3D(sc).(tN)=tC;
            deoxy3D(sc).(sN)=sC;
    
            oxy3D(sc).name=snames{sc};
            oxy3D(sc).(subN)=z_oxyC;
            oxy3D(sc).(tN)=tC;
            oxy3D(sc).(sN)=sC;

            if ~isempty(auxC)
                oxy3D(sc).(auxN)=auxC;
                deoxy3D(sc).(auxN)=auxC;
            end

            if sj==max(nSubs)
                deoxy3D(sc).samprate=samprate;
                oxy3D(sc).samprate=samprate;
            end
        end
    end
else
    for sc=1:numScans
        z_oxy1=nan(1,1,1); z_deoxy1=nan(1,1,1);
        tC=nan(1,1,1); sC=nan(1,1,1);
        auxC=nan(1,1,1); 
    
        for i=1:length(currdir)
            subject=currdir(i).name; %define subject
            subfolder=dir(strcat(preprocdir,filesep,subject,filesep,dataprefix,'*'));
    
            if ~isempty(subfolder) 
                subfiles=dir(strcat(subfolder(1).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                if ~isempty(subfiles)
                    if zdim
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux') 
                        [length_convo, numchans]=size(z_oxy);
                        z_deoxy1(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                        z_oxy1(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                    else
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy','t','s','samprate','aux') 
                        [length_convo, numchans]=size(oxy);
                        z_deoxy1(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                        z_oxy1(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                    end
                elseif ~isempty(subfiles) && numScans == 1 %for single sub & single scan
                    if zdim
                        load(strcat(subfolder(ch_reject).folder,filesep,subfolder(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux') 
                        [length_convo, numchans]=size(z_oxy);
                        z_deoxy1(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                        z_oxy1(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                    else
                        load(strcat(subfolder(ch_reject).folder,filesep,subfolder(ch_reject).name),'oxy','deoxy','t','s','samprate','aux') 
                        [length_convo, numchans]=size(oxy);
                        z_deoxy1(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                        z_oxy1(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                    end
                end
                [lenAux,nAux]=size(aux);
                auxC(1:lenAux,1:nAux,i)=aux(1:lenAux,:);
                tC(1:length_convo,1,i)=t';
                sC(1:length_convo,1,i)=s;    
            end
        end
        deoxy3D(sc).name=snames{sc};
        deoxy3D(sc).subdata=z_deoxy1;
        deoxy3D(sc).t=tC;
        deoxy3D(sc).triggers=sC;
        deoxy3D(sc).samprate=samprate;
        deoxy3D(sc).aux=auxC;
      
        oxy3D(sc).name=snames{sc};
        oxy3D(sc).subdata=z_oxy1;
        oxy3D(sc).t=tC;
        oxy3D(sc).triggers=sC;
        oxy3D(sc).samprate=samprate;
        oxy3D(sc).aux=auxC;
    end  
end
