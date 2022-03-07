classdef WFASetUpParam
    %WFASetUp is to store all set up required to to a walk-forward analysis
    %   Detailed explanation goes here

    properties
        % WFA specific set up
        nWalk = 80 ; % Number of walk for the whole walk forwad
        lookbackUB = 300; % lookback upper bound
        nstepTrain = 200; % Number of step for training datastasket
        nstepTest = 10; % Number of step for testing dataset

        % btEngineSetUp
        tradingCost = [0.15/100, 0.25/100];
        maxCapAllocation = 0.20;

        % optimization set up
        maxFcnEval = 600;

        % nlConstParam
        maxDDThreshold {mustBeNumeric} = -20/100;
        minPortRet {mustBeNumeric} = 1.2;
        minDailyRetThreshold {mustBeNumeric} = -35/100;
        minLast20DRetThreshold {mustBeNumeric} = -20/100;
        minLast60DRetThreshold {mustBeNumeric} = -15/100;
        minLast200DRetThreshold {mustBeNumeric} = 0/100;
        backShiftNDay {mustBeNumeric, mustBeInteger} = 1;
        walkPeriodTable table

    end

    properties (SetAccess = private)
        lbubConst {mustBeInteger, mustBeNonnegative}
        nDataRowRequired {mustBeInteger, mustBeNonnegative}
        nVars {mustBeInteger, mustBeNonnegative}
        optimLookbackStep {mustBeInteger, mustBeNonnegative}

    end

    methods

        function obj = prepare(obj)
            ubLookback = obj.lookbackUB;

            obj.lbubConst =...
                [               % open the array
                20, 400         % volumeMATreshold = x(1)/100 ; % input #1
                10, ubLookback % volumeMALookback = x(2) ; % input #2
                1,  60          % valueThreshold = x(3)*10^7 ; % input #3 in Rp hundreds million
                1,  10          % valueLookback = x(4) ; % input #4 nDays
                1,  10          % volumeValueBufferDays = x(5) ; % input #5
                1,  20          % priceRetLowCloseThresh = x(6)/100 ; % input #6
                40, 300          % priceMAThreshold = x(7)/100 ; % input #7
                1,  30          % priceMALookback = x(8) ; % input #8
                1,  20          % priceVolumeValueBufferDays = x(9) ; % input #9
                1,  10          % cutLossLookback = x(10) ; % input #10
                0,  8           % cutLossPct = x(11)/100 ; % input #11
                ] ;             % close the array

            % number of required nDataRow
            nstepWalk = obj.nWalk*obj.nstepTest + obj.lookbackUB + obj.nstepTrain;
            additionalData = obj.nstepTest; % additional data for safety required data

            nRowRequired = nstepWalk+additionalData;

            obj.nDataRowRequired = nRowRequired;

            obj.nVars = size(obj.lbubConst,1);

            obj.optimLookbackStep = obj.nstepTrain;

        end
    end

end

