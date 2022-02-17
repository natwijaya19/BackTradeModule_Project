function datai = tryGetMarketDataViaYahoo(symi,...
    startDate, endDate, interval, maxRetry, TT)
% tryGetMarketDataViaYahoo is functin to get data from yahoo with error
% handling. If the the Yahoo data cannot be retrieved, then it will put a
% preallocated timetable TT. TT is a preallocated 1 column timetable with
% variable type double.

    for reTryCount = 1:maxRetry
        reTryCount;

        if reTryCount == maxRetry
            reTryCount

        end

        try
            datai = getMarketDataViaYahoo(char(symi), startDate, endDate, interval);
    
            if ~isempty(datai)
                datai = table2timetable(datai);
                break
            end          
    
        catch ME
        
        end
        
        if and(isempty(datai),reTryCount==maxRetry)
            datai = TT;
        end  
    end

end % of function