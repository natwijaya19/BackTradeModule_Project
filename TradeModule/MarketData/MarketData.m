classdef MarketData
    %MarketData Summary of this class goes here
    %   
    % Input arguments
 
    % 
    % Other properties
    %   symbols {mustBeText} = []
    %   openPrice timetable = []
    %   highPrice timetable = []
    %   lowPrice timetable = []
    %   closePrice timetable = []
    %   volume timetable = []
    %   marketCap timetable = []
    %   marketCapCategory timetable = []
    %   SymMarketCapRef table = []
    %   MarketCapRangeRef table = []

    % Methods
    %   loadSymbolMCapRef
    %   loadDataFromYahoo
    %   loadDataFromSpreadsheet
    %   cleanData
    %   saveDataToSpreadsheet

%------------------------------------------------------------------------
%% Properties section
%------------------------------------------------------------------------
    properties
        % YahooDataLoadSetUp
        yahooData_fileName = "DataInput\Symbols_MarketCap_MarketCapCategoryRange.xlsx"
        yahooData_symMktCapSheetName = "SymbolsMarketCapReference"
        yahooData_mktCapCategRangeSheet = "MarketCap_Category_Range"
        startDate = datetime("1-Jan-2018")
        endDate = datetime("today")
        interval = "1d"
        maxRetry = 5;
        
        % SpreadsheetDataLoadSetUp
        spreadhseetData_filename = "DataInput\PriceVolumeInput"
        spreadhseetData_openPriceSheet = "openPrice"
        spreadhseetData_lowPriceSheet = "lowPrice"
        spreadhseetData_highPriceSheet = "highPrice"
        spreadhseetData_closePriceSheet = "lowPrice"
        spreadhseetData_volumeSheet = "volume"
        spreadhseetData_IndexIHSGSheet = "IndexIHSG"

        % SpreadsheetDataLoadSetUp
        saveData_filename = "DataInput\PriceVolumeInput"
        saveData_openPriceSheet = "openPrice"
        saveData_lowPriceSheet = "lowPrice"
        saveData_highPriceSheet = "highPrice"
        saveData_closePriceSheet= "lowPrice"
        saveData_volumeSheet = "volume"
        saveData_IndexIHSGSheet = "IndexIHSG"

    end

    properties (SetAccess = private)
        symbols 
        openPrice
        highPrice
        lowPrice 
        closePrice 
        volume 
        indexIHSG
        marketCap 
        marketCapCategory 
        symMarketCapRef 
        marketCapRangeRef 
    end

    properties (Constant)
        exhangeName = "JK"
        priceChangeLimit = [-0.35, 35]
    end

%------------------------------------------------------------------------
%% Methods section
%------------------------------------------------------------------------
    methods

        function obj = loadSymbolMCapRef(obj)
            %loadSymbolMCapRef Summary of this method goes here

            fileName = obj.yahooData_fileName;
            sheetNameSymCap = obj.yahooData_symMktCapSheetName;
            sheetNamecaptCategRange = obj.yahooData_mktCapCategRangeSheet;

            obj.symMarketCapRef = readtable(fileName, Sheet=sheetNameSymCap);
            obj.marketCapRangeRef = readtable(fileName, Sheet=sheetNamecaptCategRange);
            obj.symbols = string(obj.symMarketCapRef.Symbol);           
        end

        function obj = loadDataFromYahoo(obj)
            %loadDataFromYahoo Summary of this method goes here
            %TODO
            % load data from Yahoo using background pool

            numOut = 1; % number of function output from calc.
            F = parfevalOnAll(@loadDataFromYahooFcn, numOut, obj.symbols, ...
                obj.startDate, obj.endDate, obj.interval, obj.maxRetry);
            priceVolumeData = fetchOutputs(F);

%             priceVolumeData = loadDataFromYahooFcn (obj.symbols,...
%                 obj.startDate, obj.endDate, obj.interval, obj.maxRetry);
            
            % transfer value to object
            obj.openPrice = priceVolumeData.openPrice;
            obj.highPrice = priceVolumeData.highPrice;
            obj.lowPrice = priceVolumeData.lowPrice;
            obj.closePrice = priceVolumeData.closePrice;
            obj.volume = priceVolumeData.volumePrice;
            obj.indexIHSG = priceVolumeData.indexIHSG;
        end
        
        function outputArg = loadDataFromSpreadsheet(obj,inputArg)
            %loadDataFromSpreadsheet Summary of this method goes here
            % TODO
            outputArg = obj.Property1 + inputArg;
        end

        function outputArg = cleanData(obj,inputArg)
            %cleanData Summary of this method goes here
            %TODO
            outputArg = obj.Property1 + inputArg;
        end

        function outputArg = saveDataToSpreadsheet(obj,inputArg)
            %saveDataToSpreadsheet Summary of this method goes here
            %TODO
            outputArg = obj.Property1 + inputArg;
        end    
    end
end

%% Helper functions
%==========================================================================

