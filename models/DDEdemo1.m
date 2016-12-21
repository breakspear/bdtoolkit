% DDEdemo1  Delay Differential Equations with constant delays 
%   This is based on the simple example of Wille' and Baker for DDE23.
%   Extra parameters (a,b,c,d) have been included for demonstration.
%   
%   The differential equations
%
%        y'_1(t) = a*y_1(t-1)
%        y'_2(t) = b*y_1(t-1) + c*y_2(t-0.2)
%        y'_3(t) = d*y_2(t)
%
%   are solved on [0,5] with constant history y_1(t)=1, y_2(t)=1, y_3(t)=1
%   for t<=0.
%
% Example 1: Using the Brain Dynamics GUI
%   sys = DDEdemo1();       % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
% 
% Example 2: Using the Brain Dynamics command-line solver
%   sys = DDEdemo1();                               % get system struct
%   sys.pardef = bdSetValue(sys.pardef,'a',-1);     % set 'a' parameter
%   sys.pardef = bdSetValue(sys.pardef,'b', 1);     % set 'b' parameter
%   sys.pardef = bdSetValue(sys.pardef,'c',-1);     % set 'c' parameter
%   sys.pardef = bdSetValue(sys.pardef,'d', 1);     % set 'd' parameter
%   sys.lagdef = bdSetValue(sys.lagdef,'tau1',  1); % set 'tau1' lag value
%   sys.lagdef = bdSetValue(sys.lagdef,'tau2',0.2); % set 'tau2' lag value
%   sys.vardef = bdSetValue(sys.vardef,'y1',rand);  % 'y1' initial value
%   sys.vardef = bdSetValue(sys.vardef,'y2',rand);  % 'y2' initial value
%   sys.vardef = bdSetValue(sys.vardef,'y3',rand);  % 'y3' initial value
%   sys.tspan = [0 10];                             % set time domain
%   sol = bdSolve(sys);                             % solve
%   tplot = 0:0.1:10;                               % plot time domain
%   Y = bdEval(sol,tplot);                          % extract solution
%   plot(tplot,Y);                                  % plot the result
%   xlabel('time'); ylabel('y');
%
% Example 2: Calling DDE23 manually
%   sys = DDEdemo1();                       % construct the system struct
%   ddefun = sys.ddefun;                    % get DDE function handle
%   [a,b,c,d] = deal(sys.pardef{:,2});      % default parameter values
%   [tau1,tau2] = deal(sys.lagdef{:,2});    % default lag values
%   [y1,y2,y3] = deal(sys.vardef{:,2});     % default initial conditions
%   ddeopt = sys.ddeoption;                 % default DDE options
%   tspan = sys.tspan;                      % default time span
%   sol = dde23(ddefun,[tau1;tau2],[y1;y2;y3],tspan,ddeopt,a,b,c,d);
%   t = linspace(tspan(1),tspan(2),1000);   % time domain of interest
%   Y = deval(sol,t);                       % interpolate the results
%   plot(t,Y);                              % plot the results
%   xlabel('time');
%   legend('y1','y2','y3');
%
% Authors
%   Stewart Heitmann (2016a)

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
function sys = DDEdemo1()
    sys.ddefun = @ddefun;               % Handle to our DDE function
    sys.pardef = {'a',-1;               % DDE parameters {'name',value}
                  'b', 1;
                  'c',-1;
                  'd', 1};
    sys.lagdef = {'tau1',1;             % DDE lag parameters {'name',value}
                  'tau2',0.2};
    sys.vardef = {'y1',1;               % DDE variables {'name',value}
                  'y2',1;
                  'y3',1};
    sys.tspan = [0 20];                 % default time span 

    % Specify DDE solvers and default options
    sys.ddesolver = {@dde23};                  % DDE solvers
    sys.ddeoption = ddeset('RelTol',1e-6);     % DDE solver options    
    
    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{DDEdemo1}';
        '';
        'Delay Differential Equation with constant time delays';
        '\qquad $\dot y_1(t) = a\,y_1(t-\tau_1)$';
        '\qquad $\dot y_2(t) = b\,y_1(t-\tau_1) + c\,y_2(t-\tau_2)$';
        '\qquad $\dot y_3(t) = d\,y_2(t)$';
        'where';
        '\qquad $y_1(t), y_2(t), y_3(t)$ are the dynamic variables,';
        '\qquad $a,b,c,d$ are scalar constants,';
        '\qquad $\tau_1,\tau_2$ are constant time delays.';
        '';
        'Notes';
        '\qquad 1. The equations of Wille'' and Baker (see DDEX1, DDE23)' ;   
        '\qquad 2. Constant initial conditions apply for $t{<}t_0$' };
    
    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';
 
    % Include the Phase Portrait panel in the GUI
    sys.gui.bdPhasePortrait.title = 'Phase Portrait';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver'; 
    
    % Handle to this function. The GUI uses it to construct a new system. 
    sys.self = str2func(mfilename);
end

% The DDE function.
function dYdt = ddefun(t,Y,Z,a,b,c,d)  
    Ylag1 = Z(:,1);                     % Y(t-lag1)
    Ylag2 = Z(:,2);                     % Y(t-lag2)
    dy1dt = a*Ylag1(1);                 % y'_1(t) = a*y_1(t-1)
    dy2dt = b*Ylag1(1) + c*Ylag2(2);    % y'_2(t) = b*y_1(t-1) + c*y_2(t-0.2)
    dy3dt = d*Y(2);                     % y'_3(t) = d*y_2(t)
    dYdt = [dy1dt; dy2dt; dy3dt];       % return a column vector
end
