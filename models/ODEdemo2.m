function sys = ODEdemo2()
    % ODEdemo2  Example van der Pol equation
    %   Implements the van der Pol equation
    %        y1'(t) = y2(t)
    %        y2'(t) = a*(1-y1^2)*y2 - y1
    %   for use with the Brain Dynamics toolbox.
    %
    % Example 1: Using the Brain Dynamics GUI
    %   sys = ODEdemo2();       % construct the system struct
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    % 
    % Example 2: Using ODE45 manually
    %   sys = ODEdemo2();                         % construct the system struct
    %   odefun = sys.odefun;                      % ODE function handle
    %   [a] = deal(sys.pardef{:,2});              % default parameters
    %   [y1,y2] = deal(sys.vardef{:,2});          % initial conditions
    %   Y0=[y1;y2];                               % concatenate as a column
    %   odeopt = sys.odeopt;                      % default solver options
    %   tspan = sys.tspan;                        % default time span
    %   sol = ode45(odefun,tspan,Y0,odeopt,a);    % call the matlab solver
    %   tsol = tspan(1):0.1:tspan(2);             % time domain of interest
    %   Y = deval(sol,tsol);                      % extract the solution
    %   plot(tsol,Y);                             % plot the result
    %   xlabel('time');
    %   ylabel('y');

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
    sys.pardef = {'a',1};               % ODE parameters {'name',value}
    sys.vardef = {'y1',rand;            % ODE variables {'name',value}
                  'y2',rand};
    sys.solver = {'ode45','ode113'};    % pertinent matlab ODE solvers
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 20];                 % default time span 
    sys.texstr = {'\textbf{ODEdemo2} \medskip';
                  'The van der Pol oscillator \smallskip';
                  '\qquad $\dot U(t) = V(t)$ \smallskip';
                  '\qquad $\dot V(t) = a\,\big(1 - U^2(t)\big)\,V(t) - U(t)$ \smallskip';
                  'where \smallskip';
                  '\qquad $U(t)$ and $V(t)$ are the dynamic variables,';
                  '\qquad $a$ is a scalar constant. \medskip';
                  'Notes';
                  '\qquad 1. Oscillations occur for $a>0$.'};
end

% The ODE function.
function dYdt = odefun(t,Y,a)  
    dy1 = Y(2);
    dy2 = a*(1-Y(1)^2)*Y(2) - Y(1);
    dYdt=[dy1; dy2];
end
   