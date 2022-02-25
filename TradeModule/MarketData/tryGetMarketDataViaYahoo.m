function datai = tryGetMarketDataViaYahoo(symi,...
    startDate, endDate, interval, maxRetry)
% tryGetMarketDataViaYahoo is functin to get data from yahoo with error
% handling. If the the Yahoo data cannot be retrieved, then it will put a
% preallocated timetable TT. TT is a preallocated 1 column timetable with
% variable type double.

    for reTryCount = 1:maxRetry

        if reTryCount == maxRetry
            disp(reTryCount);

        end

        try
            datai = getMarketDataViaYahoo(char(symi), startDate, endDate, interval);
    
            if ~isempty(datai)
                pause(5);
                datai = table2timetable(datai);
                break
            end          
    
        catch ME
        
        end
        
        if and(isempty(datai),reTryCount==maxRetry)
            datai = [];
        end  
    end

end % of function