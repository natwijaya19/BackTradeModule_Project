% function wfaOptimStructOut = wfaOptimParamFcn(marketData, wfaSetUpParam)
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


% number of required nDataRowRequired 
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

% preallocate tradingSignalTT
timeCol = dataInput.openPrice.Time;
timeColSignalTT = timeCol(startStepTest(1):endStepTest(end));
openPrice = dataInput.openPrice;
tradingSignalTT = openPrice(timeColSignalTT,:);
tradingSignalTT.Variables = zeros(size(tradingSignalTT));
tradingSignalTT.Properties.VariableNames = strrep(tradingSignalTT.Properties.VariableNames,"_open",""); 

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
% preallocate timetable for output FVal >> optimized cumulative return timetable
% in training dataset
nCol = numel(uniqueMktCap);
nRow = nWalk;
varTypes = repmat({'double'},1,nCol);
sz = [nRow, nCol];
timeCol = marketCapCategory(endStepTrain,:).Time;

optimCumRetAtTrainData = timetable('Size', sz, 'VariableTypes', varTypes,...
                        'RowTimes', timeCol, 'VariableNames', uniqueMktCap);
%-------------------------------------------------------------------------

% preallocate timetable for output flag >> exitflagAtTrainData timetable 
% in training dataset
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
for walkIdx = 1:nWalk

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

        % show wait bar counting each walkIdx
        progressCounter = (walkIdx*mCapIdx)/nIteration;
        waitbar(progressCounter, waitbarFig, msg);

        disp(strcat("walkIdx ",string(walkIdx)," | mCapIdx ",string(mCapIdx)))

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


        % clean dataInput %TODO
        priceVolumeRaw = dataInputTrain;
        priceVolumeClean = cleanDataFcn (priceVolumeRaw);

        % transfer the dataInput
        dataStructInput = priceVolumeClean;

        optimStructOut = optimParamsFcn (dataStructInput, optimLookbackStep,...
            tradingCost, maxCapAllocation, nlConstParam,...
            lbubConst, maxFcnEval);

        % backtest the optimTradingSignal on test dataset
        % setup the test dataset
        endTestSet = endTestIdx;
        startTestSet = endTestSet - nstepTest - lookbackUB +1;
        timeColTestWalkIdx = timeColDataInput(startTestSet:endTestSet);

        dataInputTest.openPrice = dataInput.openPrice(timeColTestWalkIdx,openPriceVarName);
        dataInputTest.highPrice = dataInput.highPrice(timeColTestWalkIdx,highPriceVarName);
        dataInputTest.lowPrice = dataInput.lowPrice(timeColTestWalkIdx,lowPriceVarName);
        dataInputTest.closePrice = dataInput.closePrice (timeColTestWalkIdx,closePriceVarName);
        dataInputTest.volume = dataInput.volume(timeColTestWalkIdx,volumeVarName);

        % generate tradingSignal 
        tradingSignalParameter = optimStructOut.optimizedTradingSignalParam;
        tradingSignalTTOut = generateTradingSignalFcn (dataInputTest, tradingSignalParameter);
        
        % assign signal to tradingSignalTT
        timeColSignal = timeColTestWalkIdx(end-nstepTest+1:end,:);
        tradingSignalTT(timeColSignal,SymInMCapIdxWalkIdx) = tradingSignalTTOut(timeColSignal,:);

        % assign the optimizedParam into optimTradingSignalParam
        colIdx = startTradingParamIdx(mCapIdx):endTradingParamIdx(mCapIdx);
        timeColOptimParam = timeColDataInput(endTrainIdx);
        
        optimTradingSignalParam(timeColOptimParam, colIdx).Variables =...
                                optimStructOut.optimizedTradingSignalParam;

        % assign FVal into optimCumRetAtTrainData
        optimCumRetAtTrainData(timeColOptimParam, mCapIdx).Variables = optimStructOut.fval;

        % assign exitflag into exitflagAtTrainData
        exitflagAtTrainData(timeColOptimParam, mCapIdx).Variables = optimStructOut.exitflag;

    end

end
%% 

% prepare data backtest teh signal against the market data
dataInputBacktest.openPrice = dataInput.openPrice(timeColSignalTT,:);
dataInputBacktest.highPrice = dataInput.highPrice(timeColSignalTT,:);
dataInputBacktest.lowPrice = dataInput.lowPrice(timeColSignalTT,:);
dataInputBacktest.closePrice = dataInput.closePrice(timeColSignalTT,:);
dataInputBacktest.volume = dataInput.volume(timeColSignalTT,:);

priceVolumeClean = cleanDataFcn (dataInputBacktest);

% generate backtest output
btResultStruct = btEngineVectorizedFcn (priceVolumeClean, tradingSignalTT,...
    tradingCost, maxCapAllocation);


% assign output variables into a struct
wfaOptimStructOut.optimTradingSignalParam = optimTradingSignalParam;
wfaOptimStructOut.optimCumRetAtTrainData = optimCumRetAtTrainData;
wfaOptimStructOut.exitflagAtTrainData = exitflagAtTrainData;
wfaOptimStructOut.wfaSetUpParam = wfaSetUpParam;
wfaOptimStructOut.btResultStruct = btResultStruct;
wfaOptimStructOut.tradingSignalTT = tradingSignalTT;
%=========================================================================

% end

