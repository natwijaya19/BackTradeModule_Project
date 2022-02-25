function wfaOptimStructOut = wfaOptimParamFcn(marketData, wfaSetUpParam)
%UNTITLED Summary of this function goes here
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
optimLookbackStep = wfaSetUpParam.nstepTrain; %TODO lets put this later in the function
maxDDThreshold = wfaSetUpParam.maxDDThreshold;
minPortfolioReturn = wfaSetUpParam.minPortfolioReturn;
minDailyRetThreshold = wfaSetUpParam.minDailyRetThreshold;
maxFcnEval = wfaSetUpParam.maxFcnEval;
lbubConst = wfaSetUpParam.lbubConst;

% number of required nDataRowRequired 
nstepWalk = nWalk*nstepTest + lookbackUB + nstepTrain;
additionalData = nstepTest; % additional data for safety required data
nDataRowRequired = nstepWalk+additionalData;

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

%% marking idx step for each walk
% idx for start and end of test steps

nDataRowRequired = size(dataInput.openPrice,1);
lastEndStepTestIdx = nDataRowRequired;
firstEndTestIdx = lastEndStepTestIdx - (nWalk-1)*nstepTest;
endStepTestIdx = firstEndTestIdx:nstepTest:lastEndStepTestIdx;
startStepTestIdx = endStepTestIdx - nstepTest +1;

% idx for start and end of train steps
endStepTrainIdx = startStepTestIdx-1;
startStepTrainIdx = endStepTrainIdx - nstepTrain+1;

% idx for start and end of lookback steps
endStepLookbackIdx = startStepTrainIdx-1;
startStepLookbackIdx = endStepLookbackIdx - lookbackUB+1;

% determine index and timecolumn for each step and walk
timeCol = dataInput.openPrice.Time;
nRow = numel(timeCol);
idx = (1:nRow)';
% lookback set idx
startStepLookbackIdxTT = sum(idx == startStepLookbackIdx,2);
endStepLookbackIdxTT = sum(idx == endStepLookbackIdx,2);
% train set idx
startStepTrainIdxT = sum(idx == startStepTrainIdx,2);
endStepTrainIdxT = sum(idx == endStepTrainIdx,2);

%test set idx
startStepTestIdxT = sum(idx == startStepTestIdx,2);
endStepTestIdxT = sum(idx == endStepTestIdx,2);

% time column index for looping marker
% timeColIdx = timetable(timeCol, idx, startStepLookbackIdxTT,...
%     endStepLookbackIdxTT, startStepTrainIdxT, endStepTrainIdxT,...
%     startStepTestIdxT, endStepTestIdxT);


%% prepare market cap category for loop to get the list of symbols at each EndStepTrainIdx for each
% mktCapCategory
marketCapCategory = dataInput.marketCapCategory;
uniqueMktCap = unique(marketCapCategory.Variables);
uniqueMktCap(ismissing(uniqueMktCap)) = [];
uniqueMktCap= sort(uniqueMktCap);

symbols = marketCapCategory.Properties.VariableNames;
mCapAtEndStepTrainIdx = marketCapCategory(endStepTrainIdx,:);
mCapAtEndStepTrainIdxVar = mCapAtEndStepTrainIdx.Variables;

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
                    "cutLossHighToCloseMaxPct";  ];


nCol = numel(uniqueMktCap) * numel(tradingSignalParamVarName);
nRow = nWalk;
varTypes = repmat({'double'},1,nCol);
sz = [nRow, nCol];
timeCol = mCapAtEndStepTrainIdx.Time;

optimTradingSignalParam = timetable('Size', sz, 'VariableTypes', varTypes,...
                          'RowTimes', timeCol);

optimTradingSignalParamVarNames = optimTradingSignalParam.Properties.VariableNames;

for idx = 1:numel(uniqueMktCap)

    startIdx = numel(tradingSignalParamVarName)*(idx-1)+1;
    endIdx = idx*numel(tradingSignalParamVarName);
    mCapIdx = string(uniqueMktCap(idx));
    mCapIdx = strrep(mCapIdx,"Lower","lower");
    mCapIdx = strrep(mCapIdx,"Upper","upper");
    mCapIdx = strrep(mCapIdx," ","");
    optimTradingSignalParamVarNames = string(optimTradingSignalParamVarNames);
    
    optimTradingSignalParamVarNames(startIdx:endIdx) = strcat(mCapIdx,"_",...
                            tradingSignalParamVarName);
end

optimTradingSignalParam.Properties.VariableNames = optimTradingSignalParamVarNames;

% preallocate timetable for output FVal >> optimized cumulative return timetable
% in training dataset
nCol = numel(uniqueMktCap);
nRow = nWalk;
varTypes = repmat({'double'},1,nCol);
sz = [nRow, nCol];
timeCol = mCapAtEndStepTrainIdx.Time;

optimCumRetAtTrainData = timetable('Size', sz, 'VariableTypes', varTypes,...
                        'RowTimes', timeCol, 'VariableNames', uniqueMktCap);
% preallocate timetable for output flag >> exitflagAtTrainData timetable 
% in training dataset
varTypes = repmat({'string'},1,nCol);
exitflagAtTrainData = timetable('Size', sz, 'VariableTypes', varTypes,...
                    'RowTimes', timeCol, 'VariableNames', uniqueMktCap);
%=========================================================================


%% do walk-forwad
nMktCap = numel(uniqueMktCap);
% optimParam for each walk
msg = "Please wait. Optimizing parameter for walk forward analysis";
waitbarFig = waitbar(0,msg);
for walkIdx = 1:nWalk
    
    % show wait bar counting the walkIdx
    waitbar(walkIdx/nWalk, waitbarFig, msg); 
%     disp(walkIdx)

    % setup start and end for loopbackDataset, trainDataset and testDataset
    startLookbackAtWalkIdx = startStepLookbackIdx(walkIdx);
%     endLookbackAtWalkIdx = endStepLookbackIdx(walkIdx);
    
%     startTrainAtWalkIdx = startStepTrainIdx(walkIdx);
    endTrainAtWalkIdx = endStepTrainIdx(walkIdx);
    
%     startStepTestAtWalkIdx = startStepTestIdx(walkIdx);
%     endStepTestAtWalkIdx = endStepTestIdx(walkIdx);
    
    % setup dataInputStruct for each walk
    startIdx = startLookbackAtWalkIdx;
    endIdx = endTrainAtWalkIdx;
    dataInputWalkIdx.openPrice = dataInput.openPrice(startIdx:endIdx,:);
    dataInputWalkIdx.highPrice = dataInput.highPrice(startIdx:endIdx,:);
    dataInputWalkIdx.lowPrice = dataInput.lowPrice(startIdx:endIdx,:);
    dataInputWalkIdx.closePrice = dataInput.closePrice(startIdx:endIdx,:);
    dataInputWalkIdx.volume = dataInput.volume(startIdx:endIdx,:);
    dataInputWalkIdx.marketCapCategory = dataInput.marketCapCategory(startIdx:endIdx,:);

    % optimparam for each mCap
    for mCapIdx = 1: nMktCap
        if mCapIdx == 6
            disp(mCapIdx)
        end
        
        %setUp list of symbols for each mktCap category in each walkIdx
%         MktCapCategIdx = uniqueMktCap(mCapIdx);
        mCapIdxAtWalkIdx = mCapAtEndStepTrainIdxVar(walkIdx, :) == uniqueMktCap(mCapIdx);
        SymInmCapIdxAtWalkIdx = symbols(mCapIdxAtWalkIdx);
        
        % setUp dataInput contains symbols in each mktCap category in each walk
        openPriceVarName = strcat(SymInmCapIdxAtWalkIdx,"_open");
        dataInputWalkMCapIdx.openPrice = dataInputWalkIdx.openPrice(:,openPriceVarName);
        highPriceVarName = strcat(SymInmCapIdxAtWalkIdx,"_high");
        dataInputWalkMCapIdx.highPrice = dataInputWalkIdx.highPrice(:,highPriceVarName);
        lowPriceVarName = strcat(SymInmCapIdxAtWalkIdx,"_low");
        dataInputWalkMCapIdx.lowPrice = dataInputWalkIdx.lowPrice(:,lowPriceVarName);    
        closePriceVarName = strcat(SymInmCapIdxAtWalkIdx,"_close");
        dataInputWalkMCapIdx.closePrice = dataInputWalkIdx.closePrice(:,closePriceVarName);        
        volumeVarName = strcat(SymInmCapIdxAtWalkIdx,"_volume");
        dataInputWalkMCapIdx.volume = dataInputWalkIdx.volume(:,volumeVarName);
        
        % %TODO clean data input for each mCap category in each walkIdx 
%         priceVolumeClean = cleanDataFcn (priceVolumeRaw, symbolRef)
        
        
        % transfer the dataInput
        dataStructInput = dataInputWalkMCapIdx;
        
        optimStructOut = optimParamsFcn (dataStructInput, optimLookbackStep,...
                     tradingCost, maxCapAllocation, maxDDThreshold,...
                     minPortfolioReturn, minDailyRetThreshold,...
                     lbubConst, maxFcnEval);


        % assign the optimizedParam into optimTradingSignalParam 
        startIdx = numel(tradingSignalParamVarName)*(mCapIdx-1)+1;
        endIdx = mCapIdx*numel(tradingSignalParamVarName);
        optimTradingSignalParam(walkIdx, startIdx:endIdx).Variables =...
                                     optimStructOut.optimizedTradingSignalParam;
        
        % assign FVal into optimCumRetAtTrainData
        optimCumRetAtTrainData(walkIdx, mCapIdx).Variables = optimStructOut.fval;

        % assign exitflag into exitflagAtTrainData
        exitflagAtTrainData(walkIdx, mCapIdx).Variables = optimStructOut.exitflag;
        
    end

end
toc


% assign output variables into a struct
wfaOptimStructOut.optimTradingSignalParam = optimTradingSignalParam;
wfaOptimStructOut.optimCumRetAtTrainData = optimCumRetAtTrainData;
wfaOptimStructOut.exitflagAtTrainData = exitflagAtTrainData;
wfaOptimStructOut.wfaSetUpParam = wfaSetUpParam;
%=========================================================================

end

