%bdEvolve  Evolve an initial-value problem using the Brain Dynamics Toolbox
%Usage: 
%   [sys,sol] = bdEvolve(sys)
%   [sys,sol] = bdEvolve(sys,rep)
%   [sys,sol] = bdEvolve(sys,rep,tspan)
%   [sys,sol] = bdEvolve(sys,rep,tspan,@solverfun)
%   [sys,sol] = bdEvolve(sys,rep,tspan,@solverfun,solvertype)
%where
%   sys is a system struct describing the dynamical system
%   rep=1 is the number of repeat simulation runs to perform (optional)
%   tspan=[0 100] is the time span of the integration (optional)
%   @solverfun is a function handle to an ode/dde/sde solver (optional)
%   solvertype is a string describing the type of solver (optional).
%
%   The tspan, @solverfun and solvertype arguments are all optional.
%   If tspan is omitted then it defaults to sys.tspan.
%   If @solverfun is omitted then it defaults to the first solver in sys.
%   If @solverfun is supplied but it is not known to the sys struct then
%   you must also supply the solvertype string ('odesolver', 'ddesolver'
%   or 'sdesolver').
%
%RETURNS
%   sys is updated with new initial conditions that correspond to the final 
%      conditions of the last simulation run.
%   sol is the solution structure. It has the same format as that returned
%      by the matlab ode45 solver. Use the bdEval function to extract the
%      results from sol.
%
%EXAMPLE
%   sys = WilsonCowan;                           % Wilson-Cowan Equations
%   sys.pardef = bdSetValue(sys.pardef,'Je',2);  % Set parmater Je=2
%   rep = 10;                                    % number of repeat runs
%   [sys,sol] = bdEvolve(sys,rep);               % evolve the system
%   plot(sol.y(1,:),sol.y(2,:));                 % plot the phase portrait
%   xlabel('E'); ylabel('I');
%
%AUTHORS
%   Stewart Heitmann (2018b)

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
function [sys,sol] = bdEvolve(sys,rep,tspan,solverfun,solvertype)
        % check the number of output variables
        if nargout>2
            error('Too many output variables');
        end
        
        % check the number of input variables
        if nargin<1
            error('Not enough input parameters');
        end
   
        % check the validity of the sys struct and fill missing fields with default values
        try
            sys = bd.syscheck(sys);
        catch ME
            throwAsCaller(ME);
        end

        % use defaults for missing input parameters
        switch nargin
            case 1  
                % Caller specified bdEvolve(sys).
                
                % Perform one siimulation run only.
                rep = 1;
                
                % Get tspan from sys.tspan 
                tspan = sys.tspan;
                
                % Get solverfun and solvertype from sys 
                if isfield(sys,'odesolver')
                    solverfun = sys.odesolver{1};
                    solvertype = 'odesolver';
                end
                if isfield(sys,'ddesolver')
                    solverfun = sys.ddesolver{1};
                    solvertype = 'ddesolver';
                end
                if isfield(sys,'sdesolver')
                    solverfun = sys.sdesolver{1};
                    solvertype = 'sdesolver';
                end

            case 2  
                % Caller specified bdEvolve(sys,rep).
                
                % Get tspan from sys.tspan 
                tspan = sys.tspan;
                
                % Get solverfun and solvertype from sys 
                if isfield(sys,'odesolver')
                    solverfun = sys.odesolver{1};
                    solvertype = 'odesolver';
                end
                if isfield(sys,'ddesolver')
                    solverfun = sys.ddesolver{1};
                    solvertype = 'ddesolver';
                end
                if isfield(sys,'sdesolver')
                    solverfun = sys.sdesolver{1};
                    solvertype = 'sdesolver';
                end
                
            case 3
                % Caller specified bdEvolve(sys,rep,tspan).
                
                % Get solverfun and solvertype from sys 
                if isfield(sys,'odesolver')
                    solverfun = sys.odesolver{1};
                    solvertype = 'odesolver';
                end
                if isfield(sys,'ddesolver')
                    solverfun = sys.ddesolver{1};
                    solvertype = 'ddesolver';
                end
                if isfield(sys,'sdesolver')
                    solverfun = sys.sdesolver{1};
                    solvertype = 'sdesolver';
                end
                
            case 4
                % Caller specified bdEvolve(sys,rep,tspan,solverfun).
                
                % Get solvertype from sys 
                if isfield(sys,'odesolver')
                    solvertype = 'odesolver';
                end
                if isfield(sys,'ddesolver')
                    solvertype = 'ddesolver';
                end
                if isfield(sys,'sdesolver')
                    solvertype = 'sdesolver';
                end
        end
        
        try
            % for each repeat simulation
            for r=1:rep
                % Call the appropriate solver
                sol = bd.solve(sys,tspan,solverfun,solvertype);
            
                % Update the initial conditions
                sys.vardef = bdSetValues(sys.vardef,sol.y(:,end));
            end
            
        catch ME
            throwAsCaller(ME);
        end
        
end
