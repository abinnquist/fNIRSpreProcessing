%Compiles the solo data for n scans
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compilesoloNIRSdata(preprocess_dir,dataprefix,ch_reject,numScans,zdim,snames)

%find all of the preprocessed folders
currdir=dir(strcat(preprocess_dir,filesep,dataprefix,'*'));

for sc=1:numScans
    z_oxyC=nan(1,1,1); z_deoxyC=nan(1,1,1);
    tC=nan(1,1,1); sC=nan(1,1,1);
    auxC=nan(1,1,1); 

    for i=1:length(currdir)
        subject=currdir(i).name; %define dyad
        subfolder=dir(strcat(preprocess_dir,filesep,subject,filesep,dataprefix,'*'));

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
            else %for single sub & single scan
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
            tC(1:length_convo,1,i)=t';
            sC(1:length_convo,1,i)=s;
            auxC(1:lenAux,1:nAux,i)=aux(1:lenAux,:);
        end
    end
    deoxy3D(sc).name=snames{sc};
    deoxy3D(sc).subdata=z_deoxy1;
    deoxy3D(sc).t=tC;
    deoxy3D(sc).triggers=sC;
    deoxy3D(sc).aux=auxC;
    deoxy3D(sc).samprate=samprate;
  
    oxy3D(sc).name=snames{sc};
    oxy3D(sc).subdata=z_oxy1;
    oxy3D(sc).t=tC;
    oxy3D(sc).triggers=sC;
    oxy3D(sc).aux=auxC;
    oxy3D(sc).samprate=samprate;
end  