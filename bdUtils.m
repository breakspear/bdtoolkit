classdef bdUtils
    %bdUtils Utility functions for the Brain Dynamics Toolbox. 
    %  This class provides useful utility functions that may be used
    %  when building custom GUI panels.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

    % Copyright (c) 2016, Queensland Institute Medical Research (QIMR)
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions
    % are met:
    %
    % 1. Redistributions of source code must retain the above copyright
    %    notice, this list of conditions and the following disclaimer.
    % 
    % 2. Redistributions in binary form must reproduce the above copyright
    %    notice, this list of conditions and the following disclaimer in
    %    the documentation and/or other materials provided with the
    %    distribution.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    % "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    % LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    % FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    % INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    % BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    % LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    % CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    % ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.

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
        
%         % Returns all values in xxxdef as one monolithic column vector
%         % where xxxdef is a cell array of {'name',value} pairs. 
%         % It applies to pardef, vardef, lagdef and auxdef arrays.
%         function vec = getValues(xxxdef)
%             % extract the second column of vardef
%             vec = xxxdef(:,2);
% 
%             % convert each cell entry to a column vector
%             for indx=1:numel(vec)
%                 vec{indx} = reshape(vec{indx},[],1);
%             end
% 
%             % concatenate the column vectors to a simple vector
%             vec = cell2mat(vec);
%         end
%         
%         % Return the value of the named entry in xxxdef 
%         function val = getValue(xxxdef,name)
%             val = [];
%             nvar = size(xxxdef,1);
%             for indx=1:nvar
%                 if strmcp(xxxdef{indx,1},name)==0
%                     val = xxxdef{indx,2};
%                     return
%                 end
%             end
%             warning('bdUtils.getValue() failed to find a matching name');
%         end
%         
%         % Set the value of the named entry in xxxdef
%         function setValue(xxxdef,name,val)
%             nvar = size(xxxdef,1);
%             for indx=1:nvar
%                 if strcmp(xxxdef{indx,1},name)==0
%                     xxxdef{indx,2} = val;
%                     return
%                 end
%             end
%             warning('dbUtils.setValue() failed to find a matching name');
%         end

        % Return the type (odesolver,ddesolver,sdesolver) of the given
        % solver function handle. If the solver is not supported by the
        % sys struct then returns 'unsupported'.
        % Examples:
        %    solverType(sys,@ode45) returns 'odesolver'
        %    solverType(sys,@dde23) returns 'ddesolver'
        function typestr = solverType(sys,solver)
            % Case of an ODE solver (eg ode45)
            if isfield(sys,'odesolver')
                for idx = 1:numel(sys.odesolver)
                    odesolver = sys.odesolver{idx};
                    if isequal(solver,odesolver)
                        typestr = 'odesolver';
                        return
                    end
                end
            end

            % Case of a DDE solver (eg dde23)
            if isfield(sys,'ddesolver')
                for idx = 1:numel(sys.ddesolver)
                    ddesolver = sys.ddesolver{idx};
                    if isequal(solver,ddesolver)
                        typestr = 'ddesolver';
                        return
                    end
                end
            end

            % Case of an SDE solver.
            if isfield(sys,'sdesolver')
                for idx = 1:numel(sys.sdesolver)
                    sdesolver = sys.sdesolver{idx};
                    if isequal(solver,sdesolver)
                        typestr = 'sdesolver';
                        return
                    end
                end    
            end
           
            % No match found
            typestr = 'unsupported';
        end

        
        % Utility function to construct a map of the solvers defined in sys.
        % The map is an array of structs with fields describing the name,
        % function handle and type of solver, as in:
        %    map.solvername = 'ode45'
        %    map.solverfunc = @ode45
        %    map.solvertype = 'odesolver'
        function map = solverMap(sys)
            map = struct('solvername',{}, 'solverfunc',{}, 'solvertype',{});
            if isfield(sys,'odesolver')
                for idx = 1:numel(sys.odesolver)
                    func = sys.odesolver{idx};
                    name = func2str(func);
                    map(end+1) = struct('solvername',name, 'solverfunc',func, 'solvertype','odesolver');
                end
            end
            if isfield(sys,'ddesolver')
                for idx = 1:numel(sys.ddesolver)
                    func = sys.ddesolver{idx};
                    name = func2str(func);
                    map(end+1) = struct('solvername',name, 'solverfunc',func, 'solvertype','ddesolver');
                end
            end
            if isfield(sys,'sdesolver')
                for idx = 1:numel(sys.sdesolver)
                    func = sys.sdesolver{idx};
                    name = func2str(func);
                    map(end+1) = struct('solvername',name, 'solverfunc',func, 'solvertype','sdesolver');
                end
            end
end

        
    end
    
end

