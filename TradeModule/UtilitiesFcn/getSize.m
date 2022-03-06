function varSize = getSize(variableName) 
   props = properties(variableName); 
   totSize = 0; 
   
   for ii=1:length(props) 
      currentProperty = getfield(variableName, char(props(ii))); 
      s = whos('currentProperty'); 
      totSize = totSize + s.bytes; 
   end
  
%    fprintf(1, '%d bytes\n', totSize); 
   varSize = totSize;
end