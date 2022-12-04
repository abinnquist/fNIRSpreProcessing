function neworder = norder(scanCount,numscans,scanMask,scannames,dataprefix,sname)
neworder=zeros(length(scanCount),numscans,2);
for g=1:length(scanCount)
    for p=1:width(scanCount)
        if scanMask(g,p)==1
            snames2=extract(string(scannames(g,1:scanCount(g,p),p)),lettersPattern);
            if strcmp(dataprefix,snames2(1,1,1)) 
                if length(size(snames2)) > 2
                    sname2=snames2(1,:,2);
                else
                    sname2=snames2(2,:);
                end
            end

            for s=1:numscans
                loc=find(sname(s)==sname2);

                if ~isempty(loc)
                    neworder(g,s,p)=loc;
                end
            end
        else
            neworder(g,1:5,p)=1:5;
        end
    end
end

fndSc=1:numscans;
for g=1:length(scanCount)
    for p=1:width(scanCount)
        if scanMask(g,p)==1
            if sum(neworder(g,:,p)==0) == 1
                loc=find(neworder(g,:,p)==0);
                loc2rp=~ismember(fndSc,neworder(g,:,p));
                neworder(g,loc,p)=find(loc2rp);

            elseif sum(neworder(g,:,p)==0) > 1
                loc=find(neworder(g,:,p)==0);
                loc2rp=~ismember(fndSc,neworder(g,:,p));
                loc2rp=find(loc2rp);

                for sc=1:length(loc2rp)
                    neworder(g,loc(sc),p)=loc2rp(sc);
                end
            end
        end
    end
end



