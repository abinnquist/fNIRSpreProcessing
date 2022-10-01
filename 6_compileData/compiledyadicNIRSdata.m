%Compiles the dyadic data for n scans.
%NOTE: Even if you don't have the scan make sure you have an empty folder
%so the script does not error out.
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compiledyadicNIRSdata(preprocess_dir,dataprefix,ch_reject,numScans,zdim)

%find all of the preprocessed folders
currdir=dir(strcat(preprocess_dir,filesep,dataprefix,'*'));
nSubs=length(dir(strcat(preprocess_dir,filesep,currdir(1).name,filesep,dataprefix,'*')));

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
            dyaddir=dir(strcat(preprocess_dir,filesep,dyad,filesep,dataprefix,'*'));
            subject=dyaddir(sj).name;
            subfolder=dir(strcat(dyaddir(sj).folder,filesep,subject,filesep,dataprefix,'*')); 
            subfiles=dir(strcat(subfolder(sj).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
            
            if zdim
                load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy','t','s','samprate','aux')
                [length_convo, numchans]=size(z_oxy);
                z_deoxyC(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                z_oxyC(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
            else
                load(strcat(subfiles(ch_reject).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy','t','s','samprate','aux')
                [length_convo, numchans]=size(oxy);
                z_deoxyC(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                z_oxyC(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
            end
            [lenAux,nAux]=size(aux);
            tC(1:length_convo,1,i)=t';
            sC(1:length_convo,1,i)=s;
            auxC(1:lenAux,1:nAux,i)=aux(1:lenAux,:);
        end  
        deoxy3D(sc).name=strcat('Scan',num2str(sc));
        deoxy3D(sc).(subN)=z_deoxyC;
        deoxy3D(sc).(tN)=tC;
        deoxy3D(sc).(sN)=sC;
        deoxy3D(sc).(auxN)=auxC;

        oxy3D(sc).name=strcat('Scan',num2str(sc));
        oxy3D(sc).(subN)=z_oxyC;
        oxy3D(sc).(tN)=tC;
        oxy3D(sc).(sN)=sC;
        oxy3D(sc).(auxN)=auxC;
        if sj==max(nSubs)
            deoxy3D(sc).samprate=samprate;
            oxy3D(sc).samprate=samprate;
        end
    end
end