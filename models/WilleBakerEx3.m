% WilleBakerEx3 Delay Differential Equations with constant delays 
%   This is based on example 3 by Wille' and Baker (1992).
%   Extra parameters (a,b,c) have been included for demonstration.
%   
%   The differential equations
%
%        a y'_1(t) = y_1(t-1)
%        b y'_2(t) = y_1(t-1) + y_2(t-0.2)
%        c y'_3(t) = y_2(t)
%
%   are solved on [0,5] with constant history y_1(t)=1, y_2(t)=1, y_3(t)=1
%   for t<=0.
%
% EXAMPLE
%   sys = WilleBakerEx3();  % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2016a-2018a)

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
function sys = WilleBakerEx3()
    % Handle to our DDE function
    sys.ddefun = @ddefun;
    
    % DDE parameters
    sys.pardef = [ struct('name','a', 'value', 1);
                   struct('name','b', 'value', 1);
                   struct('name','c', 'value', 1) ];
               
    % DDE lag parameters
    sys.lagdef = [ struct('name','tau1', 'value',1.0);
                   struct('name','tau2', 'value',0.2) ];
               
    % DDE state variables
    sys.vardef = [ struct('name','y1', 'value',1);
                   struct('name','y2', 'value',1);
                   struct('name','y3', 'value',1) ];
               
    % Default time span
    sys.tspan = [0 20]; 

    % Specify DDE solvers and default options
    sys.ddesolver = {@dde23};                  % DDE solvers
    sys.ddeoption = ddeset('RelTol',1e-6);     % DDE solver options    
    
    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Will\''e \& Baker (1992) Example 3}';
        '';
        'Delay Differential Equations';
        '\qquad $a\,\dot y_1(t)=y_1(t-\tau_1)$';
        '\qquad $b\,\dot y_2(t)=y_1(t-\tau_1)+y_2(t-\tau_2)$';
        '\qquad $c\,\dot y_3(t)=y_2(t)$';
        'where';
        '\qquad $y_1(t), y_2(t), y_3(t)$ are state variables,';
        '\qquad $\tau_1,\tau_2$ are constant time delays.';
        '\qquad $a,b,c$ are time scale constants.';
        '';
        'References';
        '\qquad 1. Will\''e and Baker (1992) DELSOL. Appl Num Math (9) 3-5.' ;   
        '\qquad 2. Matlab example code DDEX1.m.' ;
        '\qquad 3. Shampine and Thompson (2001) Solving DDEs in MATLAB.' };   
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = []; 
end

% The DDE function where Y and dYdt are (3x1) and Z is (3x2).
function dYdt = ddefun(t,Y,Z,a,b,c)  
    Ylag1 = Z(:,1);                      % Y(t-tau1)
    Ylag2 = Z(:,2);                      % Y(t-tau2)
    dy1dt = Ylag1(1) ./ a;               % a * y'_1(t) = y_1(t-tau1)
    dy2dt = (Ylag1(1) + Ylag2(2)) ./ b;  % b * y'_2(t) = y_1(t-tau1) + y_2(t-tau2)
    dy3dt = Y(2) ./ c;                   % c * y'_3(t) = y_2(t)
    dYdt = [dy1dt; dy2dt; dy3dt];        % return a column vector
end
