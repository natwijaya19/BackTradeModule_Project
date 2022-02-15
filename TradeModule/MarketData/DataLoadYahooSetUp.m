classdef DataLoadYahooSetUp
    %DataLoadYahooSetUp is class data holder to hold input required 
    %to download data from Yahoo
    %   
    % Input arguments
    %   filename: name of file where the symbols, marketCapData are stored
    %   sheetnameSymbolList {mustBeText, mustBeTextScalar}
    % ====================================================================
    properties
        filename {mustBeText, mustBeFile, mustBeTextScalar} = "filename"
        sheetnamesymMarketCapReference {mustBeText} = "SymMarketCapReference"
        startDate datetime = datetime("1-Jan-2010")
        endDate datetime = datetime("today")
        interval = "1d"
    end

    methods
        function obj = DataLoadYahooSetUp(filename, ...
                sheetnamesymMarketCapReference, startDate, endDate, interval)
            
            %DataLoadYahooSetUp Construct an instance of this class
            obj.filename = filename;
            obj.sheetnamesymMarketCapReference = sheetnamesymMarketCapReference;
            obj.startDate = startDate;
            obj.endDate = endDate;
            obj.interval = interval;
            
        end
    end
end