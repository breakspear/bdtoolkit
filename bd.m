classdef bd
    %bd  Class of static utility functions for the Brain Dynamics Toolbox. 
    %  This class provides useful utility functions that may be used
    %  when building custom GUI panels.
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017c,2018a)

    % Copyright (C) 2016-2018 QIMR Berghofer Medical Research Institute
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
        
        % The functionality of bdSolve but without the error checking on sys
        function sol = solve(sys,tspan,solverfun,solvertype)
            % The type of the solver function determines how we apply it 
            switch solvertype
                case 'odesolver'
                    % case of an ODE solver (eg ode45)
                    y0 = bdGetValues(sys.vardef);
                    par = {sys.pardef.value};
                    sol = solverfun(sys.odefun, tspan, y0, sys.odeoption, par{:});

                case 'ddesolver'
                    % case of a DDE solver (eg dde23)
                    y0 = bdGetValues(sys.vardef);          
                    lag = bdGetValues(sys.lagdef); 
                    par = {sys.pardef.value};
                    sol = solverfun(sys.ddefun, lag, y0, tspan, sys.ddeoption, par{:});

                case 'sdesolver'
                    % case of an SDE solver
                    y0 = bdGetValues(sys.vardef);          
                    par = {sys.pardef.value};
                    sol = solverfun(sys.sdeF, sys.sdeG, tspan, y0, sys.sdeoption, par{:});

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
               throw(MException('bdtoolkit:syscheck:badsys','The sys variable must be a struct'));
            end

            % silently remove obsolete fields (from version 2017c)
            if isfield(sys,'auxdef')
                sys = rmfield(sys,'auxdef');
            end
            if isfield(sys,'auxfun')
                sys = rmfield(sys,'auxfun');
            end
            if isfield(sys,'self')
                sys = rmfield(sys,'self');
            end
            
            % check for obsolete fields (from version 2016a)
            if isfield(sys,'pardef') && iscell(sys.pardef)
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.pardef field changed from a cell array in 2016a to an array of structs in 2017a'));
            end
            if isfield(sys,'sdefun')
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.odefun and sys.sdefun fields are obsolete for SDEs. They were replaced by sys.sdeF and sys.sdeG in 2017a'));
            end
            if isfield(sys,'gui')
                throw(MException('bdtoolkit:syscheck:obsolete','The sys.gui field is obsolete. It was renamed sys.panels after version 2016a'));        
            end
            if isfield(sys,'panels')
                if isfield(sys.panels,'bdCorrelationPanel')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'The bdCorrelationPanel was renamed bdCorrPanel after version 2016a'));        
                end
                if isfield(sys.panels,'bdSpaceTimePortrait')
                    throw(MException('bdtoolkit:syscheck:obsolete', 'The bdSpaceTimePortrait was renamed bdSpaceTime after version 2016a'));        
                end
            end

            % check sys.pardef
            if ~isfield(sys,'pardef')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef field is undefined'));
            end
            if ~isstruct(sys.pardef)
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef field must be a struct'));
            end
            if ~isfield(sys.pardef,'name')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef.name field is undefined'));
            end
            if ~isfield(sys.pardef,'value')
               throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef.value field is undefined'));
            end
            % check each array entry
            for indx=1:numel(sys.pardef)
                % ensure the pardef.name field is a string
                if ~ischar(sys.pardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).name field must be a string',indx));
                end
                % ensure the pardef.value field is numeric 
                if isempty(sys.pardef(indx).value) || ~isnumeric(sys.pardef(indx).value)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).value field must be numeric',indx));
                end
                % assign a default value to pardef.lim if it is missing  
                if ~isfield(sys.pardef(indx),'lim') || isempty(sys.pardef(indx).lim)
                    % default lim entries
                    lo = floor(min(sys.pardef(indx).value(:)) - 1e-6);
                    hi =  ceil(max(sys.pardef(indx).value(:)) + 1e-6);
                    sys.pardef(indx).lim = [lo,hi];
                end
                % ensure the pardef.lim field is [lo hi] only
                if ~isnumeric(sys.pardef(indx).lim) || numel(sys.pardef(indx).lim) ~= 2 || sys.pardef(indx).lim(1)>=sys.pardef(indx).lim(2)
                   throw(MException('bdtoolkit:syscheck:pardef','The sys.pardef(%d).lim field does not contain valid [lower, upper] limits',indx));
                end
            end
            
            % check sys.vardef
            if ~isfield(sys,'vardef')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef field is undefined'));
            end
            if ~isstruct(sys.vardef)
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef field must be a struct'));
            end
            if ~isfield(sys.vardef,'name')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef.name field is undefined'));
            end
            if ~isfield(sys.vardef,'value')
               throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef.value field is undefined'));
            end
            % check each array entry
            offset = 0;
            for indx=1:numel(sys.vardef)
                % ensure the vardef.name field is a string
                if ~ischar(sys.vardef(indx).name)
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).name field must be a string',indx));
                end
                % ensure the vardef.value field is numeric 
                if isempty(sys.vardef(indx).value) || ~isnumeric(sys.vardef(indx).value) 
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).value field must be numeric',indx));
                end
                % assign a default value to vardef.lim if it is missing  
                if ~isfield(sys.vardef(indx),'lim') || isempty(sys.vardef(indx).lim)
                    % default lim entries
                    lo = floor(min(sys.vardef(indx).value(:)) - 1e-6);
                    hi =  ceil(max(sys.vardef(indx).value(:)) + 1e-6);
                    sys.vardef(indx).lim = [lo,hi];
                end
                % ensure the vardef.lim field is [lo hi] only
                if ~isnumeric(sys.vardef(indx).lim) || numel(sys.vardef(indx).lim) ~= 2 || sys.vardef(indx).lim(1)>=sys.vardef(indx).lim(2)
                   throw(MException('bdtoolkit:syscheck:vardef','The sys.vardef(%d).lim field does not contain valid [lower, upper] limits',indx));
                end
                % assign the corresponding indices to sol
                len =  numel(sys.vardef(indx).value);
                sys.vardef(indx).solindx = [1:len] + offset;
                offset = offset + len;
            end
            
            % check sys.tspan = [0,1]
            if ~isfield(sys,'tspan')
                sys.tspan = [0 1];      
            end
            if ~isnumeric(sys.tspan)
                throw(MException('bdtoolkit:syscheck:tspan','The sys.tspan field must be numeric'));
            end
            if size(sys.tspan,1)~=1 || size(sys.tspan,2)~=2
                throw(MException('bdtoolkit:syscheck:tspan','The sys.tspan field must be size 1x2'));
            end
            if sys.tspan(1) > sys.tspan(2)
                throw(MException('bdtoolkit:syscheck:tspan','The values in sys.tspan=[t0 t1] must have t0<=t1'));
            end

            % check sys.tval = t0
            if ~isfield(sys,'tval')
                sys.tval = sys.tspan(1);      
            end
            % force tval to be bounded by tspan
            sys.tval = max(sys.tspan(1), sys.tval);
            sys.tval = min(sys.tspan(2), sys.tval);            

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
                % check sys.odefun is a function handle
                if ~isa(sys.odefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:odefun','The sys.odefun field must be a function handle'));
                end
                
                % check sys.odefun is in the search path
                if strcmp(func2str(sys.odefun),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:odefun','The sys.odefun field contains a handle to a missing function.'));
                end
                
                % check sys.odesolver
                if ~isfield(sys,'odesolver')
                    sys.odesolver = {@ode45,@ode23,@ode113,@ode15s,@ode23s,@ode23t,@ode23tb,@odeEul};
                end
                if ~iscell(sys.odesolver)
                    throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver field must be a cell array'));
                end
                if size(sys.odesolver,1)~=1 && size(sys.odesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.odesolver)
                    % check that each sys.odesolver is a function handle
                    if ~isa(sys.odesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.odesolver is in the search path
                    if strcmp(func2str(sys.odesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:odesolver','The sys.odesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end

                % check sys.odeoption
                if ~isfield(sys,'odeoption')
                    sys.odeoption = odeset();
                end
                if ~isstruct(sys.odeoption)
                    throw(MException('bdtoolkit:syscheck:odeoption','The sys.odeoption field must be a struct (see odeset)'));
                end
            end
            
            % case of DDE
            if isfield(sys,'ddefun')
                % check sys.ddefun
                if ~isa(sys.ddefun,'function_handle')
                    throw(MException('bdtoolkit:syscheck:ddefun','The sys.ddefun field must be a function handle'));
                end
                
                % check sys.ddefun is in the search path
                if strcmp(func2str(sys.ddefun),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:ddefun','The sys.ddefun field contains a handle to a missing function.'));
                end
                
                % check sys.ddesolver
                if ~isfield(sys,'ddesolver')
                    sys.ddesolver = {@dde23};
                end
                if ~iscell(sys.ddesolver)
                    throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver field must be a cell array'));
                end
                if size(sys.ddesolver,1)~=1 && size(sys.ddesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.ddesolver)
                    % check that each sys.ddesolver is a function handle
                    if ~isa(sys.ddesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.ddesolver is in the search path
                    if strcmp(func2str(sys.ddesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:ddesolver','The sys.ddesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end

                % check sys.ddeoption
                if ~isfield(sys,'ddeoption')
                    sys.ddeoption = ddeset();
                end
                if ~isstruct(sys.ddeoption)
                    throw(MException('bdtoolkit:syscheck:ddeoption','The sys.ddeoption field must be a struct (see ddeset)'));
                end
                
                % check sys.lagdef
                if ~isfield(sys,'lagdef')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef field is undefined'));
                end
                if ~isstruct(sys.lagdef)
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef field must be a struct'));
                end
                if ~isfield(sys.lagdef,'name')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef.name field is undefined'));
                end
                if ~isfield(sys.lagdef,'value')
                    throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef.value field is undefined'));
                end
                % check each array entry
                for indx=1:numel(sys.lagdef)
                    % ensure the lagdef.name field is a string
                    if ~ischar(sys.lagdef(indx).name)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).name field must be a string',indx));
                    end
                    % ensure the lagdef.value field is numeric
                    if isempty(sys.lagdef(indx).value) || ~isnumeric(sys.lagdef(indx).value)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).value field must be numeric',indx));
                    end
                    % assign a default value to lagdef.lim if it is missing  
                    if ~isfield(sys.lagdef(indx),'lim') || isempty(sys.lagdef(indx).lim)
                        % default lim entries
                        lo = floor(min(sys.lagdef(indx).value(:)) - 1e-6);
                        hi =  ceil(max(sys.lagdef(indx).value(:)) + 1e-6);
                        sys.lagdef(indx).lim = [lo,hi];
                    end
                    % ensure the lagdef.lim field is [lo hi] only
                    if ~isnumeric(sys.lagdef(indx).lim) || numel(sys.lagdef(indx).lim) ~= 2 || sys.lagdef(indx).lim(1)>=sys.lagdef(indx).lim(2)
                        throw(MException('bdtoolkit:syscheck:lagdef','The sys.lagdef(%d).lim field does not contain valid [lower, upper] limits',indx));
                    end                    
                end
            end
            
            % case of SDE
            if isfield(sys,'sdeF')
                % check that sys.sdeF is a function handle
                if ~isa(sys.sdeF,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeF','The sys.sdeF field must be a function handle'));
                end
                
                % check that sys.sdeF is in the search path
                if strcmp(func2str(sys.sdeF),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:sdeF','The sys.sdeF field contains a handle to a missing function.'));
                end
                
                % check that sys.sdeG is a function handle
                if ~isa(sys.sdeG,'function_handle')
                    throw(MException('bdtoolkit:syscheck:sdeG','The sys.sdeG field must be a function handle'));
                end
                
                % check that sys.sdeG is in the search path
                if strcmp(func2str(sys.sdeG),'UNKNOWN Function')
                    throw(MException('bdtoolkit:syscheck:sdeG','The sys.sdeG field contains a handle to a missing function.'));
                end
                
                % check sys.sdesolver
                if ~isfield(sys,'sdesolver')
                    sys.sdesolver = {@sdeEM,@sdeSH};
                end
                if ~iscell(sys.sdesolver)
                    throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver field must be a cell array'));
                end
                if size(sys.sdesolver,1)~=1 && size(sys.sdesolver,2)~=1
                    throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver cell array must be one dimensional'));
                end                    
                for indx=1:numel(sys.sdesolver)
                    % check that each sys.sdesolver is a function handle
                    if ~isa(sys.sdesolver{indx},'function_handle')
                        throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver{%d} cell must be a function handle',indx));
                    end
                    % check that each sys.sdesolver is in the search path
                    if strcmp(func2str(sys.sdesolver{indx}),'UNKNOWN Function')
                        throw(MException('bdtoolkit:syscheck:sdesolver','The sys.sdesolver{%d} cell contains a handle to a missing function.',indx));
                    end
                end

                % check sys.sdeoption
                if ~isfield(sys,'sdeoption')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption field is undefined'));
                end
                if ~isstruct(sys.sdeoption)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption field must be a struct'));
                end
                
                % check sys.sdeoption.InitialStep
                if ~isfield(sys.sdeoption,'InitialStep')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.InitialStep field is undefined'));
                end
                if ~isnumeric(sys.sdeoption.InitialStep) && ~isempty(sys.sdeoption.InitialStep)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.InitialStep field must be numeric'));
                end
                
                % check sys.sdeoption.NoiseSources
                if ~isfield(sys.sdeoption,'NoiseSources')
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.NoiseSources field is undefined'));
                end
                if ~isnumeric(sys.sdeoption.NoiseSources)
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.NoiseSources field must be numeric'));
                end
                if numel(sys.sdeoption.NoiseSources)~=1
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.NoiseSources field must be a scalar value'));
                end
                if mod(sys.sdeoption.NoiseSources,1)~=0
                    throw(MException('bdtoolkit:syscheck:sdeoption','The sys.sdeoption.NoiseSources field must be an integer value'));
                end
                
                % check sys.sdeoption.randn (an optional parameter)
                if isfield(sys.sdeoption,'randn')
                    if ~isnumeric(sys.sdeoption.randn)
                        throw(MException('bdtoolkit:syscheck:sdeoption','The sys.odeoption.randn field must be numeric'));
                    end
                    if size(sys.sdeoption.randn,1) ~= sys.sdeoption.NoiseSources
                        throw(MException('bdtoolkit:syscheck:sdeoption','The number of rows in sys.sdeoption.randn must equal sys.sdeoption.NoiseSources')); 
                    end
                end
            end            
            
            % check sys.panels 
            if ~isfield(sys,'panels')
                throw(MException('bdtoolkit:syscheck:panels','The sys.panels field is undefined'));
            end
            if ~isstruct(sys.panels)
                throw(MException('bdtoolkit:syscheck:panels','The sys.panels field must be a struct'));
            end
            
            % all tests have passed, return the updated sys.
            sysout = sys;
        end
     
    end
    
end

