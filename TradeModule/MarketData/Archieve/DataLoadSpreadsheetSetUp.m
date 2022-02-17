classdef DataLoadSpreadsheetSetUp
    %DataLoadSpreadsheetSetUp is class data holder to hold input required to
    % save data
    %   
    % Input arguments
    %   filename: file name of spreadsheet
    %   openPriceSheetname: sheet name where openPriceSheetname is stored
    %   highPriceSheetname: sheet name where highPriceSheetname is stored
    %   lowPriceSheetname: sheet name where lowPriceSheetname is stored
    %   closePriceSheetname: sheet name where closePriceSheetname is stored
    %   volumeSheetname: sheet name where volumeSheetname is stored
    %======================================================================
    
    properties
        filename {mustBeText, mustBeTextScalar} = "DataInput\PriceVolumeInput"
        openPriceSheetname {mustBeText, mustBeTextScalar} = "openPrice"
        lowPriceSheetname {mustBeText, mustBeTextScalar} = "lowPrice"
        highPriceSheetname {mustBeText, mustBeTextScalar} = "highPrice"
        closePriceSheetname {mustBeText, mustBeTextScalar} = "lowPrice"
        volumeSheetname {mustBeText, mustBeTextScalar} = "volume"        
    end

end