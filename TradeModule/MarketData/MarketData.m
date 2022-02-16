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
        maxRetry = 1;
        
        % SpreadsheetDataLoadSetUp
        spreadhseetData_filename = "DataInput\PriceVolumeInput.xlsx"
        spreadhseetData_openPriceSheet = "openPrice"
        spreadhseetData_lowPriceSheet = "lowPrice"
        spreadhseetData_highPriceSheet = "highPrice"
        spreadhseetData_closePriceSheet = "lowPrice"
        spreadhseetData_volumeSheet = "volume"
        spreadhseetData_IndexIHSGSheet = "IndexIHSG"

        % saveDataSetUp
        saveData_filename = "DataInput\PriceVolumeInput.xlsx"
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
        priceChangeLimit = [-0.35, 0.35]
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

            priceVolumeData = loadDataFromYahooFcn (obj.symbols,...
                obj.startDate, obj.endDate, obj.interval, obj.maxRetry);
            
            % transfer value to object
            obj.openPrice = priceVolumeData.openPrice;
            obj.highPrice = priceVolumeData.highPrice;
            obj.lowPrice = priceVolumeData.lowPrice;
            obj.closePrice = priceVolumeData.closePrice;
            obj.volume = priceVolumeData.volume;
            obj.indexIHSG = priceVolumeData.indexIHSG;
        end
        
        function obj = loadDataFromSpreadsheet(obj)
            %loadDataFromSpreadsheet Summary of this method goes here

            % transfer filename and sheetname
            fileName = obj.spreadhseetData_filename; 
            openPriceSheet = obj.spreadhseetData_openPriceSheet; 
            lowPriceSheet = obj.spreadhseetData_lowPriceSheet; 
            highPriceSheet = obj.spreadhseetData_highPriceSheet;
            closePriceSheet = obj.spreadhseetData_closePriceSheet; 
            volumeSheet = obj.spreadhseetData_volumeSheet; 
            indexIHSGSheet = obj.spreadhseetData_IndexIHSGSheet; 
            
            % read table for each price and volume data
            obj.openPrice = readtable(fileName, "Sheet", openPriceSheet);
            obj.highPrice = readtable(fileName, "Sheet", highPriceSheet);
            obj.lowPrice = readtable(fileName, "Sheet", lowPriceSheet);
            obj.closePrice = readtable(fileName, "Sheet", closePriceSheet);
            obj.volume = readtable(fileName, "Sheet", volumeSheet);
            obj.indexIHSG = readtable(fileName, "Sheet", indexIHSGSheet);

        end

        function obj = cleanData(obj)
            %cleanData Summary of this method goes here
            %TODO
            priceVolumeRaw.openPrice = obj.openPrice;
            priceVolumeRaw.highPrice = obj.highPrice;
            priceVolumeRaw.lowPrice = obj.lowPrice;
            priceVolumeRaw.closePrice = obj.closePrice;
            priceVolumeRaw.volume = obj.volume;
            priceVolumeRaw.indexIHSG = obj.indexIHSG;
            
            priceVolumeClean = cleanDataFcn(priceVolumeRaw);
            
            obj.openPrice = priceVolumeClean.openPrice;
            obj.highPrice = priceVolumeClean.highPrice;
            obj.lowPrice = priceVolumeClean.lowPrice;
            obj.closePrice = priceVolumeClean.closePrice;
            obj.volume = priceVolumeClean.volume ;
            obj.indexIHSG = priceVolumeClean.indexIHSG;

            % calculate market cap for each symbol over the time
            marketCap = calculateMarketCapFcn (obj);
            obj.marketCap = marketCap;

            % categorize Mkt Cap
            marketCapCategory = calcMktCapCategoryFcn(obj);
            obj.marketCapCategory = marketCapCategory;

        end

        function obj = saveDataToSpreadsheet(obj)
            %saveDataToSpreadsheet Summary of this method goes here
            
            % write timetable for each price and volume data
            writetimetable(obj.openPrice, "DataInput\PriceVolumeInput.xlsx", "Sheet", "openPrice");
            writetimetable(obj.highPrice, "DataInput\PriceVolumeInput.xlsx", "Sheet", "highPrice");
            writetimetable(obj.lowPrice, "DataInput\PriceVolumeInput.xlsx", "Sheet", "lowPrice");
            writetimetable(obj.closePrice, "DataInput\PriceVolumeInput.xlsx", "Sheet", "closePrice");
            writetimetable(obj.volume, "DataInput\PriceVolumeInput.xlsx", "Sheet", "volume");
            writetimetable(obj.indexIHSG, "DataInput\PriceVolumeInput.xlsx", "Sheet", "indexIHSG");

        end    
    end
end
%==========================================================================
%% Helper functions
%==========================================================================
% calculateMarketCapFcn
function marketCap = calculateMarketCapFcn (inputArgs)
    % calculate market cap for each symbol over the time
    % preallocatte marketCap
    
    marketData = inputArgs;
    symbols = sort(eraseBetween(string(marketData.volume.Properties.VariableNames),5,11)) ;
    timeCol = marketData.volume.Time;
    varType = repmat(["double"], 1,numel(symbols));
    marketCap = timetable('Size', [numel(timeCol), numel(symbols)], 'VariableTypes', varType ,...
        'RowTimes', timeCol, VariableNames=symbols);
    
    for symIdx = 1:numel(symbols)
    
        symbols(symIdx);
        symMarketCapRef = marketData.symMarketCapRef;
        symMarketCapRef.Symbol = string(symMarketCapRef.Symbol);
        symMarketCapRef(symbols==symbols(symIdx),:);
        priceSymIdx = symMarketCapRef(symbols==symbols(symIdx),4).Variables;
        MktCapSymIdx = symMarketCapRef(symbols==symbols(symIdx),5).Variables;
        
        closePrice = marketCap;
        closePrice.Variables = marketData.closePrice.Variables;
        marketCap(:,symIdx).Variables = closePrice(:,symIdx).Variables .* (MktCapSymIdx/priceSymIdx);
    
    end
    
end

%% calcMktCapCategoryFcn
function marketCapCategory = calcMktCapCategoryFcn(inputArg) 
    % calcMktCapCategoryFcn to categorize MktCap
    marketData = inputArg;
    marketCap = marketData.marketCap;
    symbols = sort(eraseBetween(string(marketData.volume.Properties.VariableNames),5,11)) ;
    timeCol = marketData.volume.Time;
    varType = repmat(["string"], 1,numel(symbols));
    marketCapCategory  = timetable('Size', [numel(timeCol), numel(symbols)], 'VariableTypes', varType ,...
        'RowTimes', timeCol, VariableNames=symbols);
    marketCapRangeRef = sortrows(marketData.marketCapRangeRef, "UB","ascend"); 
    UB = marketCapRangeRef.UB;
    edges = sort([UB(:); 0 ],"ascend");
    category = (marketCapRangeRef.CapCategory) ;
    marketCapCategoryVar = discretize(marketCap.Variables, edges, 'categorical', category, 'IncludedEdge','left');
    marketCapCategory.Variables = string(marketCapCategoryVar);

end
