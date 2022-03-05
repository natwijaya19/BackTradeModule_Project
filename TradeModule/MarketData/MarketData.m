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
    %   cleanMktData
    %   saveDataToSpreadsheet

    %------------------------------------------------------------------------
    %% Properties section
    %------------------------------------------------------------------------
    properties
        % YahooDataSetUp
        yahooDataSetUp YahooDataSetUp = YahooDataSetUp;

        % SpreadsheetSetUp
        spreadSheetSetUp SpreadSheetSetUp = SpreadSheetSetUp;

        % MatFileSetUp
        matFileSetUp MatFileSetUp = MatFileSetUp;
        % data properties
        priceVolumeData
        nDay {mustBeInteger, mustBePositive} = 250*6

    end

    properties (SetAccess = private)
        symbols
        indexIHSG
        marketCap
        marketCapCategory
        symMarketCapRef
        marketCapRangeRef
    end

    properties (Constant)
        exhangeName = "JK"
        priceChangeLimit = [-0.35, 0.35]
        nDayPerYear = 252
    end

    %------------------------------------------------------------------------
    %% Methods section
    %==========================================================================
    methods


        function obj = MarketData (yahooDataSetUp, spreadSheetSetUp, matFileSetUp)
            % MarketData object constructor
            obj.yahooDataSetUp = yahooDataSetUp;
            obj.spreadSheetSetUp = spreadSheetSetUp;
            obj.matFileSetUp = matFileSetUp;

        end

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

            [priceVolume, index] = loadDataFromYahooFcn (obj.symbols,...
                startDate, endDate, interval, maxRetry);

            % transfer value to object
            obj.priceVolumeData = priceVolume;
            obj.indexIHSG = index;

        end

        %-------------------------------------------------------------------------
%         function obj = loadDataFromSpreadsheet(obj)
%             %loadDataFromSpreadsheet Summary of this method goes here
% 
%             % transfer filename and sheetname
%             %TODO refactor to use cell array
%             path  = obj.spreadSheetSetUp.path;
%             fileName = obj.spreadSheetSetUp.fileName;
%             fullFileName = fullfile(path, fileName);
% 
%             openPriceSheet = obj.spreadSheetSetUp.openPriceSheet;
%             lowPriceSheet = obj.spreadSheetSetUp.lowPriceSheet;
%             highPriceSheet = obj.spreadSheetSetUp.highPriceSheet;
%             closePriceSheet = obj.spreadSheetSetUp.closePriceSheet;
%             volumeSheet = obj.spreadSheetSetUp.volumeSheet;
%             indexIHSGSheet = obj.spreadSheetSetUp.IndexIHSGSheet;
% 
%             % read table for each price and volume data
%             obj.openPrice = readtimetable(fullFileName, "Sheet", openPriceSheet);
%             obj.highPrice = readtimetable(fullFileName, "Sheet", highPriceSheet);
%             obj.lowPrice = readtimetable(fullFileName, "Sheet", lowPriceSheet);
%             obj.closePrice = readtimetable(fullFileName, "Sheet", closePriceSheet);
%             obj.volume = readtimetable(fullFileName, "Sheet", volumeSheet);
%             obj.indexIHSG = readtimetable(fullFileName, "Sheet", indexIHSGSheet);
% 
%         end

        %-------------------------------------------------------------------------
        function obj = loadDataFromMatFile(obj)
            % transfer filename and sheetname
            path = obj.matFileSetUp.path;
            fileName = obj.matFileSetUp.fileName;
            fullFileName = fullfile(path, fileName);
            matObj = matfile(fullFileName);

            dataName = ["openPrice", "highPrice", "lowPrice", "closePrice", "volume"];
            dataRaw = cell(1,numel(dataName));

            dataRaw{1} = matObj.openPrice;
            dataRaw{2} = matObj.highPrice;
            dataRaw{3} = matObj.lowPrice;
            dataRaw{4} = matObj.closePrice;
            dataRaw{5} = matObj.volume;

            obj.priceVolumeData = dataRaw;


        end

        %-------------------------------------------------------------------------
        function obj = cleanMktData(obj)
            %cleanData Summary of this method goes here
            %TODO
            priceVolumeRaw = obj.priceVolumeData;
            priceVolumeRaw.indexIHSG = obj.indexIHSG;
            symbols = obj.symbols;

            priceVolumeClean = cleanDataFcn(priceVolumeRaw, symbols);

            obj.priceVolumeData = priceVolumeClean.openPrice;

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

            %TODO refactor to use cell array
            openPrice = obj.priceVolumeData.openPrice;
            highPrice = obj.priceVolumeData.highPrice;
            lowPrice = obj.priceVolumeData.lowPrice;
            closePrice = obj.priceVolumeData.closePrice;
            volume = obj.priceVolumeData.volume;

            save(fullFileName, "openPrice", "highPrice", "lowPrice", "closePrice", "volume")


        end

        %-------------------------------------------------------------------------
        function saveDataToSpreadsheet(obj)
            %saveDataToSpreadsheet Summary of this method goes here

            path  = "C:\Users\kikim\OneDrive\Documents\MATLAB_Projects\BackTradeModule_Project_WFA_Feature_Development\DataInput";
            fileName = "PriceVolumeInput.xlsx";
            fullFileName = fullfile(path, fileName);

            openPrice = obj.priceVolumeData.openPrice;
            highPrice = obj.priceVolumeData.highPrice;
            lowPrice = obj.priceVolumeData.lowPrice;
            closePrice = obj.priceVolumeData.closePrice;
            volume = obj.priceVolumeData.volume;

            %TODO refactor to use cell array
            % write timetable for each price and volume data
            writetimetable(openPrice, fullFileName, 'Sheet', 'openPrice');
            writetimetable(highPrice, fullFileName, "Sheet", "highPrice");
            writetimetable(lowPrice, fullFileName, "Sheet", "lowPrice");
            writetimetable(closePrice, fullFileName, "Sheet", "closePrice");
            writetimetable(volume, fullFileName, "Sheet", "volume");
            writetimetable(obj.indexIHSG, fullFileName, "Sheet", "indexIHSG");

        end

    end

end
%==========================================================================
%% Helper functions
%==========================================================================
% calculateMarketCapFcn
function marketCap = calculateMarketCapFcn (marketData)
% calculate market cap for each symbol over the time

% clean the pricevolume data
symMarketCapRef = marketData.symMarketCapRef;
dataRaw = marketData.priceVolumeData;
priceVolumeData = cleanDataFcn(dataRaw);

% preallocatte marketCap
closePrice = priceVolumeData{4};
marketCap = closePrice;
symbols = string(closePrice.Properties.VariableNames);
symbols = strrep(symbols, "_price","");
marketCap.Properties.VariableNames = sort(symbols);
marketCap.Variables = zeros(size(marketCap.Variables));

for symIdx = 1:numel(symbols)

    symbols(symIdx);
    symMarketCapRef.Symbol = string(symMarketCapRef.Symbol);
    symMarketCapRef(symbols==symbols(symIdx),:);
    priceSymIdx = symMarketCapRef(symbols==symbols(symIdx),4).Variables;
    MktCapSymIdx = symMarketCapRef(symbols==symbols(symIdx),5).Variables;
    
    marketCap(:,symIdx).Variables = closePrice(:,symIdx).Variables .* (MktCapSymIdx/priceSymIdx);

end

clearvars -except marketCap

end

%---------------------------------------------------------------------------
%% calcMktCapCategoryFcn
function marketCapCategory = calcMktCapCategoryFcn(marketData)
% calcMktCapCategoryFcn to categorize MktCap

% prepare the dataInput
marketCap = marketData.marketCap;
priceVolumeData = marketData.priceVolumeData;
marketCapRangeRef = marketData.marketCapRangeRef;
volume = priceVolumeData{5};

symbols = sort(strrep(string(volume.Properties.VariableNames),"_volume","")) ;
timeCol = volume.Time;
varType = repmat({'string'}, 1,numel(symbols));
marketCapCategory  = timetable('Size', [numel(timeCol), numel(symbols)],...
    'VariableTypes', varType ,'RowTimes', timeCol, 'VariableNames', symbols);

marketCapRangeRef = sortrows(marketCapRangeRef, "UB","ascend");
UB = marketCapRangeRef.UB;
edges = sort([UB(:); 0 ],"ascend");
category = (marketCapRangeRef.CapCategory) ;

marketCapCategoryVar = discretize(marketCap.Variables, edges,...
    'categorical', category, 'IncludedEdge','left');

% wrap up the output
marketCapCategory.Variables = string(marketCapCategoryVar);

% end of function
clearvars -except marketCapCategory

end

% END
%========================================================================