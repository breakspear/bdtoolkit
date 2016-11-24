function sys = ODEdemo1()
    % ODEdemo1  Example ordinary differential equation
    %   Implements the simple ordinary differential equation
    %        y'(t) = a*Y + b*t
    %   for use with the Brain Dynamics toolbox.
    %
    % Example 1: Using the Brain Dynamics GUI
    %   sys = ODEdemo1();       % construct the system struct
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    % 
    % Example 2: Using ODE45 manually
    %   sys = ODEdemo1();                         % construct the system struct
    %   odefun = sys.odefun;                      % ODE function handle
    %   [a,b] = deal(sys.pardef{:,2});            % default parameters
    %   [Y0] = deal(sys.vardef{:,2});             % initial conditions
    %   odeopt = sys.odeopt;                      % default solver options
    %   tspan = sys.tspan;                        % default time span
    %   sol = ode45(odefun,tspan,Y0,odeopt,a,b);  % call the matlab solver
    %   tsol = tspan(1):0.1:tspan(2);             % time domain of interest
    %   Y = deval(sol,tsol);                      % extract the solution
    %   plot(tsol,Y);                             % plot the result
    %   xlabel('time'); ylabel('y');

    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
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
    sys.pardef = {'a',1;                % ODE parameters {'name',value}
                  'b',2};
    sys.vardef = {'y',0};               % ODE variables {'name',value}
    sys.solver = {'ode45','ode23'};     % pertinent matlab ODE solvers
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 5];                  % default time span  
    
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
end

% The ODE function.
function dYdt = odefun(t,Y,a,b)  
    dYdt = a*Y + b*t;
end
    