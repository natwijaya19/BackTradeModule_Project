
%% setUp WFA
clear
clc
close all

%% wfaSetUpParam
wfaSetUpParam = WFASetUpParam;
wfaSetUpParam = wfaSetUpParam.prepare;

%========================================================================

%% prepare marketData
yahooDataSetUp = YahooDataSetUp;
spreadSheetSetUp = SpreadSheetSetUp;
matFileSetUp = MatFileSetUp;
marketData = MarketData(yahooDataSetUp, spreadSheetSetUp, matFileSetUp);

marketData = marketData.loadSymbolMCapRef;
marketData = marketData.loadDataFromMatFile

%========================================================================

%% data for input
nRow = marketData.nDay-1;

% transfer the priceVolumeData
dataRaw = marketData.priceVolumeData;
nData = numel(dataRaw);

%preallocate
dataInputRaw = cell(1,nData);

for idx = 1:nData
    dataInputRaw{idx} = dataRaw{idx}(end-nRow:end,:);
end

marketData.priceVolumeData = dataInputRaw;
clearvars dataRaw dataInputRaw

% classifyMktCap
marketData = marketData.classifyMktCap

%========================================================================

%% setUpParam
wfaSetUpParam = WFASetUpParam;
wfaSetUpParam = wfaSetUpParam.prepare

%========================================================================

%% prepare WFA

WfaEngine = WFAEngine(wfaSetUpParam)

%========================================================================

%% runWFA

script_wfaOptimParamFcn

% runWFA for each walk and each symbol group

% optimize parameters in runIST

% evaluate performance in runOST

% animated equityCurve

% save the input parameters and WFA results

% visualize performance summary
%   summary table
%   animated plot of nSignalDaily and equityCurve


%========================================================================
%% 

figure
tiledlayout(2,2)

%tile [1,1]
nexttile
equityCurvePortfolioTrain = wfaOptimStructOut.btResultTrainSet.equityCurvePortfolioTT;
timeCol = equityCurvePortfolioTrain.Time;
trainPlot = semilogy(timeCol, equityCurvePortfolioTrain.Variables);
title("equityCurvePortfolioTrainSet")
% axis([timeCol(1) timeCol(end)])

%tile [1,2]
nexttile
equityCurvePortfolioTest = wfaOptimStructOut.btResultTestSet.equityCurvePortfolioTT;
timeCol = equityCurvePortfolioTest.Time;
testPlot = plot(timeCol , equityCurvePortfolioTest.Variables);
title("equityCurvePortfolioTestSet")
% axis([timeCol(1) timeCol(end)])

%tile [2,1]
nexttile
tradingSignalTrainSet = wfaOptimStructOut.tradingSignalTrainSet;
nDailyTradingSignalTrain = sum(tradingSignalTrainSet.Variables,2);
trainBar = bar(nDailyTradingSignalTrain);
title("nDailyTradingSignalTrain")

%tile [2,2]
nexttile
tradingSignalTestSet = wfaOptimStructOut.tradingSignalTestSet;
nDailyTradingSignalTest = sum(tradingSignalTestSet.Variables,2);
testBar = bar(nDailyTradingSignalTest);
title("nDailyTradingSignalTest")

maxDDTrainSet = maxdrawdown(equityCurvePortfolioTrain.Variables)
maxDDTestSet = maxdrawdown(equityCurvePortfolioTest.Variables)
