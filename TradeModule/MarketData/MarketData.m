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
        % YahooDataSetUp
        yahooDataSetUp = YahooDataSetUp;
        
        % SpreadsheetSetUp
        spreadSheetSetUp = SpreadSheetSetUp;
        
        % MatFileSetUp
        matFileSetUp = MatFileSetUp;

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
%==========================================================================
    methods

        function obj = loadSymbolMCapRef(obj)
            %loadSymbolMCapRef Summary of this method goes here

            path = obj.yahooDataSetUp.path; 
            fileName = obj.yahooDataSetUp.fileName;
            fullFileName = fullfile(path, fileName);
            sheetNameSymCap = obj.yahooDataSetUp.symMktCapSheetName;
            sheetNameCaptCategRange = obj.yahooDataSetUp.mktCapCategRangeSheet;

            obj.symMarketCapRef = readtable(fullFileName, 'Sheet', sheetNameSymCap);
            obj.marketCapRangeRef = readtable(fullFileName, 'Sheet', sheetNameCaptCategRange);
            sym = string(obj.symMarketCapRef.Symbol);
            obj.symbols = sort(sym, "ascend");           
        end

%-------------------------------------------------------------------------
        function obj = loadDataFromYahoo(obj)
            %loadDataFromYahoo Summary of this method goes here
            startDate = obj.yahooDataSetUp.startDate;
            endDate = obj.yahooDataSetUp.endDate;
            interval = obj.yahooDataSetUp.interval;
            maxRetry = obj.yahooDataSetUp.maxRetry;
            
            priceVolumeData = loadDataFromYahooFcn (obj.symbols,...
                startDate, endDate, interval, maxRetry);
            
            % transfer value to object
            obj.openPrice = priceVolumeData.openPrice;
            obj.highPrice = priceVolumeData.highPrice;
            obj.lowPrice = priceVolumeData.lowPrice;
            obj.closePrice = priceVolumeData.closePrice;
            obj.volume = priceVolumeData.volume;
            obj.indexIHSG = priceVolumeData.indexIHSG;
            
        end

%-------------------------------------------------------------------------        
        function obj = loadDataFromSpreadsheet(obj)
            %loadDataFromSpreadsheet Summary of this method goes here

            % transfer filename and sheetname

            path  = obj.spreadSheetSetUp.path;
            fileName = obj.spreadSheetSetUp.fileName;            
            fullFileName = fullfile(path, fileName);

            openPriceSheet = obj.spreadSheetSetUp.openPriceSheet; 
            lowPriceSheet = obj.spreadSheetSetUp.lowPriceSheet; 
            highPriceSheet = obj.spreadSheetSetUp.highPriceSheet;
            closePriceSheet = obj.spreadSheetSetUp.closePriceSheet; 
            volumeSheet = obj.spreadSheetSetUp.volumeSheet; 
            indexIHSGSheet = obj.spreadSheetSetUp.IndexIHSGSheet; 
            
            % read table for each price and volume data
            obj.openPrice = readtimetable(fullFileName, "Sheet", openPriceSheet);
            obj.highPrice = readtimetable(fullFileName, "Sheet", highPriceSheet);
            obj.lowPrice = readtimetable(fullFileName, "Sheet", lowPriceSheet);
            obj.closePrice = readtimetable(fullFileName, "Sheet", closePriceSheet);
            obj.volume = readtimetable(fullFileName, "Sheet", volumeSheet);
            obj.indexIHSG = readtimetable(fullFileName, "Sheet", indexIHSGSheet);

        end

%-------------------------------------------------------------------------
        function obj = loadDataFromMatFile(obj)
           % transfer filename and sheetname
            path = obj.matFileSetUp.path;
            fileName = obj.matFileSetUp.fileName;
            fullFileName = fullfile(path, fileName);
            priceVolume = load(fullFileName);
            obj.openPrice = priceVolume.openPrice;
            obj.highPrice = priceVolume.highPrice;
            obj.lowPrice = priceVolume.lowPrice;
            obj.closePrice = priceVolume.closePrice;
            obj.volume = priceVolume.volume;
%             obj.indexIHSG = priceVolume.indexIHSG;

        end

%-------------------------------------------------------------------------
        function obj = cleanData(obj)
            %cleanData Summary of this method goes here
            %TODO
            priceVolumeRaw.openPrice = obj.openPrice;
            priceVolumeRaw.highPrice = obj.highPrice;
            priceVolumeRaw.lowPrice = obj.lowPrice;
            priceVolumeRaw.closePrice = obj.closePrice;
            priceVolumeRaw.volume = obj.volume;
            priceVolumeRaw.indexIHSG = obj.indexIHSG;
            symbols = obj.symbols;
            
            priceVolumeClean = cleanDataFcn(priceVolumeRaw, symbols);
            
            obj.openPrice = priceVolumeClean.openPrice;
            obj.highPrice = priceVolumeClean.highPrice;
            obj.lowPrice = priceVolumeClean.lowPrice;
            obj.closePrice = priceVolumeClean.closePrice;
            obj.volume = priceVolumeClean.volume ;

        end
        
        %-------------------------------------------------------------------------

        function obj = classifyMktCap(obj)
            % calculate market cap for each symbol over the time
            obj.marketCap = calculateMarketCapFcn (obj);

            % classify Mkt Cap
            obj.marketCapCategory = calcMktCapCategoryFcn(obj);
            
        end
        function saveDataToMatFile (obj)
            path  = obj.matFileSetUp.path;
            fileName = obj.matFileSetUp.fileName;
            fullFileName = fullfile(path, fileName);

            openPrice = obj.openPrice;
            highPrice = obj.highPrice;
            lowPrice = obj.lowPrice;
            closePrice = obj.closePrice;
            volume = obj.volume;
            indexIHSG = obj.indexIHSG;

        save(fullFileName, "openPrice", "highPrice", "lowPrice", "closePrice", "volume")


        end

%-------------------------------------------------------------------------
        function saveDataToSpreadsheet(obj)
            %saveDataToSpreadsheet Summary of this method goes here

            path  = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
            fileName = "PriceVolumeInput.xlsx";            
            fullFileName = fullfile(path, fileName);

            % write timetable for each price and volume data
            writetimetable(obj.openPrice, fullFileName, 'Sheet', 'openPrice');
            writetimetable(obj.highPrice, fullFileName, "Sheet", "highPrice");
            writetimetable(obj.lowPrice, fullFileName, "Sheet", "lowPrice");
            writetimetable(obj.closePrice, fullFileName, "Sheet", "closePrice");
            writetimetable(obj.volume, fullFileName, "Sheet", "volume");
            writetimetable(obj.indexIHSG, fullFileName, "Sheet", "indexIHSG");

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
    symbols = string(marketData.volume.Properties.VariableNames);
    symbols = strrep(symbols, "_volume","");
    symbols = sort(symbols) ;
    timeCol = marketData.volume.Time;
    varType = repmat(["double"], 1,numel(symbols));
    marketCap = timetable('Size', [numel(timeCol), numel(symbols)],...
        'VariableTypes', varType , 'RowTimes', timeCol, 'VariableNames', symbols);
    
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

%---------------------------------------------------------------------------
%% calcMktCapCategoryFcn
function marketCapCategory = calcMktCapCategoryFcn(inputArg) 
    % calcMktCapCategoryFcn to categorize MktCap
    marketData = inputArg;
    marketCap = marketData.marketCap;
    symbols = sort(eraseBetween(string(marketData.volume.Properties.VariableNames),5,11)) ;
    timeCol = marketData.volume.Time;
    varType = repmat(["string"], 1,numel(symbols));
    marketCapCategory  = timetable('Size', [numel(timeCol), numel(symbols)],...
        'VariableTypes', varType ,'RowTimes', timeCol, 'VariableNames', symbols);
    marketCapRangeRef = sortrows(marketData.marketCapRangeRef, "UB","ascend"); 
    UB = marketCapRangeRef.UB;
    edges = sort([UB(:); 0 ],"ascend");
    category = (marketCapRangeRef.CapCategory) ;
    marketCapCategoryVar = discretize(marketCap.Variables, edges,...
        'categorical', category, 'IncludedEdge','left');
    marketCapCategory.Variables = string(marketCapCategoryVar);

end

% END
%========================================================================