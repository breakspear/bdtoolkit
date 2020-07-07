function sys = HopfXY()
    % HopfXY  Normal form of the Hopf bifurcation in cartesian coordinates
    %    dx/dt = -y + (alpha - x^2 - y^2)*x
    %    dy/dt =  x + (alpha - x^2 - y^2)*y
    % where the radius of the limit cycle is sqrt(alpha).
    %
    % Example:
    %   sys = HopfXY();         % construct the system struct
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    %
    % Authors
    %   Stewart Heitmann (2020)

    % Copyright (C) 2020 Stewart Heitmann. All rights reserved.
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

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE parameter definitions
    sys.pardef = [ struct('name','alpha', 'value',0.25, 'lim',[-1 1]) ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','x', 'value',2*rand-1, 'lim',[-1 1]) 
        struct('name','y', 'value',2*rand-1, 'lim',[-1 1]) 
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '\textbf{Hopf XY}'
        ''
        'Normal form of the Hopf bifurcation in cartesian coordinates'
        '\qquad $\dot x = -y + (\alpha - x^2 - y^2)\, x$'
        '\qquad $\dot y =  x + (\alpha - x^2 - y^2)\, y$'
        'where the radius of the limit cycle is $\sqrt \alpha$.'
        };

    % Time Portrait panel 
    sys.panels.bdTimePortrait = [];

    % Phase Portrait panel
    sys.panels.bdPhasePortrait = [];
  
    % Solver panel
    sys.panels.bdSolverPanel = [];
    
    % Default time span (optional)
    sys.tspan = [0 200]; 

    % Specify the relevant ODE solvers (optional)
    sys.odesolver = {@ode45,@ode23,@odeEul};
    
    % ODE solver options (optional)
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
    sys.odeoption.InitialStep = 0.01;   % Step-size for Euler method
end

% The ODE function.
function dY = odefun(~,Y,alpha) 
    % extract incoming states
    x = Y(1);
    y = Y(2);
    
    % Hopf normal form
    dx = -y + (alpha - x^2 - y^2)*x;
    dy =  x + (alpha - x^2 - y^2)*y;
    
    % Return results
    dY = [dx; dy];
end
