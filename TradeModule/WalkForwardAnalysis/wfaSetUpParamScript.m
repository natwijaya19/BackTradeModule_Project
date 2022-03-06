% function wfaSetUpParam = wfaSetUpParamFcn(marketData, wfaSetUpParam)

%=========================================================================
%% preparation

%=========================================================================

%% prepare the params

nWalk = wfaSetUpParam.nWalk;
lookbackUB = wfaSetUpParam.lookbackUB;
nstepTrain = wfaSetUpParam.nstepTrain;
nstepTest = wfaSetUpParam.nstepTest;

% number of required nDataRowRequired
nstepWalk = nWalk*nstepTest + lookbackUB + nstepTrain;
additionalData = nstepTest; % additional data for safety required data
nDataRowRequired = nstepWalk+additionalData;
%=========================================================================

%% prepare the data

dataInput = marketData.priceVolumeData;

% Number of rows in raw data
nRowDataAvailable = size (dataInput{1},1) ;

% nRowDataAvailable must be larger than nDataRowRequired
validIF = nDataRowRequired < nRowDataAvailable;

if ~validIF
    error(message('finance:WFA:nRowDataAvailable must be larger than nDataRowRequired'));
end

%=========================================================================

%% prepare for walk loop

% idx for start and end of test steps
nDataRowAvailable = size(dataInput{1},1);
lastEndStepTest = nDataRowAvailable;
lastStartStepTest = lastEndStepTest - nstepTest +1;
firstEndStepTest = lastEndStepTest - (nWalk-1)*nstepTest;
firstStartStepTest = firstEndStepTest - nstepTest +1;

endStepTest = (firstEndStepTest:nstepTest:lastEndStepTest)';
startStepTest= endStepTest - nstepTest +1;

% idx for start and end of train steps
endStepTrain = (startStepTest-1');
startStepTrain = (endStepTrain - nstepTrain+1);

% idx for start and end of lookback steps
endStepLookback = (startStepTrain-1);
startStepLookback = (endStepLookback - lookbackUB+1);

% determine index and timecolumn for each step and walk
timeCol = datetime(dataInput{1}.Time, "Format","dd-MMM-uuuu");
nRow = numel(timeCol);

% timeStep for lookback
lookBackStartDate = timeCol(startStepLookback);
lookBackEndDate = timeCol(endStepLookback);

% timeStep for trainStep
trainStartDate = timeCol(startStepTrain);
trainEndDate = timeCol(endStepTrain);

% timeStep for testStep
testStartDate = timeCol(startStepTest);
testEndDate = timeCol(endStepTest);

% create walkPeriodTable
walk = (1:nWalk)';

walkPeriodTable =...
    table(...
    walk,...
    startStepLookback, endStepLookback,...
    lookBackStartDate, lookBackEndDate,...
    startStepTrain, endStepTrain,...
    trainStartDate, trainEndDate,...
    startStepTest, endStepTest,...
    testStartDate, testEndDate);

%=========================================================================

%% prepare for mCap loop



%=========================================================================

%% wrapUp the output for the whole function
% results for each symMCap in struct data class

% walkPeriodTable
wfaSetUpParam.walkPeriodTable = walkPeriodTable;

% WalkMCapTable


%=========================================================================

%% the end of function
% clearvars -except

% end