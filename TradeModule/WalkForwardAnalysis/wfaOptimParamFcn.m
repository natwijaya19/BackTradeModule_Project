% function wfaOptimStructOut = wfaOptimParamFcn(marketData, wfaSetUpParam)
tic
%wfaOptimParamFcn Summary of this function goes here
%   Detailed explanation goes here
% Input arguments
% - dataInput contains timetables of openPrice, highPrice, lowPrice, closePrice, volume and mktCapCategory
% - wfaSetUpParam
% -

% Output arguments:
% A struct containing tables of :
% - optimTradingSignalParam
% - optimCumRetAtTrainData
% - exitflagAtTrainData
% - wfaSetUpParam

%=========================================================================
%% prepare the input parameters
% transfer wfaSetUpParam values
% WFA specific set up
nWalk = wfaSetUpParam.nWalk ; % Number of walk for the whole walk forwad
lookbackUB = wfaSetUpParam.lookbackUB; % lookback upper bound
nstepTrain = wfaSetUpParam.nstepTrain; % Number of step for training datastasket
nstepTest = wfaSetUpParam.nstepTest; % Number of step for testing dataset

% btEngineSetUp
tradingCost = wfaSetUpParam.tradingCost;
maxCapAllocation = wfaSetUpParam.maxCapAllocation;

% optimization set up
optimLookbackStep = wfaSetUpParam.nstepTrain;
maxFcnEval = wfaSetUpParam.maxFcnEval;
lbubConst = wfaSetUpParam.lbubConst;

nlConstParam.maxDDThreshold  = wfaSetUpParam.maxDDThreshold;
nlConstParam.minPortRet = wfaSetUpParam.minPortRet;
nlConstParam.minDailyRetThreshold = wfaSetUpParam.minDailyRetThreshold;
nlConstParam.Last20DRetThreshold = wfaSetUpParam.minLast20DRetThreshold;
nlConstParam.Last60DRetThreshold = wfaSetUpParam.minLast60DRetThreshold;
nlConstParam.Last200DRetThreshold = wfaSetUpParam.minLast200DRetThreshold;


% number of required nDataRow
nstepWalk = nWalk*nstepTest + lookbackUB + nstepTrain;
additionalData = nstepTest; % additional data for safety required data
nDataRowRequired = nstepWalk+additionalData;
%-------------------------------------------------------------------------

%% prepare data for for WFA
dataInput.openPrice = marketData.openPrice(end-nDataRowRequired+1:end,:);
dataInput.highPrice = marketData.highPrice(end-nDataRowRequired+1:end,:);
dataInput.lowPrice = marketData.lowPrice(end-nDataRowRequired+1:end,:);
dataInput.closePrice = marketData.closePrice(end-nDataRowRequired+1:end,:);
dataInput.volume = marketData.volume(end-nDataRowRequired+1:end,:);
dataInput.marketCapCategory = marketData.marketCapCategory(end-nDataRowRequired+1:end,:);

% Number of rows in raw data
nRowDataAvailable = size (marketData.openPrice,1) ;

% nRowDataAvailable must be larger than nDataRowRequired
validIF = nRowDataAvailable < nDataRowRequired;

if validIF
    error(message('finance:WFA:nRowDataAvailable must be larger than nDataRowRequired'));
end

clearvars marketData
%-------------------------------------------------------------------------

%% marking idx step for each walk
% idx for start and end of test steps
nDataRowRequired = size(dataInput.openPrice,1);
lastEndStepTest = nDataRowRequired;
lastStartStepTest = lastEndStepTest - nstepTest +1;
firstEndStepTest = lastEndStepTest - (nWalk-1)*nstepTest;
firstStartStepTest = firstEndStepTest - nstepTest +1;

endStepTest = firstEndStepTest:nstepTest:lastEndStepTest;
startStepTest= endStepTest - nstepTest +1;

% idx for start and end of train steps
endStepTrain = startStepTest-1;
startStepTrain = endStepTrain - nstepTrain+1;

% idx for start and end of lookback steps
endStepLookback = startStepTrain-1;
startStepLookback = endStepLookback - lookbackUB+1;


% determine index and timecolumn for each step and walk
timeCol = dataInput.openPrice.Time;
nRow = numel(timeCol);
%-------------------------------------------------------------------------

%% prepare market cap category for loop to get the list of symbols at each EndStepTrainIdx for each
% mktCapCategory
marketCapCategory = dataInput.marketCapCategory;
uniqueMktCap = unique(marketCapCategory.Variables);
uniqueMktCap(ismissing(uniqueMktCap)) = [];
uniqueMktCap= sort(uniqueMktCap);
mktCapList = uniqueMktCap;

symbols = marketCapCategory.Properties.VariableNames;

mCapEndStepTrainIdx = marketCapCategory(endStepTrain,:);
mCapEndStepTrainIdxVar = mCapEndStepTrainIdx.Variables;

% preallocate tradingSignalTrainSet
timeCol = dataInput.openPrice.Time;
timeColSignalTrainSet = timeCol(startStepTrain(1):endStepTrain(end));
openPrice = dataInput.openPrice;
tradingSignalTrainSet = openPrice(timeColSignalTrainSet,:);
tradingSignalTrainSet.Variables = zeros(size(tradingSignalTrainSet));
tradingSignalTrainSet.Properties.VariableNames = strrep(tradingSignalTrainSet.Properties.VariableNames,"_open","");

% preallocate tradingSignalTestSet
timeCol = dataInput.openPrice.Time;
timeColSignalTestSet = timeCol(startStepTest(1):endStepTest(end));
openPrice = dataInput.openPrice;
tradingSignalTestSet = openPrice(timeColSignalTestSet,:);
tradingSignalTestSet.Variables = zeros(size(tradingSignalTestSet));
tradingSignalTestSet.Properties.VariableNames = strrep(tradingSignalTestSet.Properties.VariableNames,"_open","");

%-------------------------------------------------------------------------

%% preallocate optimizedSignalParam for each startTrainStepIdx and marketCapCategory
tradingSignalParamVarName = [
    "liquidityVolumeMALookback";
    "liquidityVolumeMAThreshold";
    "liquidityVolumeMANDayBuffer";
    "liquidityValueMALookback";
    "liquidityValueMAThreshold";
    "liquidityValueMANDayBuffer";
    "liquidityNDayVolumeValueBuffer";
    "momentumPriceMALookback";
    "momentumPriceMAToCloseThreshold";
    "momentumPriceRetLowToCloseLookback";
    "momentumPriceRetLowToCloseThreshold";
    "momentumPriceRetLowToCloseNDayBuffer";
    "liquidityMomentumSignalBuffer";
    "cutLossHighToCloseNDayLookback";
    "cutLossHighToCloseMaxPct";
    "nDayBackShift"];


nCol = numel(uniqueMktCap) * numel(tradingSignalParamVarName);
nRow = nWalk;
varTypes = repmat({'double'},1,nCol);
sz = [nRow, nCol];
timeCol = marketCapCategory(endStepTrain,:).Time;

optimTradingSignalParam = timetable('Size', sz, 'VariableTypes', varTypes,...
    'RowTimes', timeCol);

optimTradingSignalParamVarNames = optimTradingSignalParam.Properties.VariableNames;

step = numel(tradingSignalParamVarName);
startTradingParamIdx = 1:step:nCol;
endTradingParamIdx = (startTradingParamIdx + step)-1;

for idx = 1:numel(uniqueMktCap)

    mCapIdx = string(uniqueMktCap(idx));
    mCapIdx = strrep(mCapIdx," ","");
    optimTradingSignalParamVarNames = string(optimTradingSignalParamVarNames);

    startIdx = startTradingParamIdx(idx);
    endIdx = endTradingParamIdx(idx);
    optimTradingSignalParamVarNames(startIdx:endIdx) = strcat(mCapIdx,"_",...
        tradingSignalParamVarName);
end

optimTradingSignalParam.Properties.VariableNames = optimTradingSignalParamVarNames;

%-------------------------------------------------------------------------
% preallocate timetable for output FVal (cumulative return) in training dataset
nCol = numel(uniqueMktCap);
nRow = nWalk;
varTypes = repmat({'double'},1,nCol);
sz = [nRow, nCol];
timeCol = marketCapCategory(endStepTrain,:).Time;

optimCumRetAtTrainData = timetable('Size', sz, 'VariableTypes', varTypes,...
    'RowTimes', timeCol, 'VariableNames', uniqueMktCap);

clearvars marketCapCategory
%-------------------------------------------------------------------------

% preallocate timetable for output flag(exitflagAtTrainData) in training dataset
varTypes = repmat({'string'},1,nCol);
exitflagAtTrainData = timetable('Size', sz, 'VariableTypes', varTypes,...
    'RowTimes', timeCol, 'VariableNames', uniqueMktCap);
%-------------------------------------------------------------------------

%% do walk-forwad
nMktCap = numel(uniqueMktCap);

% prepare for waitbarFig
msg = "Please wait. Optimizing parameter for walk forward analysis";
waitbarFig = waitbar(0,msg);
timeColDataInput = dataInput.openPrice.Time;
% optimParam for each walk
nIteration = nWalk*nMktCap;
for walkIdx = 15:nWalk
    % walkIdx =1
    % setUp lookbackIdx
    startLookbackIdx = startStepLookback(walkIdx);
    endLookbackIdx = endStepLookback(walkIdx);

    % setUp trainIdx
    startTrainIdx = startStepTrain(walkIdx);
    endTrainIdx = endStepTrain(walkIdx);

    % setUp testIdx
    startTestIdx = startStepTest(walkIdx);
    endTestIdx = endStepTest(walkIdx);

    timeColTrainWalkIdx = timeColDataInput(startLookbackIdx:endTrainIdx);

    % optimparam for each mCap
    for mCapIdx = 1: nMktCap
        % mCapIdx = 1
        % show wait bar counting each walkIdx
        progressCounter = (walkIdx*mCapIdx)/nIteration;
        waitbar(progressCounter, waitbarFig, msg);

        disp(strcat("walkIdx ",string(walkIdx)," | mCapIdx ",string(mCapIdx)," ",uniqueMktCap(mCapIdx)))

        %setUp list of symbols for each mktCap category in each walkIdx
        mCapIdxAtWalkIdx = mCapEndStepTrainIdxVar(walkIdx, :) == uniqueMktCap(mCapIdx);
        SymInMCapIdxWalkIdx = symbols(mCapIdxAtWalkIdx);

        % setUp dataInput contains symbols of mCapIdx only  in each walk
        openPriceVarName = strcat(SymInMCapIdxWalkIdx,"_open");
        dataInputTrain.openPrice = dataInput.openPrice(timeColTrainWalkIdx,openPriceVarName);

        highPriceVarName = strcat(SymInMCapIdxWalkIdx,"_high");
        dataInputTrain.highPrice = dataInput.highPrice(timeColTrainWalkIdx,highPriceVarName);

        lowPriceVarName = strcat(SymInMCapIdxWalkIdx,"_low");
        dataInputTrain.lowPrice = dataInput.lowPrice(timeColTrainWalkIdx,lowPriceVarName);

        closePriceVarName = strcat(SymInMCapIdxWalkIdx,"_close");
        dataInputTrain.closePrice = dataInput.closePrice(timeColTrainWalkIdx,closePriceVarName);

        volumeVarName = strcat(SymInMCapIdxWalkIdx,"_volume");
        dataInputTrain.volume = dataInput.volume(timeColTrainWalkIdx,volumeVarName);


        % clean dataInput 
        priceVolumeRaw = dataInputTrain;
        priceVolumeClean = cleanDataFcn (priceVolumeRaw);

        % transfer the dataInput
        dataStructInput = priceVolumeClean;
        clearvars priceVolumeRaw priceVolumeClean
        %--------------------------------------------------------------------

        optimStructOut = optimParamsFcn (dataStructInput, optimLookbackStep,...
            tradingCost, maxCapAllocation, nlConstParam,...
            lbubConst, maxFcnEval);

        %--------------------------------------------------------------------

        % assign the optimizedParam into optimTradingSignalParam
        colIdx = startTradingParamIdx(mCapIdx):endTradingParamIdx(mCapIdx);
        timeColOptimParam = timeColDataInput(endTrainIdx);

        optimTradingSignalParam(timeColOptimParam, colIdx).Variables =...
            optimStructOut.optimizedTradingSignalParam;

        % assign FVal into optimCumRetAtTrainData
        optimCumRetAtTrainData(timeColOptimParam, mCapIdx).Variables = optimStructOut.fval;

        % assign exitflag into exitflagAtTrainData
        exitflagAtTrainData(timeColOptimParam, mCapIdx).Variables = optimStructOut.exitflag;

        %-------------------------------------------------------------------------

        % apply the optimizedTradingParam to generateSignal on training dataset
        % generate tradingSignal in training dataset
        tradingSignalParameter = optimStructOut.optimizedTradingSignalParam;
        tradingSignalTrainOut = generateTradingSignalFcn (dataStructInput, tradingSignalParameter);

        % assign signal to tradingSignalTestSet
        timeColSignalTrain = timeColTrainWalkIdx(end-nstepTrain+1:end,:);
        tradingSignalTrainSet(timeColSignalTrain,SymInMCapIdxWalkIdx) = tradingSignalTrainOut(timeColSignalTrain,:);

        %-------------------------------------------------------------------------

        % apply the optimizedTradingParam to generateSignal on test dataset
        % setup the test dataset
        endTestSet = endTestIdx;
        startTestSet = endTestSet - nstepTest - lookbackUB +1;
        timeColTestWalkIdx = timeColDataInput(startTestSet:endTestSet);

        dataInputTest.openPrice = dataInput.openPrice(timeColTestWalkIdx,openPriceVarName);
        dataInputTest.highPrice = dataInput.highPrice(timeColTestWalkIdx,highPriceVarName);
        dataInputTest.lowPrice = dataInput.lowPrice(timeColTestWalkIdx,lowPriceVarName);
        dataInputTest.closePrice = dataInput.closePrice (timeColTestWalkIdx,closePriceVarName);
        dataInputTest.volume = dataInput.volume(timeColTestWalkIdx,volumeVarName);

        % generate tradingSignal in test dataset
        tradingSignalParameter = optimStructOut.optimizedTradingSignalParam;
        tradingSignalTTOut = generateTradingSignalFcn (dataInputTest, tradingSignalParameter);

        % assign signal to tradingSignalTestSet
        timeColSignalTest = timeColTestWalkIdx(end-nstepTest+1:end,:);
        tradingSignalTestSet(timeColSignalTest,SymInMCapIdxWalkIdx) = tradingSignalTTOut(timeColSignalTest,:);

    end

end
%-------------------------------------------------------------------------

%% backtest on the training dataset
% prepare training dataset backtest the signal against the market data
dataInputTrainSet.openPrice = dataInput.openPrice(timeColSignalTrainSet,:);
dataInputTrainSet.highPrice = dataInput.highPrice(timeColSignalTrainSet,:);
dataInputTrainSet.lowPrice = dataInput.lowPrice(timeColSignalTrainSet,:);
dataInputTrainSet.closePrice = dataInput.closePrice(timeColSignalTrainSet,:);
dataInputTrainSet.volume = dataInput.volume(timeColSignalTrainSet,:);

dataInputTrainSetClean = cleanDataFcn (dataInputTrainSet);

% generate backtest output
btResultTrainSet = btEngineVectFcn(dataInputTrainSetClean, tradingSignalTrainSet,...
    tradingCost, maxCapAllocation);

%-----------------------------------------------------------------------

%% backtest on the test dataset
% prepare test dataset backtest the signal against the market data
dataInputTestSet.openPrice = dataInput.openPrice(timeColSignalTestSet,:);
dataInputTestSet.highPrice = dataInput.highPrice(timeColSignalTestSet,:);
dataInputTestSet.lowPrice = dataInput.lowPrice(timeColSignalTestSet,:);
dataInputTestSet.closePrice = dataInput.closePrice(timeColSignalTestSet,:);
dataInputTestSet.volume = dataInput.volume(timeColSignalTestSet,:);

dataInputTestSetClean = cleanDataFcn (dataInputTestSet);

% generate backtest output
btResultTestSet = btEngineVectFcn(dataInputTestSetClean, tradingSignalTestSet,...
    tradingCost, maxCapAllocation);


%% wrap up the results
wfaOptimStructOut.optimTradingSignalParam = optimTradingSignalParam;
wfaOptimStructOut.optimCumRetAtTrainData = optimCumRetAtTrainData;
wfaOptimStructOut.exitflagAtTrainData = exitflagAtTrainData;
wfaOptimStructOut.wfaSetUpParam = wfaSetUpParam;
wfaOptimStructOut.btResultTestSet = btResultTestSet;
wfaOptimStructOut.btResultTrainSet = btResultTrainSet;
wfaOptimStructOut.tradingSignalTestSet = tradingSignalTestSet;
wfaOptimStructOut.tradingSignalTrainSet = tradingSignalTrainSet;
wfaOptimStructOut.wfaSetUpParam = wfaSetUpParam;

%% 
path = pwd;
fileName = 'DataOutput\OptimizedParameters\wfaOptimStructOut_20220227.mat';
fullFileName = fullfile(path,fileName);
save(fullFileName, 'wfaOptimStructOut');
%% =========================================================================

% cleanvars -except wfaOptimStructOut
tWFAOptim = toc
% end

