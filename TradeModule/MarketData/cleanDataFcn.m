function dataClean = cleanDataFcn(dataRaw)
%cleanDataFcn clean the data by rearranging the symbols alphabetically,
%fillmissing and put zero value for timeseries having priceret beyond the
%priceRetLimit

%% argument validation
arguments
    dataRaw cell

end

%% rearrange data based on symbols alphabetcicaly
dataSortIn = dataRaw;
nData = numel(dataSortIn);  % n price data only excluding volume
dataSortOut = cell(1,nData);
for idx = 1:nData
    symbols = dataSortIn{idx}.Properties.VariableNames;
    symbols = string(symbols);
    symbols = sort(symbols,2,"ascend");
    dataSortOut{idx} = dataSortIn{idx}(:,symbols);
end

%======================================================================
%% fillmissing data

dataStrDblInput = dataSortOut;

% convert data to string and to double
nData = numel(dataStrDblInput);

dataStrDblOut = dataStrDblInput;
for idx = 1:nData
    varStr = string(dataStrDblInput{idx}.Variables); % convert data to string
    varDouble = double(varStr); % convert string data to dobule
    dataStrDblOut{idx}.Variables = varDouble;
end

% main fillmissing data routine
dataFillInput = dataStrDblOut;
nData = numel(dataFillInput);
dataFillOut = dataFillInput;

% for price data (idx 1 to 4), fill missing data with previous and next data
% for volume data, fill missing data with previous data
for idx = 1:nData

    % fill zero with nan
    dataVar = dataFillInput{idx}.Variables;
    dataVar(dataVar==0) = nan;

    % fill with prevous data
    dataVar = fillmissing(dataVar,"previous");

    % fill with next data only for price data(idx=1:4) and exclude volume data (idx=5)
    validIF = idx ~= 5;
    if validIF
        dataVar = fillmissing(dataVar,"next");
    end

    if idx == 5
        dataVar (isnan(dataVar)) = 0;
    end

    
    % fill nan with zero
    dataVar(isnan(dataVar)) = 0;
    
    % transfer data for output
    dataFillOut{idx}.Variables = dataVar;

end

%======================================================================
%% fill data column containing priceRetLimit ARA & ARB error with zero
% define priceRetLimit
priceRetLimit = 35/100;

% prepare data
dataPriceLimInput = dataFillOut;
dataPriceLimOutput = dataPriceLimInput;

% calc closePriceRet
closePriceRet = tick2ret(dataPriceLimInput{4});
closePriceRetVar = closePriceRet.Variables;

% Identify symbols with daily ret higher than ARA limit
priceRetHigherARA = closePriceRetVar > priceRetLimit;
sumIndexHigherARA = sum(priceRetHigherARA,1);
indexHigherARA = sumIndexHigherARA > 0;


% Identify symbols with daily ret lower than ARB limit
priceRetHigherARB = closePriceRetVar < -priceRetLimit;
sumindexLowerARB = sum(priceRetHigherARB,1);
indexLowerARB = sumindexLowerARB > 0;

% main routine:fill data column containing priceRetLimit
% ARA & ARB error with zero

combinedMarker = indexHigherARA + indexLowerARB;
indexPriceLimitError = combinedMarker > 0;
nData = numel(dataPriceLimInput);

for idx = 1:nData
    dataVar = dataPriceLimOutput{idx}.Variables;
    dataVar(:,indexPriceLimitError) = 0;
    dataPriceLimOutput{idx}.Variables = dataVar;  
end

%=======================================================================
%% Check final result
nData = numel(dataPriceLimOutput);
resultCheck = zeros(1,nData);
for idx = 1:nData
    resultCheck(idx) = max(max(isnan(dataPriceLimOutput{idx}.Variables)));
end

%% transfer final result
dataClean = dataPriceLimOutput;

%=======================================================================
%% end of function

clearvars -except dataClean

end