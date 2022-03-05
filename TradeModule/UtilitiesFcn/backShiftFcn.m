function shiftedSignal = backShiftFcn (signalInput, nBackShift)
% backShiftFcn will shift the signal one day

arguments
    signalInput {mustBeNumeric}
    nBackShift {mustBeInteger}
end

argsInputShifted = signalInput;
argsInputShifted(1:nBackShift,:) = 0;
argsInputShifted(1+nBackShift:end,:) = signalInput(1:end-nBackShift,:);
argsInputShifted(isnan(argsInputShifted)) = 0;

% transfer value to the output variable
shiftedSignal = argsInputShifted;

end