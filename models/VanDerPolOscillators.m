function sys = VanDerPolOscillators(Kij)
    % VanDerPolOscillators  System of N coupled van der Pol ocillators
    %   Implements a set of n coupled van der Pol equation
    %        Ui' = Vi
    %        Vi' = a*(1-Ui^2)*Vi - Ui - b*Kij*Ui
    %   where i=1..n and Kij is an nxn coupling matrix
    %
    % Example 1: Using the Brain Dynamics GUI
    %   n = 20;                             % number of nodes
    %   Kij = circshift(eye(n),1) + ...     % nearest-neighbour coupling
    %         circshift(eye(n),-1);
    %   sys = VanDerPolOscillators(Kij);    % construct the system struct
    %   gui = bdGUI(sys);                   % open the Brain Dynamics GUI
    % 
    % Example 2: Using the Brain Dynamics command-line solver
    %   n = 20;                                             % number of nodes
    %   Kij = circshift(eye(n),1) + ...                     % nearest-neighbour
    %         circshift(eye(n),-1);                         % coupling
    %   sys = VanDerPolOscillators(Kij);                    % system struct
    %   sys.pardef = bdSetValue(sys.pardef,'a',1);          % set 'a' parameter
    %   sys.pardef = bdSetValue(sys.pardef,'b',1.3);        % set 'b' parameter
    %   sys.vardef = bdSetValue(sys.vardef,'U',rand(n,1));  % set 'y1' variable
    %   sys.vardef = bdSetValue(sys.vardef,'V',rand(n,1));  % set 'y2' variable
    %   sys.tspan = [0 10];                                 % set time domain
    %   sol = bdSolve(sys);                                 % solve
    %   tplot = 0:0.1:10;                                   % plot time domain
    %   U = bdEval(sol,tplot,1:n);                          % U solution
    %   V = bdEval(sol,tplot,(1:n)+n);                      % V solution
    %   plot(tplot,U,'b', tplot,V,'r');                     % plot the result
    %   xlabel('time'); ylabel('U (blue), V (red)');        % axis labels
    %
    % Authors
    %   Stewart Heitmann (2016a,2017a,2018a)

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

    % determine the number of nodes from Kij
    n = size(Kij,1);

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE parameters
    sys.pardef = [ struct('name','Kij', 'value',Kij,  'lim',[0 2]);
                   struct('name','a',   'value',  1,  'lim',[-1 2]);
                   struct('name','b',   'value',0.2,  'lim',[0 1]) ];
    
    % ODE variables           
    sys.vardef = [ struct('name','U',   'value',rand(n,1), 'lim',[-2.5 2.5]);
                   struct('name','V',   'value',rand(n,1), 'lim',[-2.5 2.5]) ];
               
    % Default time span
    sys.tspan = [0 100];
              
    % Specify ODE solvers and default options
    %sys.odesolver = {@ode45,@ode23,@ode113};    % ODE solvers
    sys.odeoption.RelTol = 1e-6;                % ODE solver options
    %sys.odeoption.AbsTol = 1e-6;                % see odeset 

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{Van der Pol Oscillators}';
        '';
        'A network of coupled van der Pol oscillators';
        '\qquad $\dot U_i = V_i$';
        '\qquad $\dot V_i = a\,(1 - U_i^2)\,V_i - U_i - b\,\sum_j K_{ij}\,U_j$';
        'where';
        '\qquad $U_i(t)$ and $V_i(t)$ are the dynamic variables ($n$ x $1$),';
        '\qquad $K_{ij}$ is the connectivity matrix ($n$ x $n$),';
        '\qquad $a$ and $b$ are scalar constants,';
        '\qquad $i,j{=}1 \dots n$.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$.'];
        '\qquad 2. Oscillations occur for $a>0$.';
        '\qquad 3. Network coupling is scaled by $b$.'};
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];   
end

% The ODE function.
function dYdt = odefun(t,Y,Kij,a,b)  
    % extract incoming [U,V] values from Y
    Y = reshape(Y,[],2);                % reshape Y to two colums
    U = Y(:,1);                         % 1st column contains U
    V = Y(:,2);                         % 2nd column contains V
    
    % Coupled van der Pol equations (in vector form)
    dU = V;
    dV = a*(1-U.^2).*V - U - b*Kij*U;
    
    % return a column vector
    dYdt=[dU; dV];
end
   
