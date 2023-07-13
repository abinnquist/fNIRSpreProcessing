%Compiles the dyadic data for n scans.
%NOTE: Even if you don't have the scan make sure you have an empty folder
%so the script does not error out.
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compileNIRSdata(preprocdir,dataprefix,hyperscan,ch_reject,numscans,zdim,snames)

%find all of the preprocessed folders
currdir=dir(strcat(preprocdir,filesep,dataprefix,'*'));

if length(numscans) < 2
    numscans=1:numscans;
end

if hyperscan
    nSubs=length(dir(strcat(preprocdir,filesep,currdir(1).name,filesep,dataprefix,'*')));
    
    for sj=1:nSubs
        subN=strcat('sub',num2str(sj));
        tN=strcat('t',num2str(sj));
        sN=strcat('triggers',num2str(sj));
        auxN=strcat('aux',num2str(sj));

        sk=1;
        for sc=numscans
            oxyC=nan(1,1,nSubs); deoxyC=nan(1,1,nSubs);
            tC=nan(1,1,nSubs); sC=nan(1,1,nSubs); auxC=nan(1,1,nSubs);         
    
            for i=1:length(currdir)
                dyad=currdir(i).name; %define dyad
                dyaddir=dir(strcat(preprocdir,filesep,dyad,filesep,dataprefix,'*'));
                subject=dyaddir(sj).name;
                
                if numscans==1
                    subfiles=dir(strcat(dyaddir(sj).folder,filesep,subject,filesep,dataprefix,'*.mat')); 
                else
                    subfolder=dir(strcat(dyaddir(sj).folder,filesep,subject,filesep,dataprefix,'*')); 
                    subfiles=dir(strcat(subfolder(sj).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                end
                
                if ~isempty(subfiles) %In case you are missing scans
                    if zdim && ~isempty(subfiles) %In case you are missing scans
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux')
                        deoxyC(1:length(z_deoxy),1:width(z_deoxy),i)=z_deoxy;
                        oxyC(1:length(z_oxy),1:width(z_oxy),i)=z_oxy;
                    elseif ~zdim && ~isempty(subfiles)
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy','t','s','samprate','aux')
                        deoxyC(1:length(deoxy),1:width(deoxy),i)=deoxy;
                        oxyC(1:length(oxy),1:width(oxy),i)=oxy;
                    end

                    if exist('aux','var')
                        auxC(1:length(aux),1:width(aux),i)=aux;
                    end

                    tC(1:length(t),1,i)=t;
                    if ~isempty(s)
                        sC(1:length(s),1,i)=s(:,1);
                    end
                end
            end  
            deoxy3D(sk).name=snames{sk};
            deoxy3D(sk).(subN)=deoxyC;
            deoxy3D(sk).(tN)=tC;
            deoxy3D(sk).(sN)=sC;
    
            oxy3D(sk).name=snames{sk};
            oxy3D(sk).(subN)=oxyC;
            oxy3D(sk).(tN)=tC;
            oxy3D(sk).(sN)=sC;

            if ~isempty(auxC)
                oxy3D(sk).(auxN)=auxC;
                deoxy3D(sk).(auxN)=auxC;
            end

            if sj==max(nSubs)
                deoxy3D(sk).samprate=samprate;
                oxy3D(sk).samprate=samprate;
            end
            sk=sk+1;
        end
    end
else
    sk=1;
    for sc=numscans
        oxyC=nan(1,1,1); deoxyC=nan(1,1,1);
        tC=nan(1,1,1); sC=nan(1,1,1); auxC=nan(1,1,1);   
    
        for i=1:length(currdir)
            subject=currdir(i).name; %define subject
            subfolder=dir(strcat(preprocdir,filesep,subject,filesep,dataprefix,'*'));
    
            if ~isempty(subfolder) 
                subfiles=dir(strcat(subfolder(1).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                if ~isempty(subfiles)
                    if zdim
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux') 
                        deoxyC(1:length(z_deoxy),1:width(z_deoxy),i)=z_deoxy;
                        oxyC(1:length(z_oxy),1:width(z_oxy),i)=z_oxy;
                    else
                        load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy','t','s','samprate','aux') 
                        deoxyC(1:length(deoxy),1:width(deoxy),i)=deoxy;
                        oxyC(1:length(oxy),1:width(oxy),i)=oxy;
                    end
                elseif ~isempty(subfiles) && numscans == 1 %for single sub & single scan
                    if zdim
                        load(strcat(subfolder(ch_reject).folder,filesep,subfolder(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux') 
                        deoxyC(1:length(z_deoxy),1:width(z_deoxy),i)=z_deoxy;
                        oxyC(1:length(z_oxy),1:width(z_oxy),i)=z_oxy;
                    else
                        load(strcat(subfolder(ch_reject).folder,filesep,subfolder(ch_reject).name),'oxy','deoxy','t','s','samprate','aux') 
                        deoxyC(1:length(deoxy),1:width(deoxy),i)=deoxy;
                        oxyC(1:length(oxy),1:width(oxy),i)=oxy;
                    end
                end
                
                if exist('aux','var')
                    auxC(1:length(aux),1:width(aux),i)=aux;
                end
                tC(1:length(t),1,i)=t';
                sC(1:length(s),1,i)=s;    
            end
        end
        deoxy3D(sk).name=snames{sk};
        deoxy3D(sk).subdata=deoxyC;
        deoxy3D(sk).t=tC;
        deoxy3D(sk).triggers=sC;
      
        oxy3D(sk).name=snames{sk};
        oxy3D(sk).subdata=oxyC;
        oxy3D(sk).t=tC;
        oxy3D(sk).triggers=sC;

        if ~isempty(auxC) 
            deoxy3D(sk).aux=auxC;
            oxy3D(sk).aux=auxC;
        end

        if sj==max(nSubs)
            deoxy3D(sk).samprate=samprate;
            oxy3D(sk).samprate=samprate;
        end    
        sk=sk+1;
    end  
end
