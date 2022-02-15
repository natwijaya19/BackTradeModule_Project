classdef MarketData
    %MarketData Summary of this class goes here
    %   
    % Input arguments
    %   - dataLoadYahooSetUp: parameters object data required to download 
    %       data from Yahoo
    %   - dataLoadSpreadsheetSetUp: parameters object required  to load data
    %       from spreadsheet
    %   - marketDataSaveSetUp: parameters object required to save data into
    %       spreadsheet
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

    % Methods
    %   loadSymbolMCapRef
    %   loadDataFromYahoo
    %   loadDataFromSpreadsheet
    %   cleanData
    %   saveDataToSpreadsheet

%% Properties and methods definitions
%==========================================================================

    properties
        dataLoadYahooSetUp DataLoadYahooSetUp = []
        dataLoadSpreadsheetSetUp DataLoadSpreadsheetSetUp = []
        marketDataSaveSetUp MarketDataSaveSetUp = []

    end

    properties (SetAccess = private)
        symbols {mustBeText} = []
        openPrice timetable = []
        highPrice timetable = []
        lowPrice timetable = []
        closePrice timetable = []
        volume timetable = []
        marketCap timetable = []
        marketCapCategory timetable = []
        SymMarketCapRef table = []
    end

    properties (Constant)
        exhangeName = "JK"
        priceChangeLimit = [-0.35, 35]
    end

    methods
        function obj = MarketData(dataLoadYahooSetUp,...
                dataLoadSpreadsheetSetUp, marketDataSaveSetUp)
            %MarketData Construct an instance of this class
            obj.dataLoadYahooSetUp = dataLoadYahooSetUp;
            obj.dataLoadSpreadsheetSetUp = dataLoadSpreadsheetSetUp;
            obj.marketDataSaveSetUp = marketDataSaveSetUp;
        end

        function obj = loadSymbolMCapRef(obj)
            %loadSymbolMCapRef Summary of this method goes here
            
            % transfer value
            fileName = obj.dataLoadYahooSetUp.filename;
            sheetName = obj.dataLoadYahooSetUp.sheetnameSymbolList;
            obj.SymMarketCapRef = readtable(fileName, Sheet=sheetName);
        end

        function obj = loadDataFromYahoo(obj)
            %loadDataFromYahoo Summary of this method goes here
            %TODO

            symbols = obj.symbols;
            startDate = obj.dataLoadYahooSetUp.startDate;
            endDate = obj.dataLoadYahooSetUp.endDate;
            interval = obj.dataLoadYahooSetUp.interval;

            % load data from Yahoo
            structOut = loadDataFromYahooFcn (symbols, startdate, endDate, interval);
            
            % transfer value to object
            obj.openPrice = structOut.openPrice;
            obj.highPrice = structOut.highPrice;
            obj.lowPrice = structOut.lowPrice;
            obj.closePrice = structOut.closePrice;
            obj.volume = structOut.volumePrice;
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

function structOut = loadDataFromYahooFcn (symbols, startDate, endDate, interval) 

    %TODO Loop
    datai = getMarketDataViaYahoo(symbols, startDate, endDate, interval);

    structOut.openPrice = openPriceTT;
    structOut.highPrice = highPriceTT;
    structOut.lowPrice = lowPriceTT;
    structOut.closePrice = closePriceTT;
    structOut.volume = volumeTT;

    clearvars -except structOut
end