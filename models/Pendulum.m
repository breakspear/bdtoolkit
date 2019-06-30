% Pendulum Equations of motion for a damped and driven pendulum.
%
% Example:
%   sys = Pendulum();                 % Construct the system struct.
%   gui = bdGUI(sys);                 % Open the Brain Dynamics GUI.
%
% Authors
%   Stewart Heitmann (2019a)
%
% References
%   Strogatz (1994) Nonlinear Dynamics and Chaos. Section 6.7. 

% Copyright (C) 2019 Stewart Heitmann. All rights reserved.
function sys = Pendulum()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','b',     'value',0,  'lim',[0 1])
        struct('name','gamma', 'value',0,  'lim',[0 1])
        ];

    % Our ODE variables        
    sys.vardef = [
        struct('name','theta', 'value',2*pi*(rand-0.5), 'lim',[-pi pi])
        struct('name','mu',    'value',rand,            'lim',[-4 4])
        ];
    
    % Default time span
    sys.tspan = [0 300];
              
    % Specify ODE solvers and default options
    sys.odeoption = odeset('RelTol',1e-6, 'InitialStep',0.1);   % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Pendulum}';
        '';
        'Equations of motion for a damped and driven pendulum';
        '\qquad $\ddot \theta = -b \, \dot \theta - \sin(\theta) + \gamma$'
        'where $\dot \theta = \mu$.';
        '';
        'See Section 6.7 of Strogatz (1994) Nonlinear Dynamics and Chaos.';
        };
    
    % Display panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdPhasePortrait = [];
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function.
function dY = odefun(t,Y,b,gamma)  
    % extract incoming variables from Y
    theta = Y(1);
    mu = Y(2);

    % Pendulum equations of motion
    dtheta = mu;
    dmu = -b*mu - sin(theta) + gamma;

    % return result
    dY = [dtheta; dmu];
end