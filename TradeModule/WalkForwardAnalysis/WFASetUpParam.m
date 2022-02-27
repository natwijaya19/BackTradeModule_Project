classdef WFASetUpParam
    %WFASetUp is to store all set up required to to a walk-forward analysis
    %   Detailed explanation goes here

    properties
        % WFA specific set up
        nWalk = 1 ; % Number of walk for the whole walk forwad
        lookbackUB = 300; % lookback upper bound
        nstepTrain = 60; % Number of step for training datastasket
        nstepTest = 20; % Number of step for testing dataset

        % btEngineSetUp
        tradingCost = [0.15/100, 0.25/100];
        maxCapAllocation = 0.25;

        % optimization set up
        maxFcnEval = 780;

        % nlConstParam
        maxDDThreshold = -15/100;
        minPortRet = 1.2;
        minDailyRetThreshold = -35/100;
        minLast20DRetThreshold = -20/100;
        minLast60DRetThreshold = -15/100;
        minLast200DRetThreshold = 0/100;

    end

    properties (SetAccess = private)
        lbubConst

    end

    methods

        function obj = prepare(obj)
            ubLookback = obj.lookbackUB;

            obj.lbubConst = [            % open the array
                40,  ubLookback;        % liquidityVolumeMALookback = paramInput(1);
                10,  400;               % liquidityVolumeMAThreshold = paramInput(2) * % percentage from LB to UB
                1,  40;                 %liquidityVolumeMANDayBuffer = paramInput(3)
                1,  ubLookback;        % liquidityValueMALookback  = paramInput(4);
                1,  10^6;              % liquidityValueMAThreshold  = paramInput(5)* 10^6; % multiplication of Rp 1 million
                1,  30;             %liquidityValueMANDayBuffer = paramInput(6)
                1,  30              % liquidityNDayVolumeValueBuffer = paramInput(7);
                1,  30          % momentumPriceMALookback = paramInput(8);
                10, 300            % momentumPriceMAToCloseThreshold = paramInput(9); % in percentage
                0,  20              % momentumPriceRetLowToCloseLookback = paramInput(10);
                0,  50             % momentumPriceRetLowToCloseThreshold = paramInput(11); % in percentage
                1,  30              % momentumPriceRetLowToCloseNDayBuffer = paramInput(12);
                1,  30              % liquidityMomentumSignalBuffer = paramInput(13);
                1,  10            % cutLossHighToCloseNDayLookback = paramInput(14);
                0,  8             % cutLossHighToCloseMaxPct = paramInput(15); % in percentage
                1,  1               % nDayBackShift = paramInput(16);
                ] ;                 % close the array



        end
    end

end

