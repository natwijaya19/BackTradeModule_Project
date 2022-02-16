function priceVolumeData = loadDataFromYahooFcn (symList, startDate, endDate, interval, maxRetry)

symList = string (symList);
%
samplesymbol = 'BBCA.JK';
retry_count = zeros(10, 1);
while true
    try 
        sampledata = getMarketDataViaYahoo (samplesymbol, startDate, endDate, interval);
        break;
    catch ME 
       retry_count(i) = retry_count(i) + 1;
        if retry_count(i) > maxRetry
                break;
        end
    end
end

sampledata = table2timetable (sampledata);
sz = [size(sampledata, 1) 1] ;


% Fetch composite index (IHSG) benchmark data for data cleaning
index = timetable('Size', sz, 'VariableTypes', "double", 'RowTimes', sampledata.Date, 'VariableNames',"SampleData");

retry_count = zeros(10, 1);
while true
    try 
        indexraw = getMarketDataViaYahoo ('^JKSE', startDate, endDate, interval);
        break;
    catch ME
       retry_count(i) = retry_count(i) + 1;
        if retry_count(i) > maxRetry
                break;
        end
    end
end

indexraw = table2timetable(indexraw);
index = synchronize (index, indexraw);
index.SampleData = [];

%% Fetch price volume data from yahoo per symbol
% Prepare required parameters
nsym = size (symList,1);
niters = nsym;
% niters = 20; % for testing
retry_count = zeros(niters, 1);

% Preallocate price data variables
openpricedata = timetable('Size', sz, 'VariableTypes', "double", 'RowTimes', sampledata.Date, 'VariableNames',"SampleData");
highpricedata = openpricedata;
lowpricedata = openpricedata;
closepricedata = openpricedata;
volumedata = openpricedata;

checkDisp = 0:25:1000;
for i = 1: niters
    symi = char ((strcat (symList(i),".JK")));

    %display for progress monitoring
    if  ismember (i,checkDisp)
        disp(i)
    end

    while true
        try
            dataT_i = getMarketDataViaYahoo (symi, startDate, endDate, interval);
            
%           Extract and synchronize price and volume data
%           Extract the date            
            dt = datetime (table2array(dataT_i(:,1)), 'InputFormat','yyyy-MM-dd');

%           Extract open price
            openprice_i = timetable (table2array(dataT_i(:,2)), ...
                'RowTimes', dt, 'VariableNames', strcat (symList(i),'_open')) ;

%           Extract high price
            highprice_i = timetable (table2array(dataT_i(:,3)), ...
                'RowTimes', dt, 'VariableNames', strcat (symList(i),'_high')) ;
            
%           Extract low price
            lowprice_i = timetable (table2array(dataT_i(:,4)), ...
                'RowTimes', dt, 'VariableNames', strcat (symList(i),'_low')) ;            
            
%           Extract close price
            closeprice_i = timetable (table2array(dataT_i(:,5)), ...
                'RowTimes', dt, 'VariableNames', strcat (symList(i),'_close')) ;
            
%           Extract volume price
            volume_i = timetable (table2array(dataT_i(:,7)), ...
                'RowTimes', dt, 'VariableNames', strcat (symList(i),'_volume')) ;
            
%           Synchronize price and volume data
            openpricedata = synchronize (openpricedata, openprice_i) ;
            highpricedata = synchronize (highpricedata, highprice_i) ;
            lowpricedata = synchronize (lowpricedata, lowprice_i) ;
            closepricedata = synchronize (closepricedata, closeprice_i) ;
            volumedata = synchronize (volumedata, volume_i) ;
            
%             status(i) = true;
%             message{i} = [];
            break;

        catch ME
            retry_count(i,1) = retry_count(i,1) + 1;
%             status(i) = false;
%             message{i} = ME;
            pause(1)
            if retry_count(i,1) > maxRetry
                break;
            end
        end
    end
end


% remove the sample variable data
openpricedata.SampleData = [] ;
highpricedata.SampleData = [] ;
lowpricedata.SampleData = [] ;
closepricedata.SampleData = [] ;
volumedata.SampleData = [] ;


% Sort the variable names alphabetically
SymList = unique (openpricedata.Properties.VariableNames);
SymList = sort (string (SymList)) ;
openpricedata_sort = openpricedata (:, SymList) ;

SymList = unique (highpricedata.Properties.VariableNames);
SymList = sort (string (SymList)) ;
highpricedata_sort = highpricedata (:, SymList) ;

SymList = unique (lowpricedata.Properties.VariableNames);
SymList = sort (string (SymList)) ;
lowpricedata_sort = lowpricedata (:, SymList) ;

SymList = unique (closepricedata.Properties.VariableNames);
SymList = sort (string (SymList)) ;
closepricedata_sort = closepricedata (:, SymList) ;

SymList = unique (volumedata.Properties.VariableNames);
SymList = sort (string (SymList)) ;
volumedata_sort = volumedata (:, SymList) ;


% Transfer sorted data to output variabels
openpriceTT = openpricedata_sort ;
highpriceTT = highpricedata_sort ;
lowpriceTT = lowpricedata_sort ;
closepriceTT = closepricedata_sort ;
volumeTT = volumedata_sort ;
indexIHSG = index ;


% Save data to struct
priceVolumeData.openPrice = openpriceTT;
priceVolumeData.highPrice = highpriceTT;
priceVolumeData.lowPrice = lowpriceTT;
priceVolumeData.closePrice = closepriceTT;
priceVolumeData.volume = volumeTT;
priceVolumeData.indexIHSG = indexIHSG;

clearvars -except priceVolumeData

end

