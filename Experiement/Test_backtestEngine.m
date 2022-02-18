classdef (InferiorClasses = {?matlab.graphics.axis.Axes,...
        ?matlab.ui.control.UIAxes,?matlab.ui.Figure}) backtestEngine
    %BACKTESTENGINE Engine for portfolio backtesting.
    %
    % Syntax:
    %
    %   backtester = backtestEngine(strategies)
    %   backtester = backtestEngine(strategies, param1, value1,...)
    %
    % Description:
    %
    %   BACKTESTENGINE takes as input a vector of BACKTESTSTRATEGY objects
    %   and returns a BACKTESTENGINE object.  The backtest engine is used
    %   to backtest the portfolio trading strategies defined in the
    %   BACKTESTSTRATEGY objects.
    %
    % Input arguments:
    %
    %   strategies - A vector of backtestStrategy objects to be tested
    %     using the runBacktest() method.  Each backtestStrategy object
    %     defines a portfolio trading strategy.  See the help for
    %     backtestStrategy for more information.
    %
    % Optional Input Parameter Name/Value Pairs:
    %
    %   'RiskFreeRate' : A scalar that specifies the rate of return on
    %     uninvested capital in the portfolio (cash).  The RiskFreeRate is
    %     a decimal percentage and represents the risk free rate for one
    %     time step in the backtest.  For example, if the backtest is using
    %     daily asset price data, then the RiskFreeRate must be the daily
    %     rate of return for cash.  The default is 0.
    %
    %   'CashBorrowRate' : A scalar that specifies the rate of interest
    %     accrual on negative cash balances (margin) during the backtest.
    %     The CashBorrowRate is a decimal percentage and represents the
    %     interest accrual rate for one time step in the backtest.  For
    %     example, if the backtest is using daily asset price data, then
    %     the CashBorrowRate must be the daily interest rate for negative
    %     cash balances.  The default is 0.
    %
    %   'RatesConvention' : A string specifying how the backtest engine
    %     uses the RiskFreeRate and CashBorrowRate to compute interest.
    %     Valid values are:
    %
    %         "Annualized" : The rates are treated as annualized rates and
    %             the backtest engine computes incremental interest based
    %             on the day count convention specified in the Basis
    %             property.  This is the default.
    %         "PerStep" : The rates are treated as per-step rates and the
    %             backtest engine computes interest at the provided rates
    %             at each step of the backtest.
    %
    %   'Basis' : A scalar value that specifies the day count convention
    %       when computing interest at the RiskFreeRate or CashBorrowRate.
    %       The Basis is only used when the RatesConvention property is set
    %       to "Annualized".  Possible values are:
    %
    %                      0 - actual/actual (default)
    %                      1 - 30/360 SIA
    %                      2 - actual/360
    %                      3 - actual/365
    %                      4 - 30/360 PSA
    %                      5 - 30/360 ISDA
    %                      6 - 30E /360
    %                      7 - actual/365 Japanese
    %                      8 - actual/actual ISMA
    %                      9 - actual/360 ISMA
    %                     10 - actual/365 ISMA
    %                     11 - 30/360 ISMA
    %                     12 - actual/365 ISDA
    %                     13 - bus/252
    %
    %   'InitialPortfolioValue' : A scalar that specifies the initial
    %     portfolio value for all strategies.  The default is 10,000.
    %
    % Output:
    %
    %   backtester - backtestEngine object with properties that correspond
    %       to the parameters detailed above.  The backtestEngine object is
    %       used to run backtests of portfolio investment strategies on
    %       historical data.
    %
    %   Additionally the backtestEngine object has the following properties
    %   which are empty until the backtest is run using the runBacktest
    %   method:
    %
    %     * NumAssets : The number of assets in the portfolio universe.
    %       Derived from the timetable of adjusted prices passed into the
    %       runBacktest method.
    %
    %     * Returns : A NumTimeSteps-by-NumStrategies timetable of strategy
    %       returns.  Returns are per time step.  For example if daily
    %       prices are used in the runBacktest method then Returns will be
    %       the daily strategy returns.
    %
    %     * Positions : A struct containing a NumTimeSteps-by-NumAssets
    %       timetable of asset positions for each strategy.  For example if
    %       daily prices are used in the runBacktest method then the
    %       Positions struct will hold timetables containing the daily
    %       asset positions.
    %
    %     * Turnover : A NumTimeSteps-by-NumStrategies timetable of
    %       strategy turnover.
    %
    %     * BuyCost : A NumTimeSteps-by-NumStrategies timetable of
    %       transaction costs for the asset purchases of each strategy.
    %
    %     * SellCost : A NumTimeSteps-by-NumStrategies timetable of
    %       transaction costs for the asset sales of each strategy.
    %
    % Example:
    %
    %    % Load equity adjusted price data and convert to timetable
    %    T = readtable('dowPortfolio.xlsx');
    %    pricesTT = table2timetable(T(:,[1 3:end]),'RowTimes','Dates');
    %
    %    % Create backtest strategy
    %    rebalanceFcn = @(weights,priceWindow) ones(1,numel(weights)) / numel(weights);
    %    equalWeightStrategy = backtestStrategy("EqualWeight",rebalanceFcn);
    %
    %    % Create backtest engine
    %    backtester = backtestEngine(equalWeightStrategy,...
    %        'RiskFreeRate',0.01,...
    %        'InitialPortfolioValue',1e6);
    %
    %    % Run backtest and see results
    %    backtester = runBacktest(backtester,pricesTT);
    %    backtester.summary()
    %
    %   See also BACKTESTSTRATEGY.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        Strategies
        RiskFreeRate
        CashBorrowRate
        RatesConvention
        Basis
        InitialPortfolioValue
    end
    
    properties (SetAccess=private)
        NumAssets
        Returns
        Positions
        Turnover
        BuyCost
        SellCost
    end
    
    properties (Access = private)
        PerStepCashRates
        PerStepMarginRates
    end
    
    methods
        function obj = backtestEngine(strategies, varargin)
            
            if nargin < 1
                strategies = backtestStrategy;
            end
            
            obj.Strategies = strategies;
            
            ip = inputParser;
            ip.addParameter('RiskFreeRate', 0);
            ip.addParameter('CashBorrowRate', 0);
            ip.addParameter('RatesConvention',"Annualized");
            ip.addParameter('Basis',0);
            ip.addParameter('InitialPortfolioValue', 1e4);
            
            ip.parse(varargin{:});
            result = ip.Results;
            
            obj.RiskFreeRate          = result.RiskFreeRate;
            obj.CashBorrowRate        = result.CashBorrowRate;
            obj.RatesConvention       = result.RatesConvention;
            obj.Basis                 = result.Basis;
            obj.InitialPortfolioValue = result.InitialPortfolioValue;
        end
        
        % Property Setters
        function obj = set.Strategies(obj,value)
            % Must be a vector of backtestStrategy objects
            validateattributes(value,"backtestStrategy","vector",mfilename,"Strategies");
            % All non-empty InitialWeights vectors must have same size
            initialWeights = {value.InitialWeights};
            nonEmptyIdx = ~cellfun(@isempty,initialWeights);
            initialWeightsSz = cellfun(@size,initialWeights,'UniformOutput',false);
            specifiedSizes = initialWeightsSz(nonEmptyIdx);
            if ~isempty(specifiedSizes)
                size1 = specifiedSizes{1};
                if ~all(cellfun(@(si) isequal(si, size1), specifiedSizes))
                    error(message('finance:backtest:StrategySizeMismatch'));
                end
            end
            % All strategies must have unique names
            names = [value.Name];
            if numel(names) ~= numel(unique(names))
                error(message('finance:backtest:NonUniqueStrategies'));
            end
            obj.Strategies = value(:)';
        end
        
        function obj = set.RiskFreeRate(obj,value)
            % Must be a numeric scalar
            validateattributes(value,"numeric",...
                ["scalar","nonnan"],mfilename,"RiskFreeRate");
            obj.RiskFreeRate = value;
        end
        
        function obj = set.CashBorrowRate(obj,value)
            % Must be a numeric scalar
            validateattributes(value,"numeric",...
                ["scalar","nonnan"],mfilename,"CashBorrowRate");
            obj.CashBorrowRate = value;
        end
        
        function obj = set.RatesConvention(obj,value)
            % Must be a string with value "Annualized" or "PerStep"
            value = validatestring(value,["Annualized","PerStep"],mfilename,"RatesConvention");
            obj.RatesConvention = value;
        end
        
        function obj = set.Basis(obj,value)
            % Must be a numeric scalar between 0 and 13 inclusive
            validateattributes(value,"numeric",...
                {"scalar","nonnan","integer",">=",0,"<=",13},mfilename,"Basis");
            obj.Basis = value;
        end
        
        function obj = set.InitialPortfolioValue(obj,value)
            % Must be a positive numeric scalar
            validateattributes(value,"numeric",...
                ["scalar","positive","nonnan"],mfilename,"InitialPortfolioValue");
            obj.InitialPortfolioValue = value;
        end
        
        function obj = runBacktest(obj, pricesTT, varargin)
            % Run backtest.
            %
            % Syntax:
            %
            %   backtester = runBacktest(backtester, pricesTT)
            %   backtester = runBacktest(backtester, pricesTT, param1, value1,...)
            %
            %   backtester = runBacktest(backtester, pricesTT, signalTT)
            %   backtester = runBacktest(backtester, pricesTT, signalTT, param1, value1,...)
            %
            % Description:
            %
            %   The runBacktest method runs the backtest of the strategies
            %   using the adjusted asset price data as well as the signal
            %   data if provided.  After completion, runBacktest will
            %   populate several properties in the backtestEngine object
            %   with the results of the backtest.
            %
            % Input arguments:
            %
            %   pricesTT - Asset prices.  A timetable of asset prices used
            %     by the backtestEngine to backtest the strategies.  Must
            %     be specified as a timetable where each column contains a
            %     time series of prices for an investible asset. Historical
            %     prices should be adjusted for splits and dividends.
            %
            %   signalTT - Signal data.  A timetable of trading signal data
            %     that the strategies can use to make trading decisions.
            %     The signal argument is optional.  If provided, the
            %     backtestEngine will call the strategy rebalance functions
            %     with both asset price data as well as signal data.  The
            %     signal data timetable must have the same time dimension
            %     as the asset price timetable.
            %
            % Optional Input Parameter Name/Value Pairs:
            %
            %   'Start' : A scalar that sets the starting time/row for the
            %     backtest.
            %
            %   'End' : A scalar that sets the ending time/row for the
            %     backtest.
            %
            %   The 'Start' and 'End' parameters set the start and end
            %   points for the backtest.  They can be either integers or
            %   datetime objects.  If specified as integers, they define
            %   the row in the prices timetable where the backtest will
            %   start and end, respectively.
            %
            %   If specified as a datetime, the backtest will begin at the
            %   first time in the prices timetable that occurs on or after
            %   the 'Start' parameter.  The backtest will end on the last
            %   time in the prices timetable that occurs on or before the
            %   'End' parameter.  In essence the 'Start' and 'End'
            %   parameters set the boundary of the data that is included in
            %   the backtest.
            %
            %   The default value for 'Start' and 'End' is the first and
            %   last rows of the dataset, meaning all data is used in the
            %   backtest.
            %
            %  The runBacktest method initializes each strategy to the
            %  InitialPortfolioValue and begins walking through the
            %  asset price data.
            %
            %  At each time step the engine applies the asset returns to
            %  all assets positions. The engine then determines if the
            %  strategy needs to be rebalanced based on the
            %  RebalanceFrequency and LookbackWindow properties of the
            %  backtestStrategy objects.
            %
            %  For strategies that need rebalancing, the backtestEngine
            %  calls their rebalance functions with a rolling window of
            %  asset price data (and signal data if provided) based on the
            %  LookbackWindow property of each strategy.
            %
            %  Transaction costs are then paid based on the changes in
            %  asset positions and the TransactionCosts property of the
            %  backtestStrategy objects.
            %
            %  After completing the backtest, the results are stored in
            %  several properties.  See the help for backtestEngine and
            %  backtestStrategy for more details.
            
            % Verify we have a valid prices timetable
            if ~isa(pricesTT,'timetable')
                error(message('finance:backtest:InvalidAssetTT'));
            end
            pricesTimeDim = pricesTT.Properties.DimensionNames{1};
            priceTimes = pricesTT.(pricesTimeDim);
            
            % Parse out and validate Start and End times before checking
            % for missing data.
            ip = inputParser;
            ip.addOptional('SignalTT', []);
            ip.addParameter('Start', 1);
            ip.addParameter('End', size(pricesTT,1));
            
            ip.parse(varargin{:});
            
            signalTT = ip.Results.SignalTT;
            
            % Validate start and end
            [startRow,endRow] = validateStartEnd(priceTimes,...
                ip.Results.Start,ip.Results.End);
            
            % Validate asset prices in backtest range
            missingPrices = ismissing(pricesTT(startRow:endRow,:));
            if any(missingPrices(:))
                error(message('finance:backtest:MissingAssetData'));
            end
            
            % Validate signal data
            if isempty(signalTT)
                signalSpecified = false;
            else
                signalSpecified = true;
                if ~isa(signalTT,'timetable')
                    error(message('finance:backtest:InvalidSignalTT'));
                end
                % Verify sizes match before checking for missing values
                % since start and end times were validated against the
                % prices timetable
                if size(pricesTT,1) ~= size(signalTT,1)
                    error(message('finance:backtest:SignalSizeMismatch'));
                end
                missingSignals = ismissing(signalTT(startRow:endRow,:));
                if any(missingSignals(:))
                    error(message('finance:backtest:MissingSignalData'));
                end
                signalTimeDim = signalTT.Properties.DimensionNames{1};
                signalTimes = signalTT.(signalTimeDim);
                if ~isequal(priceTimes,signalTimes)
                    error(message('finance:backtest:SignalTimeMismatch'));
                end
            end
            
            % Check for objects saved from older version of MATLAB
            obj = releaseCompatibilityCheck(obj);
            
            % Backtest time steps are in terms of returns, not prices
            numTimeSteps  = endRow - startRow;
            assetReturns  = tick2ret(pricesTT);

            obj.NumAssets = size(assetReturns.Variables,2);
            assetIdx      = 2:obj.NumAssets+1;

            % Compute per step cash account rates
            [obj.PerStepCashRates, obj.PerStepMarginRates] = computeCashReturns(obj,...
                priceTimes,startRow,endRow);
            
            strategies  = obj.Strategies;
            nStrategies = numel(strategies);
            
            % Variables to store intermediary results
            returns  = zeros(numTimeSteps, nStrategies);
            turnover = zeros(numTimeSteps, nStrategies);
            buycost  = zeros(numTimeSteps, nStrategies);
            sellcost = zeros(numTimeSteps, nStrategies);
            
            initialPositions = zeros(nStrategies, obj.NumAssets+1);
            
            startTime = priceTimes(startRow);
            
            % Run backtest for each strategy
            for i = 1:numel(strategies)
                
                % Initialize position array
                stratName = strategies(i).Name;
                positionsEOD.(stratName) = zeros(numTimeSteps, obj.NumAssets + 1);
                
                % Set initial positions
                if ~isempty(strategies(i).InitialWeights)
                    
                    % If the strategy specifies initial weights, set them
                    if numel(strategies(i).InitialWeights) ~= obj.NumAssets
                        error(message('finance:backtest:InvalidInitialWeightsSize'));
                    end
                    initialPositions(i,:) = obj.InitialPortfolioValue *...
                        [1 - sum(strategies(i).InitialWeights) strategies(i).InitialWeights];
                else
                    
                    % Otherwise, if no weights are set, we begin all in cash
                    initialPositions(i,:) = [obj.InitialPortfolioValue zeros(1,obj.NumAssets)];
                end
                
                % Find all rebalance rows
                isRebalanceRow = computeRebalanceRows(priceTimes, startRow,...
                    strategies(i).RebalanceFrequency);
                
                % Run backtest
                prevPositions = initialPositions(i,:);
                prevWeights   = prevPositions / obj.InitialPortfolioValue;
                for btIdx = 1:numTimeSteps
                    
                    % time step returns
                    returnIdx     = btIdx + (startRow - 1);
                    assetReturnsi = assetReturns{returnIdx,:};
                    cashReturni   = obj.PerStepCashRates(btIdx);
                    marginInti    = obj.PerStepMarginRates(btIdx);
                    
                    % current row in price/signal tables
                    btIdxRow = btIdx + startRow;
                    
                    % Start of day positions
                    sodPositions = prevPositions;
                    sodPortValue = sum(sodPositions);
                    
                    % Daily returns
                    if 0 <= sodPositions(1)
                        % Zero or positive cash
                        retn = 1 + [cashReturni assetReturnsi];
                    else
                        % Negative cash
                        retn = 1 + [marginInti assetReturnsi];
                    end
                    
                    % Assets positions with invalid returns (nan or Inf)
                    % are not allowed
                    invalidIdx = ~isfinite(retn);
                    if 1e3 * eps < sum(abs(prevWeights(invalidIdx)))
                        invalidTimeIdx = returnIdx + 1;
                        invalidTime = string(pricesTT.(pricesTimeDim)(invalidTimeIdx));
                        invalidAssetIdx = find(invalidIdx,1)-1;
                        invalidAsset = pricesTT.Properties.VariableNames{invalidAssetIdx};
                        error(message('finance:backtest:NonfiniteReturn',invalidAsset,invalidTime));
                    end
                    retn(invalidIdx) = 0;
                    
                    % Apply current day's return
                    eodPositions = sodPositions .* retn;
                    eodPortValue = sum(eodPositions);
                    eodAssetWeights = eodPositions(assetIdx) / eodPortValue;
                    
                    % Rebalance if necessary
                    if isRebalanceRow(btIdxRow)
                        
                        % Verify we have enough data for lookback window
                        if isnumeric(strategies(i).LookbackWindow)
                            % lookback window defined in rows
                            validWindow = 0 <= btIdxRow - strategies(i).LookbackWindow(1);
                            if validWindow
                                windowStartRow = btIdxRow - strategies(i).LookbackWindow(end) + 1;
                                windowRows = max(1,windowStartRow):btIdxRow;
                            end
                        else
                            % lookback window defined as a duration or
                            % calendarDuration
                            minStartTime = priceTimes(btIdxRow) - strategies(i).LookbackWindow(1);
                            validWindow = startTime <= minStartTime;
                            if validWindow
                                windowStartTime = priceTimes(btIdxRow) - strategies(i).LookbackWindow(end);
                                windowStartRow = find(windowStartTime <= priceTimes,1,'first');
                                windowRows = windowStartRow:btIdxRow;
                            end
                        end
                        
                        if validWindow
                            
                            % Generate rolling windows
                            assetLookbackData = pricesTT(windowRows, :);
                            
                            % Rebalance
                            if signalSpecified && nargin(strategies(i).RebalanceFcn) ~= 2
                                % Signal data was specified and rebalance
                                % function will take 3 inputs or varargin.
                                signalLookbackData = signalTT(windowRows, :);
                                strategies(i) = rebalance(strategies(i), eodAssetWeights, assetLookbackData, signalLookbackData);
                            else
                                strategies(i) = rebalance(strategies(i), eodAssetWeights, assetLookbackData);
                            end
                            eodAssetWeightsUpdated = strategies(i).Weights;
                            
                            % Positive weights always correspond to long
                            % positions.
                            eodAssetWeightsUpdated = checkWeightsSign(eodPortValue,eodAssetWeightsUpdated);
                            
                            deltaWeights = eodAssetWeightsUpdated - eodAssetWeights;
                            
                            % Record daily metrics
                            turnover(btIdx,i) = sum(abs(deltaWeights)) / 2;
                            [buycost(btIdx,i), sellcost(btIdx,i)] = strategies(i).computeTransactionCosts(...
                                eodPortValue * deltaWeights);
                            
                            % Pay transaction fees & update weights
                            preFeesPortValue = eodPortValue;
                            eodPortValue = eodPortValue - buycost(btIdx, i) - sellcost(btIdx, i);
                            
                            % Check if the fees pushed the portfolio value
                            % negative.
                            eodAssetWeights = checkWeightsSign(eodPortValue,eodAssetWeightsUpdated,preFeesPortValue);
                            
                        end
                    end
                    
                    % Update EOD positions given new weights
                    eodWeights = [1-sum(eodAssetWeights) eodAssetWeights];
                    eodPositions = eodPortValue * eodWeights;
                    
                    % Record positions and returns
                    positionsEOD.(strategies(i).Name)(btIdx, :) = eodPositions;
                    returns(btIdx, i) = eodPortValue / sodPortValue - 1;
                    
                    prevWeights   = eodWeights;
                    prevPositions = eodPositions;
                end
            end
            
            VarNames = ["Cash", assetReturns.Properties.VariableNames];
            
            % Positions uses the prices time since it includes initial T=0
            Time = priceTimes(startRow:endRow);
            for i = 1:numel(strategies)
                stratName = strategies(i).Name;
                
                % Add the initial positions to the position data
                positionData = [initialPositions(i,:); positionsEOD.(stratName)];
                positionTable = array2table(positionData, 'VariableNames', VarNames);
                positionTable = addvars(positionTable, Time, 'Before', "Cash");
                obj.Positions.(stratName) = table2timetable(positionTable);
            end
            
            % Remaining metrics use returns times
            Time = assetReturns.(pricesTimeDim)(startRow:endRow-1);
            
            % Extract strategy names
            stratsName = [strategies.Name];
            
            returns = array2table(returns,'VariableNames',stratsName);
            returns = addvars(returns, Time,'Before',stratsName{1});
            obj.Returns = table2timetable(returns);
            
            turnover = array2table(turnover,'VariableNames',stratsName);
            turnover = addvars(turnover, Time,'Before',stratsName{1});
            obj.Turnover = table2timetable(turnover);
            
            buycost = array2table(buycost,'VariableNames',stratsName);
            buycost = addvars(buycost, Time,'Before',stratsName{1});
            obj.BuyCost = table2timetable(buycost);
            
            sellcost = array2table(sellcost,'VariableNames',stratsName);
            sellcost = addvars(sellcost, Time,'Before',stratsName{1});
            obj.SellCost = table2timetable(sellcost);
        end
        
        
        function summaryTable = summary(obj)
            % Generate summary table of backtest results.
            %
            % Syntax:
            %
            %   summaryTable = summary(backtester)
            %
            % Description:
            %
            %   The summary method generates a table of metrics to
            %   summarize the backtest.  Each row of the table is a
            %   calculated metric and each column represents a strategy.
            %
            %   The reported metrics are:
            %
            %   TotalReturn - The total return of the strategy over the
            %       entire backtest.
            %   SharpeRatio - The Sharpe ratio for each strategy.
            %   Volatility - The volatility of each strategy over the
            %       backtest.
            %   AverageTurnover - Average turnover per time step as a
            %       decimal percent.
            %   MaxTurnover - Maximum turnover in a single time step.
            %   AverageReturn - Average return per time step.
            %   MaxDrawdown - Maximum portfolio drawdown as a decimal percent.
            %   AverageBuyCost - Average per time step transaction costs
            %       for asset purchases.
            %   AverageSellCost - Average per time step transaction costs
            %       for asset sales.
            
            if isempty(obj.Positions)
                error(message('finance:backtest:NoDataSummary'));
            end
            
            % Compute metrics summary table
            dailyReturns    = obj.Returns.Variables;
            averageReturns  = mean(dailyReturns);
            stdReturns      = std(dailyReturns);
            sharpeRatio     = sharpe(dailyReturns,obj.PerStepCashRates);
            compoundReturns = ret2tick(dailyReturns, 'method', 'simple');
            
            % maxdrawdown does not support non-positive portfolio values
            maxDrawdown = nan(size(sharpeRatio));
            positiveIdx = all(0 < compoundReturns);
            if any(positiveIdx)
                maxDrawdown(positiveIdx) = maxdrawdown(compoundReturns(:,positiveIdx));
            end
            
            totalReturn = compoundReturns(end, :)-1;
            avgTurnover = mean(obj.Turnover.Variables);
            avgBuyCost  = mean(obj.BuyCost.Variables);
            avgSellCost = mean(obj.SellCost.Variables);
            maxTurnover = max(obj.Turnover.Variables);
            
            metricData = [totalReturn', sharpeRatio', stdReturns',...
                avgTurnover', maxTurnover', averageReturns', ...
                maxDrawdown', avgBuyCost', avgSellCost']';
            
            metricNames = ["TotalReturn",  "SharpeRatio", "Volatility",...
                "AverageTurnover", "MaxTurnover", "AverageReturn", ...
                "MaxDrawdown", "AverageBuyCost", "AverageSellCost"];
            
            colStratsNames = (obj.Returns.Properties.VariableNames)';
            
            summaryTable = array2table(metricData, 'VariableNames', colStratsNames, 'RowNames', metricNames);
            
        end
        
        
        function h = equityCurve(varargin)
            % Plot equity curves of strategies.
            %
            % Syntax:
            %
            %   equityCurve(backtester);
            %   h = equityCurve(ax,backtester);
            %
            % Description:
            %
            %   Plot the equity curves of each strategy to compare their
            %   performance after running a backtest.  The equity curves
            %   track the total portfolio value through the duration of the
            %   backtest.
            %
            % Input Arguments:
            %
            %   ax - Axes object in which to plot.  If an axes object is
            %     specified, the backtest engine will plot the equity
            %     curves into the provided axes.
            %
            % Output Argument:
            %
            %   h - Vector of handles to the line objects created.
            
            nargoutchk(0,1)
            narginchk(1,2)
            
            % Parse out first argument plot parent if one is provided.
            [ax,args] = internal.finance.axesparser(varargin{:});
            
            if ~isempty(ax) && ~isscalar(ax)
                error(message('finance:internal:finance:axesparser:ScalarAxes'));
            end
            obj = args{1};
            
            % Can only run after backtest has completed
            if isempty(obj.Positions)
                error(message('finance:backtest:NoDataPlots'));
            end
            
            % Call newplot if no parent axes is specified
            if isempty(ax)
                ax = newplot;
            end
            
            % Store NextPlot flag (and restore on cleanup)
            nextPlotVal = get(ax,'NextPlot');
            cleanupObj = onCleanup(@() set(ax,'NextPlot',nextPlotVal));
            
            % Compute running portfolio balances
            numStrat = numel(obj.Strategies);
            numDates = size(obj.Returns,1) + 1;
            portfolioValues = zeros(numDates,numStrat);
            for i = 1:numStrat
                posi = obj.Positions.(obj.Strategies(i).Name);
                portfolioValues(:,i) = sum(posi.Variables,2);
            end
            portfolioTimes = posi.Time;
            
            % Plot portfolio equity curves
            hPlot = plot(ax,portfolioTimes,portfolioValues,...
                'Tag','EquityCurve');
            
            % Remove underscores from strategy names
            names = [obj.Strategies.Name];
            nameLabels = strrep(names,'_',' ');
            
            % Set datatips
            for i = 1:length(hPlot)
                hPlot(i).DisplayName = nameLabels(i);
                hPlot(i).DataTipTemplate.DataTipRows(1).Label = 'Time';
                hPlot(i).DataTipTemplate.DataTipRows(2).Label = 'Value';
                row = dataTipTextRow('Strategy',repmat(nameLabels(i),1,length(hPlot(i).XData)));
                hPlot(i).DataTipTemplate.DataTipRows(end+1) = row;
            end
            
            switch nextPlotVal
                case {'replace','replaceall'}
                    ax.Title.String = 'Equity Curve';
                    ax.XLabel.String = 'Time';
                    ax.YLabel.String = 'Portfolio Value';
                    
                    % Make legend semi transparent
                    lgnd = legend(ax,hPlot,'Location','best');
                    lgnd.BoxFace.ColorType = 'truecoloralpha';
                    lgnd.BoxFace.ColorData = [lgnd.BoxFace.ColorData(1:3);uint8(200)];

                    grid(ax)
                    
                case {'replacechildren','add'}
                    % Do not modify axes properties
            end
            
            if nargout > 0
                h = hPlot;
            end
        end
    end
    
    
    methods (Access=protected)
        
        function obj = releaseCompatibilityCheck(obj)
            
            % Engine objects saved in R2020b will have RatesConvention and
            % Basis set to empty.  We set RatesConvention to 'PerStep' as
            % that was the default behavior in R2020b.
            if isempty(obj.RatesConvention)
                obj.RatesConvention = "PerStep";
            end
            if isempty(obj.Basis)
                obj.Basis = 0;
            end
            
        end
        
        function [cashReturns, marginInterest] = computeCashReturns(obj,times,startRow,endRow)
            nReturns = size(times,1) - 1;
            if obj.RatesConvention == "PerStep"
                cashReturns = repmat(obj.RiskFreeRate,nReturns,1);
                marginInterest = repmat(obj.CashBorrowRate,nReturns,1);
            else
                timeDeltas = yearfrac(times(1:end-1),times(2:end),...
                    obj.Basis);
                cashReturns = timeDeltas(:) * obj.RiskFreeRate;
                marginInterest = timeDeltas(:) * obj.CashBorrowRate;
            end
            
            % Return only the values over the backtest timespan
            cashReturns    = cashReturns(startRow:endRow-1);
            marginInterest = marginInterest(startRow:endRow-1);
            
        end
        
    end
    
end

function [startRow,endRow] = validateStartEnd(priceTimes,startParam,endParam)

% Validation of class and size
validateattributes(startParam,["numeric","datetime"],"scalar","runBacktest","Start");
validateattributes(endParam,  ["numeric","datetime"],"scalar","runBacktest","End");

maxRow = size(priceTimes,1);

% Convert datetime to row index
if isa(startParam,'numeric')
    if floor(startParam) ~= startParam
        error(message('finance:backtest:FractionalStartEnd'));
    end
    startRow = startParam;
else
    % This returns empty if startRow is out of range on the right side
    startRow = find(startParam <= priceTimes,1,'first');
end
if isa(endParam,'numeric')
    if floor(endParam) ~= endParam
        error(message('finance:backtest:FractionalStartEnd'));
    end
    endRow = endParam;
else
    % This returns empty if endRow is out of range on the left side
    endRow = find(priceTimes <= endParam,1,'last');
end

% Check for out of range
if isempty(startRow) || startRow < 1 || maxRow < startRow
    error(message('finance:backtest:InvalidStart'));
end
if isempty(endRow) || endRow < 1 || maxRow < endRow
    error(message('finance:backtest:InvalidEnd'));
end

% Verify start occurs before end
if endRow <= startRow
    error(message('finance:backtest:InvalidStartEnd'));
end

end


function isRebalanceRow = computeRebalanceRows(priceTimes,startRow,rebalFreq)

numRows = size(priceTimes,1);
isRebalanceRow = false(numRows,1);

if isnumeric(rebalFreq)
    isRebalanceRow(startRow:rebalFreq:numRows) = true;
end

if isa(rebalFreq,'duration') || isa(rebalFreq,'calendarDuration')
    % Convert to a vector of datetimes and validate below
    rebalFreq = priceTimes(startRow):rebalFreq:priceTimes(end);
end

if isa(rebalFreq,'datetime')
    % Find first date on or before each rebalance date
    rebalRows = zeros(numel(rebalFreq),1);
    for i = numel(rebalFreq):-1:1
        % We iterate backwards here because if find returns empty then it
        % will remove that element from the rebalRows vector.  Iterating
        % backwards allows this to happen and the remaining loop indices
        % are still valid.
        rebalRowi = find(priceTimes <= rebalFreq(i),1,'last');
        if ~isempty(rebalRowi)
            rebalRows(i) = rebalRowi;
        else
            rebalRows(i) = [];
        end
    end
    % Remove dupes
    rebalRows = unique(rebalRows);
    isRebalanceRow(rebalRows) = true;
end

end

function weights = checkWeightsSign(portValue,weights,prevPortValue)
% Negates weights if portfolio value falls from positive to negative

if nargin < 3
    prevPortValue = 1;
end

if portValue < 0 && 0 <= prevPortValue
    weights = -weights;
    
end

end
