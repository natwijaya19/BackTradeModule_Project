classdef YahooDataSetUp
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        path = pwd;
        fileName = "DataInput\Symbols_MarketCap_MarketCapCategoryRange.xlsx";
        symMktCapSheetName = "SymbolsMarketCapReference"
        mktCapCategRangeSheet = "MarketCap_Category_Range"
        startDate = datetime("1-Jan-2010")
        endDate = datetime("today")
        interval = "1d"
        maxRetry = 3;
    end
    
end
