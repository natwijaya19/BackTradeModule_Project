
%% start over workspace
clear
clc
close all

%========================================================================

%% load data from yahoo
% 
% marketData = MarketData;
% marketData.yahooDataSetUp.startDate = datetime("01-Jan-2010");
% marketData.yahooDataSetUp;
% 
% marketData = marketData.loadSymbolMCapRef;
% marketData = marketData.loadDataFromYahoo;
% 
% marketData.matFileSetUp.fileName = "DataInput\PriceVolumeInput2010to2022Raw.mat";
% marketData.saveDataToMatFile

%========================================================================

%% load data from matfile
matObj = matfile("DataInput\PriceVolumeInput2010to2022Raw.mat");

dataName = ["openPrice", "highPrice", "lowPrice", "closePrice", "volume"];
dataRaw = cell(1,numel(dataName));
dataRaw{1} = matObj.openPrice;
dataRaw{2} = matObj.highPrice;
dataRaw{3} = matObj.lowPrice;
dataRaw{4} = matObj.closePrice;
dataRaw{5} = matObj.volume;

%========================================================================

%% data for input
nRowPerYear = 250;
nRow = nRowPerYear*6-1;
nData = numel(dataRaw);

%prellocate
dataInputRaw = cell(1,nData);

for idx = 1:nData
    dataInputRaw{idx} = dataRaw{idx}(end-nRow:end,:);
end

%========================================================================

%% clean data
dataClnRaw = dataInputRaw;
dataClean = cleanDataFcn(dataClnRaw);

clearvars dataClnRaw

%========================================================================
% generate tradeSignal
% dummy paramInput
paramInput = [
    40  %1
    200 %2
    5   %3
    5   %4
    10  %5
    8   %6
    120 %7
    20  %8
    5   %9
    8   %10
    5   %11
    ];

dataInput = dataClean;
tradeSignal = tradeSignalShortMomFcn(paramInput, dataInput) ;

% check
signal = sum(tradeSignal.Variables,2);

% backtest the signal
dataInputBT = dataInput;
tradeSignalInput = tradeSignal;
backShiftNDay = 1;
tradingCost = [0.15, 0.25] ./100;
maxCapAllocation = 0.1;

resultStruct = btEngineVectFcn (dataInputBT, tradeSignalInput, backShiftNDay, tradingCost, maxCapAllocation);

% visualize the performance
tiledlayout(2,1)
equityCurvePortfolio = resultStruct.equityCurvePortfolioTT.Variables;

nexttile
semilogy(equityCurvePortfolio)
title("equityCurvePortfolio")

nexttile
barFig = bar(signal);
title("tradeSignal")

endPortVal = equityCurvePortfolio(end,:)
maxDD = maxdrawdown(resultStruct.equityCurvePortfolioTT.Variables)

%========================================================================

%% setUp WFA
% setUpParam
wfaSetUpParam = WFASetUpParam

% loadData


% prepare WFA


%========================================================================

%% runWFA
%for each walk and each symbol group, 
% runWFA
% optimize parameters in runIST
% evaluate performance in runOST
% evaluate performance
% save the input parameters and WFA results

%========================================================================


