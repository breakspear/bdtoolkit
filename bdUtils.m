classdef bdUtils
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        
        % Returns a struct array which maps the ODE variables described
        % in vardef{} to the corresponding row entries in sol.y.
        %
        % The resulting map has one entry per vardef entry where
        %    map.name is the string name of the variable
        %    map.solindx contains the row indexes of sol.y
        %
        % For example, the compact map of
        %    vardef = {'A', rand(4,1); 
        %              'B', rand(2,1);
        %              'C', rand(3,1)};
        % has three entries
        %    map(1).name = 'A'   map(1).solindx = [1 2 3 4]
        %    map(2).name = 'B'   map(2).solindx = [5 6]
        %    map(3).name = 'C'   map(3).solindx = [7 8 9]
        %    
        function map = varMap(vardef)
            % number of entries in vardef
            n = size(vardef,1);

            % preallocate the return map with n entries
            map = struct('name',cell(n,1),'solindx',[]);

            % for each entry in vardef
            row = 0;                                  % current row index of sol.y
            for indx = 1:n
                len = numel(vardef{indx,2});          % number of ODE variables represented by this vardef
                map(indx).name = vardef{indx,1};      % name field
                map(indx).solindx = (1:len) + row;    % row indexes to corresponding sol.y values
                row = row + len;                      % next row position
            end
        end        
                
        function map = solMap(vardef)
            % number of entries in vardef
            n = size(vardef,1);
            
            % total number of variables (number of rows in sol.y)
            nsol = 0; 
            for varindx = 1:n
                nsol = nsol + numel(vardef{varindx,2});
            end
            
            % preallocate the return map with nsol entries
            map = struct('name',cell(nsol,1),'varindx',[]);

            solindx = 1;
            for varindx = 1:size(vardef,1)
                % for each element in the current variable
                len = numel(vardef{varindx,2});
                for element = 1:len
                    % generate a name string for this element
                    if len==1
                        name = vardef{varindx,1};        
                    else
                        name = num2str(element,[vardef{varindx,1},'_{%d}']);        
                    end                    
                    % populate the map entry
                    map(solindx).name = name;
                    map(solindx).varindx = varindx;
                    % next map entry
                    solindx = solindx + 1;
                end
            end            
        end
        
    end
    
end

