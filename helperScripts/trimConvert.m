
function trimTimes =  trimConvert(trimTs, trimPath, numscans)
opts = detectImportOptions(strcat(trimPath,trimTs)); 

trmT = table2array(readtable(strcat(trimPath,trimTs)));
numsubs=width(trmT)/numscans;
trimTimes=nan(length(trmT),numscans,numsubs);
st=1;
for s=1:numsubs
    trimTimes(:,:,s)=trmT(:,st:st+numscans-1);
    st=st+numscans;
end


