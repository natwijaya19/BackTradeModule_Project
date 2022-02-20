classdef Test_BacktestStrategy < matlab.mixin.Heterogeneous
    %BACKTESTSTRATEGY Strategy for portfolio backtesting.
    %
    % Syntax:
    %
    %   strat = backtestStrategy(name, rebalanceFcn)
    %   strat = backtestStrategy(name, rebalanceFcn, param1, value1,...)
    %
    % Description:
    %
    %   BACKTESTSTRATEGY takes as input a name and a function handle which
    %   specifies how the strategy will rebalance a portfolio of assets.
    %   BACKTESTSTRATEGY objects are used with the BACKTESTENGINE class to
    %   backtest portfolio trading strategies against historical market
    %   data.
    %
    % Input arguments:
    %
    %   name - Strategy name.  A string identifying the strategy.  Cannot
    %     contain special characters except for underscores.
    %
    %   rebalanceFcn - A function handle that computes new portfolio
    %     weights during the backtest.  The rebalanceFcn implements the
    %     core logic of the trading strategy and must have one of the
    %     following signatures:
    %
    %     new_weights = rebalanceFcn(weights,assetPrices)
    %     new_weights = rebalanceFcn(weights,assetPrices,signalData)
    %
    %     The rebalance function is called by the backtestEngine each time
    %     the strategy must be rebalanced.  The backtestEngine calls the
    %     rebalance function with the following arguments:
    %
    %       * weights: the current portfolio weights before rebalancing,
    %         specified as decimal percentages.
    %       * assetPrices: a timetable containing a rolling window of
    %         adjusted asset prices.
    %       * signalData: a timetable containing a rolling window of signal
    %         data.  If signal data is provided to the backtestEngine then
    %         the engine object will pass it to the strategy rebalance
    %         function (3 input argument syntax).  If signal data is not
    %         provided to the backtestEngine then the rebalance function
    %         will be called with the 2 input argument syntax.
    %
    %     The rebalance function must return a single output argument:
    %
    %       * new_weights: a vector of asset weights specified as decimal
    %         percentages.  If the new weights sum to 1 then the portfolio
    %         is fully invested.  If the weights sum to less than 1 then
    %         the portfolio will have the remainder in cash, earning the
    %         RiskFreeRate (specified in the backtestEngine).  If the
    %         weights sum to more than 1 then there will be a negative cash
    %         position (margin) and the cash borrowed will accrue interest
    %         at the CashBorrowRate (specified in the backtestEngine).
    %
    % Optional Input Parameter Name/Value Pairs:
    %
    %   'RebalanceFrequency' : The frequency or schedule used for
    %     rebalancing the strategy. Can be specified in the following ways:
    %
    %     * A scalar integer that specifies how many rows of data are
    %         processed between each rebalance.  For example if the
    %         backtestEngine is provided with daily price data, then the
    %         RebalanceFrequency would specify the number of days between
    %         rebalancing.
    %
    %     * A scalar duration or calendarDuration object.  If specified as
    %         a duration, the backtest engine creates a rebalance schedule
    %         of times, starting at the backtest start time, with rebalance
    %         times occurring after each step of the specified duration.
    %
    %     * A vector of datetime objects.  If specified as a vector of
    %         datetime objects, the RebalanceFrequency defines an explicit
    %         schedule of rebalance times.  The backtest engine will
    %         rebalance at each datetime in the provided schedule.
    %
    %       For both the duration and datetime syntaxes, if a rebalance
    %       time is not found in the backtest dataset, the engine will
    %       rebalance at the nearest time prior to the scheduled time.  For
    %       example, if the rebalance schedule contains a weekend, the
    %       rebalance will occur on the Friday before.
    %
    %     The default is 1, meaning the strategy rebalances with each time
    %     step.
    %
    %   'TransactionCosts' : The transaction costs for trades.  Can be
    %     specified in the following ways:
    %
    %       * rate: A scalar decimal percentage charge to both purchases
    %           and sales of assets.  For example if TransactionCosts were
    %           set to 0.001, then each transaction (buys and sells) would
    %           pay 0.1% in transaction fees.
    %       * [buyRate, sellRate]: A 1-by-2 vector of decimal percentage
    %           rates that specifies separate rates for buying vs. selling
    %           of assets.
    %       * computeTransactionCostsFcn: A function handle to compute
    %           customized transaction costs.  If specified as a function
    %           handle, the backtestEngine will call the TransactionCosts
    %           function to compute the fees for each rebalance.  The
    %           provided function must have the following signature:
    %
    %             [buyCosts,sellCosts] = computeCostsFcn(deltaPositions)
    %
    %           It must take a single input argument, deltaPositions, which
    %           is a vector of changes in asset positions for all assets
    %           (in currency units) as a result of a rebalance.  Positive
    %           elements in the deltaPositions vector indicate purchases
    %           while negative entries represent sales.  The function
    %           handle must return two output arguments, buyCosts and
    %           sellCosts, which contain the total costs (in currency) for
    %           the entire rebalance for each type of transaction.
    %
    %     The default TransactionCosts is 0, mean transaction costs are not
    %     computed.
    %
    %   'LookbackWindow' : A 1-by-2 vector that specifies the minimum and
    %       maximum size (as [min max]) of the rolling windows of data
    %       (asset prices and signal data) that the backtest engine
    %       provides to the strategy rebalance function.  The lookback
    %       window can be specified using either numeric integers, duration
    %       objects, or calendarDuration objects.
    %
    %       When specified as integers, the lookback window is defined in
    %       terms of rows of data from the asset and signal timetables used
    %       in the backtest.  The lookback minimum sets the minimum number
    %       of rows of asset price data that must be available to the
    %       rebalance function before a strategy rebalance can occur. The
    %       lookback maximum sets the maximum size for the rolling window
    %       of price data that is passed to the rebalance function.
    %
    %       When specified using duration or calendarDuration objects, the
    %       lookback window minimum and maximum are defined in terms of
    %       timespans relative to the time at a rebalance.  For example if
    %       the lookback minimum was set to 5 days (i.e. days(5)), the
    %       rebalance will only occur if the backtest start time is at
    %       least 5 days prior to the rebalance time.
    %
    %       Similarly, if the lookback maximum was set to 6 months (i.e.
    %       calmonths(6)), the lookback window would contain only data that
    %       occurred at 6 months prior to the rebalance time or later.
    %
    %       The default LookbackWindow is [0 Inf], meaning all available
    %       past data is given to the rebalance function.
    %
    %       Alternatively, the LookbackWindow can be set to a single scalar
    %       value indicating that the rolling window should be exactly that
    %       size (either in terms of rows or a time duration).  The minimum
    %       and maximum size will both be set to the provided value.
    %
    %   'InitialWeights' : A vector of initial portfolio weights.  The
    %       InitialWeights vector sets the portfolio weights before the
    %       backtestEngine begins the backtest.  The size of the initial
    %       weights vector must match the number of assets used in the
    %       backtest.
    %
    %       Alternatively, you can set the InitialWeights to empty ([]),
    %       indicating the strategy will begin uninvested and in a 100%
    %       cash position.  The default is empty ([]).
    %
    % Output:
    %
    %   strategy - backtestStrategy object with properties that correspond
    %       to the parameters detailed above.  The backtestStrategy object
    %       is used in conjunction with the backtestEngine class to run
    %       backtests of portfolio investment strategies on historical
    %       data.
    %
    % Example:
    %
    %    % Load equity adjusted price data and convert to timetable
    %    T = readtable('dowPortfolio.xlsx');
    %    pricesTT = table2timetable(T(:,[1 3:end]),'RowTimes','Dates');
    %
    %    % Create backtest strategy
    %    rebalanceFcn = @(weights,priceWindow) ones(1,numel(weights)) / numel(weights);
    %    equalWeightStrategy = backtestStrategy("EqualWeight",rebalanceFcn,...
    %        'RebalanceFrequency',10,'TransactionCosts',[0.005 0.0025]);
    %
    %    % Create backtest engine
    %    backtester = backtestEngine(equalWeightStrategy);
    %
    %    % Run backtest and see results
    %    backtester = runBacktest(backtester,pricesTT);
    %    backtester.summary()
    %
    %   See also BACKTESTENGINE.
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        Name
        RebalanceFcn
        RebalanceFrequency
        TransactionCosts
        LookbackWindow
        InitialWeights
    end
    
    properties (SetAccess=protected, Hidden=true)
        Weights
    end
    
    methods
        function obj = Test_BacktestStrategy(name, rebalanceFcn, varargin)
            
            if nargin < 1
                name = "DefaultStrategy";
                rebalanceFcn = @(w,~,~) w;
            end
            
            obj.Name         = name;
            obj.RebalanceFcn = rebalanceFcn;
            
            ip = inputParser;
            ip.addParameter('RebalanceFrequency', 1);
            ip.addParameter('TransactionCosts', 0);
            ip.addParameter('LookbackWindow', [0 Inf]);
            ip.addParameter('InitialWeights', []);
            
            ip.parse(varargin{:});
            result = ip.Results;
            
            obj.RebalanceFrequency = result.RebalanceFrequency;
            obj.TransactionCosts   = result.TransactionCosts;
            obj.LookbackWindow     = result.LookbackWindow;
            obj.InitialWeights     = result.InitialWeights;
        end
        
        % Property Setters
        function obj = set.Name(obj,value)
            % Must be a string or character vector
            validateattributes(value,["char","string"],"nonempty",mfilename,"Name");
            % Must be string and convertible to a valid variable name
            value = strrep(string(value)," ","_");
            if ~isvarname(value)
                error(message('finance:backtest:NoSpecialChars'));
            end
            obj.Name = value;
        end
        
        function obj = set.RebalanceFcn(obj,value)
            % Must be a function handle
            validateattributes(value,"function_handle","nonempty",mfilename,"RebalanceFcn");
            in  = nargin(value);
            out = nargout(value);
            validIn  = in < 0 || in == 2 || in == 3;
            validOut = out < 0 || out == 1;
            if validIn && validOut
                obj.RebalanceFcn = value;
            else
                error(message('finance:backtest:InvalidRebalanceFcn'));
            end
        end
        
        function obj = set.RebalanceFrequency(obj,value)
            % Validate class
            validateattributes(value,["numeric","datetime","duration","calendarDuration"],...
                {},mfilename,"RebalanceFrequency");
            
            if any(ismissing(value(:)))
                error(message('finance:backtest:MissingRebalance'));
            end
            
            % If numeric, validate it's nonnegative scalar integer
            if isnumeric(value) &&...
                    ~(isscalar(value) && 0 <= value && floor(value) == value)
                error(message('finance:backtest:InvalidNumericRebalFreq'));
            end
            
            % If duration, validate it's nonnegative scalar
            if isa(value,'duration') && ~(isscalar(value) && 0 <= value)
                error(message('finance:backtest:InvalidDurationRebalFreq'));
            end
            
            % If calendarDuration, validate it's scalar.  calendarDuration
            % objects have no sense of positive or negative and do not
            % support the < or > operators.
            if isa(value,'calendarDuration') && ~isscalar(value)
                error(message('finance:backtest:InvalidCalendarDurationRebalFreq'));
            end
            
            % If datetime, validate it's a vector and sort it
            if isa(value,'datetime')
                if ~isvector(value)
                    error(message('finance:backtest:InvalidDatetimeRebalFreq'));
                end
                value = sort(value(:));
            end
            
            obj.RebalanceFrequency = value;
        end
        
        function obj = set.TransactionCosts(obj,value)
            % Must be a 1 or 2 element vector or else a function handle
            validateattributes(value,["numeric","function_handle"],...
                {},mfilename,"TransactionCosts");
            
            % If numeric, 1 or 2 element vector
            if isnumeric(value)
                if ismember(numel(value),[1 2]) && ~any(isnan(value(:)))
                    obj.TransactionCosts = value(:)';
                else
                    error(message('finance:backtest:InvalidNumericTransactionCosts'));
                end
            else
                % Function handle validation
                in  = nargin(value);
                out = nargout(value);
                validIn  = in < 0 || in == 1;
                validOut = out < 0 || out == 2;
                if validIn && validOut
                    obj.TransactionCosts = value;
                else
                    error(message('finance:backtest:InvalidTransactionCostsFunction'));
                end
            end
        end
        
        function obj = set.LookbackWindow(obj,value)
            % Must be 1 or 2 element nonnan sorted vector
            validateattributes(value,["numeric","duration","calendarDuration"],...
                ["vector","nonnan"],mfilename,"LookbackWindow");
            
            % Check for non-negative and non-fractional (for numeric)
            if isnumeric(value)
                validateattributes(value,"numeric",...
                    "nonnegative",mfilename,"LookbackWindow");
                if ~all(value(:) == floor(value(:)))
                    error(message('finance:backtest:FractionalLookback'));
                end
            elseif isa(value,"duration")
                if any(value(:) < duration(0,0,0))
                    error(message('finance:backtest:NegativeLookback'));
                end
            end
            
            % Must be 1 or 2 elements
            if ~ismember(numel(value),[1 2])
                error(message('finance:backtest:LookbackWindowSize'));
            end
            % Must be sorted.  calendarDuration do not support sorting.
            if ~isa(value,'calendarDuration')
                if sort(value(:)) ~= value(:)
                    error(message('finance:backtest:LookbackWindowOrder'));
                end
            end
            
            obj.LookbackWindow = value(:)';
        end
        
        function obj = set.InitialWeights(obj,value)
            % Must be empty or a numeric vector
            if isnumeric(value) && ~any(isnan(value(:))) && (isempty(value) || isvector(value))
                obj.InitialWeights = value(:)';
            else
                error(message('finance:backtest:InvalidInitialWeights'));
            end
        end
        
        function obj = set.Weights(obj,value)
            % Must be a numeric vector
            validateattributes(value,"numeric",["vector","nonnan"],mfilename,"Weights");
            obj.Weights = value(:)';
        end
        
        function obj = rebalance(obj, currentWeights, prices, signal)
            % Rebalance portfolio weights.
            %
            % Syntax:
            %
            %   obj = rebalance(obj, currentWeights, prices)
            %   obj = rebalance(obj, currentWeights, prices, signal)
            %
            % Description:
            %
            %   The REBALANCE method is called by the backtestEngine to
            %   rebalance the portfolio positions of the backtestStrategy
            %   object using the function handle stored in the RebalanceFcn
            %   property.  See the help for the backtestStrategy class for
            %   details on how to specify the RebalanceFcn property.
            
            if nargin < 4
                obj.Weights = obj.RebalanceFcn(currentWeights, prices);
            else
                obj.Weights = obj.RebalanceFcn(currentWeights, prices, signal);
            end
        end
        
        function [buy, sell] = computeTransactionCosts(obj, deltaPositions)
            % Compute transaction costs from changes in asset positions.
            %
            % Syntax:
            %
            %   [buy, sell] = computeTransactionCosts(obj, deltaPositions)
            %
            % Description:
            %
            %   The COMPUTETRANSACTIONCOSTS method is called by the
            %   backtestEngine to compute the transaction costs incurred
            %   during a rebalance of the portfolio positions of the
            %   backtestStrategy object using the costs set in the
            %   TransactionCosts property.  See the help for the
            %   backtestStrategy class for details on how to specify the
            %   TransactionCosts property.
            
            if isa(obj.TransactionCosts,'function_handle')
                [buy, sell] = obj.TransactionCosts(deltaPositions);
            else
                rate = obj.TransactionCosts;
                [buy, sell] = percentTransactionCosts(deltaPositions, rate);
            end
        end
    end
end

function [buy, sell] = percentTransactionCosts(deltaMktValue,rate)
% Flat percentile for transaction costs

if isscalar(rate)
    rate = [rate rate];
end
buy  = sum(max( deltaMktValue(:), 0)) * rate(1);
sell = sum(max(-deltaMktValue(:), 0)) * rate(2);

end
