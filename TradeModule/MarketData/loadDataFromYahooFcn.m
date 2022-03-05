function [priceVolumeData, indexIHSG] = loadDataFromYahooFcn(symbols, startDate, endDate, interval, maxRetry)

%%loadMarketDataFromYahoo

% assume symbols array contain some invalid symbols.
% required data
%   - list of symbols >> should be string array
%   - startDate
%   - nYearPeriod
%   - endDate
%   - interval >> interval day period
%   - maxRetry >> for error handling



%-----------------------------------------------------------------------------------------------


% get nRow from sampleData
symbols = sort(symbols,"ascend");
sampleSymbol = 'BBCA.JK';

% sample data for preallocation TT in loop
sampleData = getMarketDataViaYahoo(char(sampleSymbol), startDate, endDate, interval);
sampleData = table2timetable(sampleData);
sampleVarName = sampleData.Properties.VariableNames;
timeCol = sampleData.Date;
[nRowSampleData, nColSampleData] = size(sampleData);
sampleVariableTypes = repmat({'double'}, 1, nColSampleData);

TT = timetable('Size', size(sampleData), 'VariableTypes', sampleVariableTypes, 'RowTimes', timeCol,...
    'VariableNames', sampleVarName);

TT.Variables = nan(nRowSampleData, nColSampleData);

% preallocation for preallocation dataTT in loop. dataTT in created to
% maintain nSymbols in output and input price volume data

nSymbols = numel(symbols);
nRow = nRowSampleData;
sz = [nRow, nSymbols];
varSample = zeros(nRow,nSymbols);
variableTypes = {'double'};
varName = symbols;


dataTT = timetable('Size', [nRow,1], 'VariableTypes', variableTypes , 'RowTimes', timeCol, ...
    'VariableNames', "preallocation");


% preallocation for each price volume data
openPriceTT = dataTT;
highPriceTT = dataTT;
lowPriceTT = dataTT;
closePriceTT = dataTT;
volumeTT = dataTT;

% looping through all symbol
waitbarFig = waitbar(0, "Downloading data from yahoo");
progressCounter = 1:25:nSymbols;

for Idx = 1: nSymbols
    waitbar(Idx/nSymbols, waitbarFig, "Downloading data from yahoo");
    symi = strcat(symbols(Idx), ".JK");

    % progressCounter
    if ismember(Idx, progressCounter)
        disp(strcat(string(Idx)," ", string(symi)))
    end

    dataIdx = tryGetMarketDataViaYahoo(symi, startDate, endDate, interval, maxRetry);
    if isempty(dataIdx)
        dataIdx = TT;
    end
    % Synchronize price and volume data
    openPriceTT = synchronize (openPriceTT, dataIdx(:,1)) ;
    highPriceTT = synchronize (highPriceTT, dataIdx(:,2));
    lowPriceTT = synchronize (lowPriceTT, dataIdx(:,3));
    closePriceTT = synchronize (closePriceTT, dataIdx(:,4));
    volumeTT = synchronize (volumeTT, dataIdx(:,6));

    % replace name with symi
    openPriceTT.Properties.VariableNames(end) = symi;
    highPriceTT.Properties.VariableNames(end) = symi;
    lowPriceTT.Properties.VariableNames(end) = symi;
    closePriceTT.Properties.VariableNames(end) = symi;
    volumeTT.Properties.VariableNames(end) = symi;

end

% remove preallocation column
openPriceTT.preallocation = [];
highPriceTT.preallocation = [];
lowPriceTT.preallocation = [];
closePriceTT.preallocation = [];
volumeTT.preallocation = [];


% load indexIHSG
indexIHSGSymbol = '^JKSE';

indexIHSG = tryGetMarketDataViaYahoo(indexIHSGSymbol, startDate,...
    endDate, interval, maxRetry);
if isempty(indexIHSG)
    indexIHSG = TT;
end

% replace string .JK from each symbol name with _open, _high, _low, _close
% and _volume
openPriceVar = openPriceTT.Properties.VariableNames;
highPriceVar = highPriceTT.Properties.VariableNames;
lowPriceVar = lowPriceTT.Properties.VariableNames;
closePriceVar = closePriceTT.Properties.VariableNames;
volumeVar = volumeTT.Properties.VariableNames;

openPriceVar = strrep(string(openPriceVar), ".JK", "_open");
highPriceVar  = strrep(string(highPriceVar), ".JK", "_high");
lowPriceVar = strrep(string(lowPriceVar), ".JK", "_low");
closePriceVar = strrep(string(closePriceVar), ".JK", "_close");
volumeVar = strrep(string(volumeVar), ".JK", "_volume");

openPriceTT.Properties.VariableNames = openPriceVar ;
highPriceTT.Properties.VariableNames = highPriceVar ;
lowPriceTT.Properties.VariableNames = lowPriceVar ;
closePriceTT.Properties.VariableNames = closePriceVar ;
volumeTT.Properties.VariableNames = volumeVar ;

%% wrap up for the output
% populate data results to PriceVolumeContainer class object
priceVolumeData = cell(1,5);
openPrice = openPriceTT;
highPrice = highPriceTT;
lowPrice = lowPriceTT;
closePrice = closePriceTT;
volume = volumeTT;

% put the price volume
priceVolumeData{1} = openPrice;
priceVolumeData{2} = highPrice;
priceVolumeData{3} = lowPrice;
priceVolumeData{4} = closePrice;
priceVolumeData{5} = volume;

% output
indexIHSG;
priceVolumeData;

%=========================================================================

%% end of function    

clearvars -except priceVolumeOut

end 