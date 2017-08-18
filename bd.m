classdef bd
    %bd  Class of static utility functions for the Brain Dynamics Toolbox. 
    %  This class provides useful utility functions that may be used
    %  when building custom GUI panels.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017c)

    % Copyright (C) 2016,2017 QIMR Berghofer Medical Research Institute
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
        
        % Vertically shifts all children of a uipanel so that the top-most
        % child is exactly <gap> pixels from the top of the panel.
        function alignTop(panel,gap)
            % work in pixels
            panelunits = panel.Units;
            panel.Units = 'pixels';

            % get height of panel
            panelh = panel.Position(4);

            % Find the vertical extent of the highest child in the panel
            ymax = 0;
            for indx=1:numel(panel.Children)
                % work in pixels
                childunits = panel.Children(indx).Units;
                panel.Children(indx).Units = 'pixels';

                % compute the vertical extent of the child
                if isfield(panel.Children(indx),'Extent')
                    childh = panel.Children(indx).Extent(4);
                else
                    childh = panel.Children(indx).Position(4);
                end
                ychild = panel.Children(indx).Position(2) + childh;

                % remember the maximum y 
                ymax = max(ymax,ychild);

                % restore the original units for the child object
                panel.Children(indx).Units = childunits;
            end

            % Shift all objects vertically to achieve the desired gap (pixels)
            % between the highest child and the top of the panel 
            yshift = panelh - ymax - gap;
            for indx=1:numel(panel.Children)
                % work in pixels
                childunits = panel.Children(indx).Units;
                panel.Children(indx).Units = 'pixels';

                % shift the vertical position
                panel.Children(indx).Position(2) = panel.Children(indx).Position(2) + yshift;

                % restore the original units for the child object
                panel.Children(indx).Units = childunits;
            end

            % restore the original units for the panel
            panel.Units = panelunits;
        end

        
%         % Returns the hull geometry of all children within a uipanel where
%         % marginw and marginh specify the margins of the hull.
%         function pos = childHull(panel,marginw,marginh)
%             % work in pixels
%             panelunits = panel.Units;
%             panel.Units = 'pixels';
% 
%             % init hull coords
%             xmin = NaN;
%             xmax = NaN;
%             ymin = NaN;
%             ymax = NaN;    
% 
%             % Find the vertical extent of the highest child in the panel
%             for indx=1:numel(panel.Children)
%                 % work in pixels
%                 childunits = panel.Children(indx).Units;
%                 panel.Children(indx).Units = 'pixels';
% 
%                 % get the x,y position of teh child
%                 childx = panel.Children(indx).Position(1);
%                 childy = panel.Children(indx).Position(2);
% 
%                 % get the width and height (extent) of the child
%                 try
%                     childw = panel.Children(indx).Extent(3);
%                     childh = panel.Children(indx).Extent(4);
%                 catch
%                     childw = panel.Children(indx).Position(3);
%                     childh = panel.Children(indx).Position(4);
%                 end
% 
%                 % remember the extremes
%                 xmin = min(xmin,childx);
%                 xmax = max(xmax,childx+childw);
%                 ymin = min(ymin,childy);
%                 ymax = max(ymax,childy+childh);
% 
%                 % restore the original units for the child object
%                 panel.Children(indx).Units = childunits;
% 
%             end
% 
%             % restore the original units for the panel
%             panel.Units = panelunits;
% 
%             % return value
%             pos = [xmin-marginw ymin-marginh xmax-xmin+2*marginw+1 ymax-ymin+2*marginh+1];        
%         end
        
        
        % Returns a struct array which maps the ODE variables described
        % in vardef{} to the corresponding row entries in sol.y.
        %
        % The resulting map has one entry per vardef entry where
        %    map.name is the string name of the variable
        %    map.solindx contains the row indexes of sol.y
        %
        % For example, 
        %    vardef = [ struct('name','A', 'value',rand(4,1)); 
        %               struct('name','B', 'value',rand(2,1));
        %               struct('name','C', 'value',rand(3,1)); ];
        %    map = varMap(vardef)
        % generates map as follows:
        %    map(1).name = 'A'   map(1).solindx = [1 2 3 4]
        %    map(2).name = 'B'   map(2).solindx = [5 6]
        %    map(3).name = 'C'   map(3).solindx = [7 8 9]
        %    
        function map = varMap(vardef)
            % number of entries in vardef
            n = numel(vardef);

            % preallocate the return map with n entries
            map = struct('name',cell(n,1),'solindx',[]);

            % for each entry in vardef
            row = 0;                                  % current row index of sol.y
            for indx = 1:n
                len = numel(vardef(indx).value);      % number of ODE variables represented by this vardef
                map(indx).name = vardef(indx).name;   % name field
                map(indx).solindx = (1:len) + row;    % row indexes to corresponding sol.y values
                row = row + len;                      % next row position
            end
        end        
                
        function map = solMap(vardef)
            % number of entries in vardef
            n = numel(vardef);
            
            % total number of variables (number of rows in sol.y)
            nsol = 0; 
            for varindx = 1:n
                nsol = nsol + numel(vardef(varindx).value);
            end
            
            % preallocate the return map with nsol entries
            map = struct('name',cell(nsol,1),'varindx',[]);

            solindx = 1;
            for varindx = 1:n
                % for each element in the current variable
                len = numel(vardef(varindx).value);
                for element = 1:len
                    % generate a name string for this element
                    if len==1
                        name = vardef(varindx).name;        
                    else
                        name = num2str(element,[vardef(varindx).name,'_{%d}']);        
                    end                    
                    % populate the map entry
                    map(solindx).name = name;
                    map(solindx).varindx = varindx;
                    % next map entry
                    solindx = solindx + 1;
                end
            end            
        end
        

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
        
        % The functionality of bdSolve but without the error checking on sys
        function [sol,sox] = solve(sys,tspan,solverfun,solvertype)
            % The type of the solver function determines how we apply it 
            switch solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    y0 = bdGetValues(sys.vardef);
                    par = {sys.pardef.value};
                    sol = solverfun(sys.odefun, tspan, y0, sys.odeoption, par{:});
                    % compute the auxilliary variables (if requested)
                    if nargout==2
                        if isfield(sys,'auxfun')
                            sox.solver = 'auxfun';
                            sox.x = sol.x;
                            sox.y = sys.auxfun(sol,par{:});
                        else
                            sox = [];
                        end
                    end

                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    y0 = bdGetValues(sys.vardef);          
                    lag = bdGetValues(sys.lagdef); 
                    par = {sys.pardef.value};
                    sol = solverfun(sys.ddefun, lag, y0, tspan, sys.ddeoption, par{:});
                    % compute the auxilliary variables (if requested)
                    if nargout==2
                        if isfield(sys,'auxfun')
                            sox.solver = 'auxfun';
                            sox.x = sol.x;
                            sox.y = sys.auxfun(sol,par{:});
                        else
                            sox = [];
                        end
                    end

                case 'sdesolver'
                    % case of an SDE solver
                    y0 = bdGetValues(sys.vardef);          
                    par = {sys.pardef.value};
                    sol = solverfun(sys.sdeF, sys.sdeG, tspan, y0, sys.sdeoption, par{:});
                    % compute the auxilliary variables (if requested)
                    if nargout==2
                        if isfield(sys,'auxfun')
                            sox.solver = 'auxfun';
                            sox.x = sol.x;
                            sox.y = sys.auxfun(sol,par{:});
                        else
                            sox = [];
                        end
                    end

                case 'unsupported'
                    % case of an unsupported solver function
                    solvername = func2str(solverfun);
                    throw(MException('bdtoolkit:solve:solverfun','Unknown solvertype for solver ''@%s''. Specify an appropriate solvertype in the calling function.',solvername));
                otherwise
                    throw(MException('bdtoolkit:solve:solvertype','Invalid solvertype ''%s''',solvertype));
                end        
        end
   
        % Checks the contents of sys and throws an exception if a problem is found.
        % If no problem is found then returns a 'safe' copy of sys in which missing
        % fields are filled with default values.
        function sysout = syscheck(sys)
            % init empty output
            sysout = [];
            
            % check that sys is a struct
            if ~isstruct(sys)
               throw(MException('bdtoolkit:syscheck:badsys','sys must be a struct'));
            end
    
            % check for obsolete fields (from version 2016a)
            if isfield(sys,'pardef') && iscell(sys.pardef)
                throw(MException('bdtoolkit:syscheck:obsolete','sys.pardef changed from a cell array in 2016a to an array of structs in 2017a'));
            end
            if isfield(sys,'sdefun')
                throw(MException('bdtoolkit:syscheck:obsolete','sys.odefun and sys.sdefun are obsolete for SDEs. They were replaced by sys.sdeF and sys.sdeG in 2017a'));
            end
            if isfield(sys,'gui')
                throw(MException('bdtoolkit:syscheck:obsolete','sys.gui is obsolete. It was renamed sys.panels in 2017a'));        
            end
            if isfield(sys,'panels')
                if isfield(sys.panels,'bdCorrelationPanel')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'bdCorrelationPanel was renamed bdCorrPanel in 2017a'));        
                end
                if isfield(sys.panels,'bdSpaceTimePortrait')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'bdSpaceTimePortrait was renamed bdSpaceTime in 2017a'));        
                end
            end

            % check sys.pardef
            if ~isfield(sys,'pardef')
               throw(MException('bdtoolkit:syscheck:pardef','sys.pardef is undefined'));
            end
            if ~isstruct(sys.pardef)
               throw(MException('bdtoolkit:syscheck:pardef','sys.pardef must be a struct'));
            end
            if ~isfield(sys.pardef,'name')
               throw(MException('bdtoolkit:syscheck:pardef','sys.pardef.name is undefined'));
            end
            if ~isfield(sys.pardef,'value')
               throw(MException('bdtoolkit:syscheck:pardef','sys.pardef.value is undefined'));
            end
            % check each array entry
            for indx=1:numel(sys.pardef)
                if ~ischar(sys.pardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:pardef','sys.pardef(%d).name must be a string',indx));
                end
                if isempty(sys.pardef(indx).value) || ~isnumeric(sys.pardef(indx).value)
                   throw(MException('bdtoolkit:syscheck:pardef','sys.pardef(%d).value must be numeric',indx));
                end
            end
            
            % check sys.vardef
            if ~isfield(sys,'vardef')
               throw(MException('bdtoolkit:syscheck:vardef','sys.vardef is undefined'));
            end
            if ~isstruct(sys.vardef)
               throw(MException('bdtoolkit:syscheck:vardef','sys.vardef must be a struct'));
            end
            if ~isfield(sys.vardef,'name')
               throw(MException('bdtoolkit:syscheck:vardef','sys.vardef.name is undefined'));
            end
            if ~isfield(sys.vardef,'value')
               throw(MException('bdtoolkit:syscheck:vardef','sys.vardef.value is undefined'));
            end
            % check each array entry
            for indx=1:numel(sys.vardef)
                if ~ischar(sys.vardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:vardef','sys.vardef(%d).name must be a string',indx));
                end
                if isempty(sys.vardef(indx).value) || ~isnumeric(sys.vardef(indx).value) 
                   throw(MException('bdtoolkit:syscheck:vardef','sys.vardef(%d).value must be numeric',indx));
                end
            end
            
            % check sys.tspan = [0,1]
            if ~isfield(sys,'tspan')
                sys.tspan = [0 1];      
            end
            if ~isnumeric(sys.tspan)
                throw(MException('bdtoolkit:syscheck:tspan','sys.tspan must be numeric'));
            end
            if size(sys.tspan,1)~=1 || size(sys.tspan,2)~=2
                throw(MException('bdtoolkit:syscheck:tspan','sys.tspan must be 1x2 vector'));
            end
           
            % Must have sys.odefun or sys.ddefun or (sys.sdeF and sdeG)
            if ~isfield(sys,'odefun') && ~isfield(sys,'ddefun') && ~isfield(sys,'sdeF') && ~isfield(sys,'sdeG')
                throw(MException('bdtoolkit:syscheck:badfun','No function handles found for sys.odefun, sys.ddefun, sys.sdeF or sys.sdeG'));
            end
            
            % check sys.odefun is exclusive (if it exists)
            if isfield(sys,'odefun') && (isfield(sys,'ddefun') || isfield(sys,'sdeF') || isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.ddefun, sys.sdeF, sys.sdeG cannot co-exist with sys.odefun'));
            end
            
            % check sys.ddefun is exclusive (if it exists)
            if isfield(sys,'ddefun') && (isfield(sys,'odefun') || isfield(sys,'sdeF') || isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.sdeF, sys.sdeG cannot co-exist with sys.ddefun'));
            end
            
            % check sys.sdeF (if it exists) is exclusive to sys.odefun and sys.ddefun
            if isfield(sys,'sdeF') && (isfield(sys,'odefun') || isfield(sys,'ddefun'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.ddefun cannot co-exist with sys.sdeF'));
            end
            
            % check sys.sdeG (if it exists) is exclusive to sys.odefun and sys.ddefun
            if isfield(sys,'sdeG') && (isfield(sys,'odefun') || isfield(sys,'ddefun'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.odefun, sys.ddefun cannot co-exist with sys.sdeG'));
            end
            
            % check sys.sdeF and sys.sdeG co-exist
            if (isfield(sys,'sdeF') && ~isfield(sys,'sdeG')) || (~isfield(sys,'sdeF') && isfield(sys,'sdeG'))
                throw(MException('bdtoolkit:syscheck:badfun','Function handles sys.sdeF and sys,sdG must co-exist'));
            end
         
            % case of ODE
            if isfield(sys,'odefun')
                % check sys.odefun
                if ~isa(sys.odefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:odefun','sys.odefun must be a function handle'));
                end
                
                % check sys.odesolver
                if ~isfield(sys,'odesolver')
                    sys.odesolver = {@ode45,@ode23,@ode113,@ode15s,@ode23s,@ode23t,@ode23tb,@odeEul};
                end
                if ~iscell(sys.odesolver)
                    throw(MException('bdtoolkit:syscheck:odesolver','sys.odesolver must be a cell array'));
                end
                if size(sys.odesolver,1)~=1 && size(sys.odesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:odesolver','sys.odesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.odesolver)
                   if ~isa(sys.odesolver{indx},'function_handle')
                       throw(MException('bdtoolkit:syscheck:odesolver','sys.odesolver{%d} must be a function handle',indx));
                   end
                end

                % check sys.odeoption
                if ~isfield(sys,'odeoption')
                    sys.odeoption = odeset();
                end
                if ~isstruct(sys.odeoption)
                    throw(MException('bdtoolkit:syscheck:odeoption','sys.odeoption must be a struct (see odeset)'));
                end
            end
            
            % case of DDE
            if isfield(sys,'ddefun')
                % check sys.ddefun
                if ~isa(sys.ddefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:ddefun','sys.ddefun must be a function handle'));
                end
                
                % check sys.ddesolver
                if ~isfield(sys,'ddesolver')
                    sys.ddesolver = {@dde23};
                end
                if ~iscell(sys.ddesolver)
                    throw(MException('bdtoolkit:syscheck:ddesolver','sys.ddesolver must be a cell array'));
                end
                if size(sys.ddesolver,1)~=1 && size(sys.ddesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:ddesolver','sys.ddesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.ddesolver)
                   if ~isa(sys.ddesolver{indx},'function_handle')
                       throw(MException('bdtoolkit:syscheck:ddesolver','sys.ddesolver{%d} must be a function handle',indx));
                   end
                end

                % check sys.ddeoption
                if ~isfield(sys,'ddeoption')
                    sys.ddeoption = ddeset();
                end
                if ~isstruct(sys.ddeoption)
                    throw(MException('bdtoolkit:syscheck:ddeoption','sys.ddeoption must be a struct (see ddeset)'));
                end
                
                % check sys.lagdef
                if ~isfield(sys,'lagdef')
                    throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef is undefined'));
                end
                if ~isstruct(sys.lagdef)
                    throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef must be a struct'));
                end
                if ~isfield(sys.lagdef,'name')
                    throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef.name is undefined'));
                end
                if ~isfield(sys.lagdef,'value')
                    throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef.value is undefined'));
                end
                % check each array entry
                for indx=1:numel(sys.lagdef)
                    if ~ischar(sys.lagdef(indx).name)
                        throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef(%d).name must be a string',indx));
                    end
                    if isempty(sys.lagdef(indx).value) || ~isnumeric(sys.lagdef(indx).value)
                        throw(MException('bdtoolkit:syscheck:lagdef','sys.lagdef(%d).value must be numeric',indx));
                    end
                end
            end
            
            % case of SDE
            if isfield(sys,'sdeF')
                % check sys.sdeF
                if ~isa(sys.sdeF,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeF','sys.sdeF must be a function handle'));
                end
                
                % check sys.sdeG
                if ~isa(sys.sdeG,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeG','sys.sdeG must be a function handle'));
                end
                
                % check sys.sdesolver
                if ~isfield(sys,'sdesolver')
                    throw(MException('bdtoolkit:syscheck:sdesolver','sys.sdesolver must be defined for SDEs'));
                end
                if ~iscell(sys.sdesolver)
                    throw(MException('bdtoolkit:syscheck:sdesolver','sys.sdesolver must be a cell array'));
                end
                if size(sys.sdesolver,1)~=1 && size(sys.sdesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:sdesolver','sys.sdesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.sdesolver)
                   if ~isa(sys.sdesolver{indx},'function_handle')
                       throw(MException('bdtoolkit:syscheck:sdesolver','sys.sdesolver{%d} must be a function handle',indx));
                   end
                end

                % check sys.sdeoption
                if ~isfield(sys,'sdeoption')
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.sdeoption is undefined'));
                end
                if ~isstruct(sys.sdeoption)
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.odeoption must be a struct'));
                end
                
                % check sys.sdeoption.InitialStep
                if ~isfield(sys.sdeoption,'InitialStep')
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.sdeoption.InitialStep is undefined'));
                end
                if ~isnumeric(sys.sdeoption.InitialStep) && ~isempty(sys.sdeoption.InitialStep)
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.odeoption.InitialStep must be numeric'));
                end
                
                % check sys.sdeoption.NoiseSources
                if ~isfield(sys.sdeoption,'NoiseSources')
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.sdeoption.NoiseSources is undefined'));
                end
                if ~isnumeric(sys.sdeoption.NoiseSources)
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.odeoption.NoiseSources must be numeric'));
                end
                if numel(sys.sdeoption.NoiseSources)~=1
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.odeoption.NoiseSources must be a scalar value'));
                end
                if mod(sys.sdeoption.NoiseSources,1)~=0
                    throw(MException('bdtoolkit:syscheck:sdeoption','sys.sdeoption.NoiseSources must be an integer value'));
                end
                
                % check sys.sdeoption.randn (an optional parameter)
                if isfield(sys.sdeoption,'randn')
                    if ~isnumeric(sys.sdeoption.randn)
                        throw(MException('bdtoolkit:syscheck:sdeoption','sys.odeoption.randn must be numeric'));
                    end
                    if size(sys.sdeoption.randn,1) ~= sys.sdeoption.NoiseSources
                        throw(MException('bdtoolkit:syscheck:sdeoption','Number of rows in sys.sdeoption.randn must equal sys.sdeoption.NoiseSources')); 
                    end
                end
            end            
            
            % check sys.auxfun (optional function handle)
            if isfield(sys,'auxfun')
                if ~isa(sys.auxfun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:auxfun','sys.auxfun must be a function handle'));
                end
            end
            
            % check sys.panels 
            if ~isfield(sys,'panels')
                throw(MException('bdtoolkit:syscheck:panels','sys.panels is undefined'));
            end
            if ~isstruct(sys.panels)
                throw(MException('bdtoolkit:syscheck:panels','sys.panels must be a struct'));
            end
            
            % check sys.self (optional function handle)
            if isfield(sys,'self')
                if ~isa(sys.self,'function_handle')
                    throw(MException('bdtoolkit:syscheck:self','sys.self must be a function handle'));
                end
            end
            
            % all tests have passed, return the updated sys.
            sysout = sys;
        end
     
    end
    
end

