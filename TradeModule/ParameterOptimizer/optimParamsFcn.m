function structOut = optimParamsFcn (tradingSignalParam, dataStructInput,...
                  optimLookbackStep, tradingCost, maxCapAllocation,...
                  maxDDThreshold, minPortfolioReturn, minDailyRetThreshold, maxFcnEval, LB, UB)
    %
    % optimParamsFcn - function for parameter optimization
    % USAGE:
    % 
    %       optimParams = optimParamsFcn (tradingSignalParam, dataStructInput,...
    %                   optimLookbackStep, tradingCost, maxCapAllocation,...
    %                   maxDDThreshold, minPortfolioReturn, minDailyRetThreshold)  
    % 
    % x
    % paralel pool
    pool = gcp('nocreate'); % Check whether a parallel pool exists
    if isempty(pool) % If not, create one
        pool = parpool;
    end
    
    N = pool.NumWorkers;
    
    % optimizedParameter
    % backtest the signal
%     dataStructInput = dataInput;
%     tradingCost = [0.15/100, 0.25/100];
%     maxCapAllocation = 0.2;
%     optimLookbackStep = 250;
%     maxDDThreshold = -0.20;
%     minPortfolioReturn = 1.10;
%     minDailyRetThreshold = -0.20;
%     maxFcnEval = 200;
%     nRowDataInput = size(dataStructInput.openPrice, 1);
%     UBLookback = 250 ;%nRowDataInput;
%     LBUBConst = [                                     % open the array
%                     1,  UBLookback;        % liquidityVolumeMALookback = paramInput(1);
%                     0,  500;               % liquidityVolumeMAThreshold = paramInput(2);
%                     1,  UBLookback;        %liquidityVolumeMANDayBuffer = paramInput(3) 
%                     1,  UBLookback;        % liquidityValueMALookback  = paramInput(4);
%                     0,  500;              % liquidityValueeMAThreshold  = paramInput(5);
%                     1,  UBLookback;        %liquidityValueMANDayBuffer = paramInput(6)
%                     1,  UBLookback        % liquidityNDayVolumeValueBuffer = paramInput(7);
%                     1,  UBLookback     % momentumPriceMALookback = paramInput(8);
%                     0,  500            % momentumPriceMAToCloseThreshold = paramInput(9);
%                     1,  UBLookback       % momentumPriceRetLowToCloseLookback = paramInput(10);
%                     0,  500             % momentumPriceRetLowToCloseThreshold = paramInput(11);
%                     1,  UBLookback     % momentumPriceRetLowToCloseNDayBuffer = paramInput(12);
%                     1,  UBLookback      % liquidityMomentumSignalBuffer = paramInput(13);
%                     0,  UBLookback        % cutLossHighToCloseNDayLookback = paramInput(14);
%                     0,  500             % cutLossHighToCloseMaxPct = paramInput(15);
%                     1,  UBLookback        % nDayBackShift = paramInput(16);
%                                                 ] ;  % close the array
    % 
    % 
    % %-----------------------------------------------------------------------
    % define function handle of objectiveFcn and nonLinearConstraintFcn
    x = tradingSignalParam;
    
    obj = @(x)objectiveFcn (x, dataStructInput, tradingCost,...
                                maxCapAllocation, optimLookbackStep);
    nlconst = @(x)nonLinearConstraintFcn (x, dataStructInput,...
                  optimLookbackStep, tradingCost, maxCapAllocation,...
                  maxDDThreshold, minPortfolioReturn, minDailyRetThreshold);
    
    objconstr = packfcn(obj,nlconst) ;
    F = objconstr ;
    
    % define other constrains
    nVars = 16;
    intConst = 1:nVars;
%     LB = LBUBConst(:,1)';
%     UB = LBUBConst(:,2)';
    
    % setup optimization options
    options = optimoptions('surrogateopt','PlotFcn',"surrogateoptplot", ...
        "ConstraintTolerance",1e-4, "MaxFunctionEvaluations",maxFcnEval, ...
        "UseParallel", true, "UseVectorized",true);
    
    % call surrogateopt to solve the problem
    [sol,fval,exitflag,output] = surrogateopt(F,LB,UB,intConst,options) ;
    
    % put UB into tradingSignalParam if FVal < minPortfolioReturn
    if fval < -(1+minPortfolioReturn) 
        optimParams = sol ;
        else
        optimParams = UB ;
    end
            
    structOut.optimParams = optimParams;
    structOut.fval = fval;
    structOut.exitflag = exitflag;
    structOut.output = output;


clearvars -except structOut
%-----------------------------------------------------------------------
end