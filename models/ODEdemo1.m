function sys = ODEdemo1()
    % ODEdemo1  Simple Ordinary Differential Equation
    %   Implements the simple ordinary differential equation
    %        y'(t) = a*Y + b*t
    %   for use with the Brain Dynamics toolbox.
    %
    % Example 1: Using the Brain Dynamics GUI
    %   sys = ODEdemo1();       % construct the system struct
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    % 
    % Example 2: Using the Brain Dynamics command-line solver
    %   sys = ODEdemo1();                               % get system struct
    %   sys.pardef = bdSetValue(sys.pardef,'a',-0.1);   % set 'a' parameter
    %   sys.vardef = bdSetValue(sys.vardef,'y',rand);   % set 'y' variable
    %   sys.tspan = [0 10];                             % set time domain
    %   sol = bdSolve(sys);                             % solve
    %   tplot = 0:0.1:10;                               % plot time domain
    %   Y = bdEval(sol,tplot);                          % extract solution
    %   plot(tplot,Y);                                  % plot the result
    %   xlabel('time'); ylabel('y');
    %    
    % Example 3: Using ODE45 manually
    %   sys = ODEdemo1();                         % get the system struct
    %   odefun = sys.odefun;                      % ODE function handle
    %   [a,b] = deal(sys.pardef{:,2});            % default parameters
    %   [Y0] = deal(sys.vardef{:,2});             % initial conditions
    %   odeopt = sys.odeoption;                   % default solver options
    %   tspan = sys.tspan;                        % default time span
    %   sol = ode45(odefun,tspan,Y0,odeopt,a,b);  % call the matlab solver
    %   tsol = tspan(1):0.1:tspan(2);             % time domain of interest
    %   Y = deval(sol,tsol);                      % extract the solution
    %   plot(tsol,Y);                             % plot the result
    %   xlabel('time'); ylabel('y');
    %
    % Authors
    %   Stewart Heitmann (2016a)

    % Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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

    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'a',-1;               % ODE parameters {'name',value}
                  'b',0.01};
    sys.vardef = {'y',rand};            % ODE variables {'name',value}
    sys.tspan = [0 20];                 % default time span  

    % Specify ODE solvers and default options
    sys.odesolver = {@ode45,@ode23,@odeEuler};  % ODE solvers
    sys.odeoption.RelTol = 1e-6;                % ODE solver options
    sys.odeoption.AbsTol = 1e-6;                % see odeset 
    
    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{ODEdemo1}';
        '';
        'A simple example of an Ordinary Differential Equation (ODE) \medskip';
        '\qquad $\dot Y(t) = a\,Y(t) + b\,t$ \medskip';
        'where $a$ and $b$ are scalar constants.'};
    
    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';
    
    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';
    
    % Handle to this function. The GUI uses it to construct a new system. 
    sys.self = str2func(mfilename);
end

% The ODE function.
function dYdt = odefun(t,Y,a,b)  
    dYdt = a*Y + b*t;
end

