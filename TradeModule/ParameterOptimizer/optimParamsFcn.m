function optimStructOut = optimParamsFcn (dataInput,...
    backShiftNDay, optimLookbackStep, tradingCost, maxCapAllocation,...
    nlConstParam, LBUBConst, maxFcnEval, nVars)

% optimParamsFcn - function for parameter optimization
% USAGE:
%
%       optimParams = optimParamsFcn (tradingSignalParam, dataStructInput,...
%                   optimLookbackStep, tradingCost, maxCapAllocation,...
%                   maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)
%
% x
%=========================================================================
% paralel pool
pool = gcp('nocreate'); % Check whether a parallel pool exists
if isempty(pool) % If not, create one
    pool = parpool;
end

N = pool.NumWorkers;
useParallel = true;

% sample input args
% optimizedParameter
% backtest the signal
% dataStructInput = dataInput;
% tradingCost = [0.15/100, 0.25/100];
% maxCapAllocation = 0.2;
% optimLookbackStep = 250*7;
% maxDDThreshold = -0.50;
% minPortfolioReturn = 1.10;
% minDailyRetThreshold = -0.20;
% maxFcnEval = 24;

%% LB UB Constraints
%     UBLookback = 250;
% LBUBConst = [       % open the array
%     2,      10;       %liquidityVolumeShortMALookback = paramInput(1);
%     100,    UBLookback;        %liquidityVolumeLongMALookback = paramInput(2);
%     0,      500;               % liquidityVolumeMAThreshold = paramInput(3);
%     1,      UBLookback;        %liquidityVolumeMANDayBuffer = paramInput(4)
%     1,      UBLookback;        % liquidityValueMALookback  = paramInput(5);
%     0,      500;              % liquidityValueeMAThreshold  = paramInput(6);
%     1,      UBLookback;        %liquidityValueMANDayBuffer = paramInput(7)
%     1,      UBLookback        % liquidityNDayVolumeValueBuffer = paramInput(8);
%     1,      UBLookback     % momentumPriceMALookback = paramInput(9);
%     0,      500            % momentumPriceMAToCloseThreshold = paramInput(10);
%     1,      UBLookback       % momentumPriceRetLowToCloseLookback = paramInput(11);
%     0,      500             % momentumPriceRetLowToCloseThreshold = paramInput(12);
%     1,      UBLookback     % momentumPriceRetLowToCloseNDayBuffer = paramInput(13);
%     1,      UBLookback      % liquidityMomentumSignalBuffer = paramInput(14);
%     0,      UBLookback        % cutLossHighToCloseNDayLookback = paramInput(15);
%     0,      500             % cutLossHighToCloseMaxPct = paramInput(16);
%     1,      1               % nDayBackShift = paramInput(17);
%     ] ;  % close the array


%% define function handle of objectiveFcn and nonLinearConstraintFcn

objFcn = @(x)objectiveFcn (x, dataInput, backShiftNDay, tradingCost,...
    maxCapAllocation, optimLookbackStep);

nlconst = @(x)nonLinearConstraintFcn (x, dataInput,...
    backShiftNDay, optimLookbackStep, tradingCost, maxCapAllocation,...
    nlConstParam);

objconstr = packfcn(objFcn,nlconst) ;
F = objconstr ;

%% define other constrains
intConst = 1:nVars;
LB = LBUBConst(:,1)';
UB = LBUBConst(:,2)';

%% setup optimization options
options = optimoptions('surrogateopt','PlotFcn',"surrogateoptplot", ...
    "ConstraintTolerance",1e-2, "UseParallel", useParallel,...
    "UseVectorized",true,"MaxFunctionEvaluations", maxFcnEval,...
    "BatchUpdateInterval", N);

%  

%% call surrogateopt to solve the problem
[sol,fval,exitflag,output] = surrogateopt(F,LB,UB,intConst,options) ;

%% put UB into tradingSignalParam if FVal < minPortfolioReturn
if fval <= -(nlConstParam.minPortRet)
    optimizedTradingSignalParam = sol ;
else
    optimizedTradingSignalParam = UB ;
end
%% wrap up for output
optimStructOut.optimizedTradingSignalParam = optimizedTradingSignalParam;
optimStructOut.fval = fval;
optimStructOut.exitflag = exitflag;
optimStructOut.output = output;


clearvars -except optimStructOut
end