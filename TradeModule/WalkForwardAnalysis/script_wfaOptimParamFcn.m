% function wfaOptimStructOut = wfaOptimParamFcn(marketData, wfaSetUpParam)
tic
%wfaOptimParamFcn Summary of this function goes here
%   Detailed explanation goes here
% Input arguments
% - dataInput contains timetables of openPrice, highPrice, lowPrice, closePrice, volume and mktCapCategory
% - wfaSetUpParam

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
backShiftNDay = wfaSetUpParam.backShiftNDay;

% optimization set up
optimLookbackStep = wfaSetUpParam.nstepTrain;
maxFcnEval = wfaSetUpParam.maxFcnEval;
lbubConst = wfaSetUpParam.lbubConst;
nVars = wfaSetUpParam.nVars;

nlConstParam.maxDDThreshold  = wfaSetUpParam.maxDDThreshold;
nlConstParam.minPortRet = wfaSetUpParam.minPortRet;
nlConstParam.minDailyRetThreshold = wfaSetUpParam.minDailyRetThreshold;
nlConstParam.Last20DRetThreshold = wfaSetUpParam.minLast20DRetThreshold;
nlConstParam.Last60DRetThreshold = wfaSetUpParam.minLast60DRetThreshold;
nlConstParam.Last200DRetThreshold = wfaSetUpParam.minLast200DRetThreshold;


% number of required nDataRowRequired
nstepWalk = nWalk*nstepTest + lookbackUB + nstepTrain;
additionalData = nstepTest; % additional data for safety required data
nDataRowRequired = nstepWalk+additionalData;
%-------------------------------------------------------------------------

%% prepare data for for WFA
priceVolumeData = marketData.priceVolumeData;
nData = numel(priceVolumeData);
dataInput = cell(1,nData);

for idx=1:numel(priceVolumeData)
    dataInput{idx} = priceVolumeData{idx}(end-nDataRowRequired+1:end,:);
end
    
marketCapCategory = marketData.marketCapCategory(end-nDataRowRequired+1:end,:);

% Number of rows in raw data
nRowDataAvailable = size (dataInput{1},1) ;

% nRowDataAvailable must be larger than nDataRowRequired
validIF = nRowDataAvailable < nDataRowRequired;

if validIF
    error(message('finance:WFA:nRowDataAvailable must be larger than nDataRowRequired'));
end

%-------------------------------------------------------------------------

%% marking idx step for each walk
% idx for start and end of test steps
nRowAvailable = size(dataInput{1},1);
lastEndStepTest = nRowAvailable;
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
timeCol = dataInput{1}.Time;
nRow = numel(timeCol);
%-------------------------------------------------------------------------

%% prepare market cap category for loop to get the list of symbols at each EndStepTrainIdx for each
% mktCapCategory

uniqueMktCap = unique(marketCapCategory.Variables);
uniqueMktCap(ismissing(uniqueMktCap)) = [];
uniqueMktCap= sort(uniqueMktCap);
mktCapList = uniqueMktCap;

symbols = marketCapCategory.Properties.VariableNames;

mCapEndStepTrainIdx = marketCapCategory(endStepTrain,:);
mCapEndStepTrainIdxVar = mCapEndStepTrainIdx.Variables;

% preallocate tradingSignalTrainSet
timeCol = dataInput{1}.Time;
timeColSignalTrainSet = timeCol(startStepTrain(1):endStepTrain(end));
openPrice = dataInput{1};
tradingSignalTrainSet = openPrice(timeColSignalTrainSet,:);
tradingSignalTrainSet.Variables = zeros(size(tradingSignalTrainSet));
tradingSignalTrainSet.Properties.VariableNames = strrep(tradingSignalTrainSet.Properties.VariableNames,"_open","");

% preallocate tradingSignalTestSet
timeCol = dataInput{1}.Time;
timeColSignalTestSet = timeCol(startStepTest(1):endStepTest(end));
openPrice = dataInput{1};
tradingSignalTestSet = openPrice(timeColSignalTestSet,:);
tradingSignalTestSet.Variables = zeros(size(tradingSignalTestSet));
tradingSignalTestSet.Properties.VariableNames = strrep(tradingSignalTestSet.Properties.VariableNames,"_open","");

%-------------------------------------------------------------------------

%% preallocate optimizedSignalParam for each startTrainStepIdx and marketCapCategory
tradingSignalParamVarName =...
    [...
    "volumeMATreshold"; % input #1
    "volumeMALookback"; % input #2
    "valueThreshold"; % input #3 in Rp hundreds million
    "valueLookback"; % input #4 nDays
    "volumeValueBufferDays"; % input #5
    "priceRetLowCloseThresh"; % input #6
    "priceMAThreshold"; % input #7
    "priceMALookback" ; % input #8
    "priceVolumeValueBufferDays "; % input #9
    "cutLossLookback" ; % input #10
    "cutLossPct" ;... % input #11
    ];


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

%% preallocate timetable for output FVal (cumulative return) in training dataset
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

% % prepare for waitbarFig
msg = "Please wait. Optimizing parameter for walk forward analysis";
waitbarFig = waitbar(0,msg);
timeColDataInput = dataInput{1}.Time;
% optimParam for each walk
nIteration = nWalk*nMktCap;

symEnd = ["_open", "_high", "_low", "_close", "_volume"];

for walkIdx = 1:nWalk
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
        progressCounter = (mCapIdx + nMktCap*(walkIdx-1))/nIteration;
        waitbar(progressCounter, waitbarFig, msg);

        textToDisplay = strcat("walkIdx ",string(walkIdx)," | mCapIdx ",...
            string(mCapIdx)," ",uniqueMktCap(mCapIdx),...
            " -- start=",string(timeColTrainWalkIdx(1)), " end=",string(timeColTrainWalkIdx(end)));
        disp(textToDisplay)

        %setUp list of symbols for each mktCap category in each walkIdx
        mCapIdxAtWalkIdx = mCapEndStepTrainIdxVar(walkIdx, :) == uniqueMktCap(mCapIdx);
        SymInMCapIdxWalkIdx = symbols(mCapIdxAtWalkIdx);

        % setUp dataInput contains symbols of mCapIdx only  in each walk
        dataInputTrain = cell(1,numel(dataInput));
        for idx=1:numel(dataInput) 
            VarNames = strcat(SymInMCapIdxWalkIdx,symEnd(idx));
            dataInputTrain{idx} = dataInput{idx}(timeColTrainWalkIdx,VarNames);
        end

        % clean dataInput
        priceVolumeRaw = dataInputTrain;
        priceVolumeClean = cleanDataFcn (priceVolumeRaw);

        % transfer the dataInput
        clearvars priceVolumeRaw dataInputTrain
        %--------------------------------------------------------------------

        optimStructOut = optimParamsFcn(priceVolumeClean, backShiftNDay,...
            optimLookbackStep, tradingCost, maxCapAllocation,...
            nlConstParam, lbubConst, maxFcnEval, nVars);

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
        tradingSignalTrainOut = tradeSignalShortMomFcn(tradingSignalParameter, priceVolumeClean);

        % assign signal to tradingSignalTestSet
        timeColSignalTrain = timeColTrainWalkIdx(end-nstepTrain+1:end,:);
        tradingSignalTrainSet(timeColSignalTrain,SymInMCapIdxWalkIdx) = tradingSignalTrainOut(timeColSignalTrain,:);

        %-------------------------------------------------------------------------

        % apply the optimizedTradingParam to generateSignal on test dataset
        % setup the test dataset
        endTestSet = endTestIdx;
        startTestSet = endTestSet - nstepTest - lookbackUB +1;
        timeColTestWalkIdx = timeColDataInput(startTestSet:endTestSet);

        % setUp dataInput contains symbols of mCapIdx only  in each walk
        dataInputTest = cell(1,numel(dataInput));
        for idx=1:numel(dataInput)
            VarNames = strcat(SymInMCapIdxWalkIdx,symEnd(idx));
            dataInputTest{idx} = dataInput{idx}(timeColTestWalkIdx,VarNames);
        end

        % clean dataInput
        dataInputTest = cleanDataFcn (dataInputTest);

        % generate tradingSignal in test dataset
        tradingSignalParameter = optimStructOut.optimizedTradingSignalParam;
        tradingSignalTTOut = tradeSignalShortMomFcn (tradingSignalParameter, dataInputTest);

        % assign signal to tradingSignalTestSet
        timeColSignalTest = timeColTestWalkIdx(end-nstepTest+1:end,:);
        tradingSignalTestSet(timeColSignalTest,SymInMCapIdxWalkIdx) = tradingSignalTTOut(timeColSignalTest,:);

        clearvars dataInputTest
        %------------------------------------------------------------------

    end

end
%-------------------------------------------------------------------------

%% backtest on the training dataset
% prepare training dataset backtest the signal against the market data
timeCol = dataInput{1}.Time;
timeColSignalTrainSet = timeCol(startStepTrain(1):endStepTrain(end));
dataInputTrainSet = cell(1,numel(dataInput));

for idx = 1:numel(dataInput)
    dataInputTrainSet{idx}= dataInput{idx}(timeColSignalTrainSet,:);
end

dataInputTrainSetClean = cleanDataFcn (dataInputTrainSet);

% generate backtest output
btResultTrainSet = btEngineVectFcn (dataInputTrainSetClean, tradingSignalTrainSet,...
    backShiftNDay, tradingCost, maxCapAllocation);

clearvars dataInputTrainSet dataInputTrainSetClean

%-----------------------------------------------------------------------

%% backtest on the test dataset
% prepare test dataset backtest the signal against the market data
timeCol = dataInput{1}.Time;
timeColSignalTestSet = timeCol(startStepTest(1):endStepTest(end));
dataInputTestSet = cell(1,numel(dataInput));

for idx = 1:numel(dataInput)
    dataInputTestSet{idx}= dataInput{idx}(timeColSignalTestSet,:);
end

dataInputTestSetClean = cleanDataFcn (dataInputTestSet);

% generate backtest output
btResultTestSet = btEngineVectFcn (dataInputTestSetClean, tradingSignalTestSet,...
    backShiftNDay, tradingCost, maxCapAllocation);

clearvars dataInputTestSet dataInputTestSetClean

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
detailPath = 'DataOutput\OptimizedParameters\';
fileName = '50Walk100Train5Test_wfaOptimStructOut_';
dateName = string(datetime('today'));
fileFormat = '.mat';
fullName = strcat(fileName,dateName, fileFormat);
fullFileName = fullfile(path, detailPath, fullName);

save(fullFileName, 'wfaOptimStructOut');

% =========================================================================

%% end of function

% cleanvars -except wfaOptimStructOut
tWFAOptim = toc
% end

