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
        yahooData_path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
        yahooData_fileName = "Symbols_MarketCap_MarketCapCategoryRange.xlsx";
        yahooData_symMktCapSheetName = "SymbolsMarketCapReference"
        yahooData_mktCapCategRangeSheet = "MarketCap_Category_Range"
        startDate = datetime("1-Jan-2014")
        endDate = datetime("today")
        interval = "1d"
        maxRetry = 3;
        
        % SpreadsheetDataLoadSetUp
        spreadhseetData_filename = "PriceVolumeInput.xlsx"
        spreadhseetData_path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput"
        spreadhseetData_openPriceSheet = "openPrice"
        spreadhseetData_lowPriceSheet = "lowPrice"
        spreadhseetData_highPriceSheet = "highPrice"
        spreadhseetData_closePriceSheet = "closePrice"
        spreadhseetData_volumeSheet = "volume"
        spreadhseetData_IndexIHSGSheet = "IndexIHSG"

        % saveDataSetUp
%         saveData_filename = "PriceVolumeInput.xlsx"
%         saveData_path = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project\DataInput"
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
%==========================================================================
    methods

        function obj = loadSymbolMCapRef(obj)
            %loadSymbolMCapRef Summary of this method goes here

            fileName = obj.yahooData_fileName;
            sheetNameSymCap = obj.yahooData_symMktCapSheetName;
            sheetNamecaptCategRange = obj.yahooData_mktCapCategRangeSheet;

            obj.symMarketCapRef = readtable(fileName, Sheet=sheetNameSymCap);
            obj.marketCapRangeRef = readtable(fileName, Sheet=sheetNamecaptCategRange);
            symbols = string(obj.symMarketCapRef.Symbol);
            obj.symbols = sort(symbols, "ascend");           
        end

%-------------------------------------------------------------------------
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

%-------------------------------------------------------------------------        
        function obj = loadDataFromSpreadsheet(obj)
            %loadDataFromSpreadsheet Summary of this method goes here

            % transfer filename and sheetname

            path  = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
            fileName = "PriceVolumeInput.xlsx";            

            % fileName = obj.spreadhseetData_filename; 
            % path = obj.spreadhseetData_path;
            fullFileName = fullfile(path, fileName);

            openPriceSheet = obj.spreadhseetData_openPriceSheet; 
            lowPriceSheet = obj.spreadhseetData_lowPriceSheet; 
            highPriceSheet = obj.spreadhseetData_highPriceSheet;
            closePriceSheet = obj.spreadhseetData_closePriceSheet; 
            volumeSheet = obj.spreadhseetData_volumeSheet; 
            indexIHSGSheet = obj.spreadhseetData_IndexIHSGSheet; 
            
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

            path  = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
            fileName = "PriceVolumeInput.mat";    
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

            % calculate market cap for each symbol over the time
            marketCap = calculateMarketCapFcn (obj);
            obj.marketCap = marketCap;

            % categorize Mkt Cap
            marketCapCategory = calcMktCapCategoryFcn(obj);
            obj.marketCapCategory = marketCapCategory;

        end
        
%-------------------------------------------------------------------------
    
        function saveDataToMatFile (obj)
            path  = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
            fileName = "PriceVolumeInput.mat";
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
    symbols = sort(eraseBetween(string(marketData.volume.Properties.VariableNames),5,11)) ;
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