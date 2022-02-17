classdef DataLoadYahooSetUp
    %DataLoadYahooSetUp is class data holder to hold input required 
    %to download data from Yahoo
    %   
    % Input arguments
    %   filename: name of file where the symbols, marketCapData are stored
    %   sheetnameSymbolList {mustBeText, mustBeTextScalar}
    % ====================================================================
    properties
        fileName {mustBeText} = "DataInput\SymbolsMarketCapReference.xlsx"
        symMarketCapReferenceSheetName {mustBeText} = "SymbolsMarketCapReference"
        marketCapCategoryRangeRefSheetName {mustBeText} = "MarketCap_Category_Range"
        startDate datetime = datetime("1-Jan-2010")
        endDate datetime = datetime("today")
        interval = "1d"
    end

end