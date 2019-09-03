function sys = Lorenz()
    % Lorenz  The Lorenz equations in three variables
    %        dx/dt = sigma * (y-x)
    %        dy/dt = r*x - y - x*z
    %        dz/dt = x*y - b*z
    % for use with the Brain Dynamics Toolbox.
    %
    % Example:
    %   sys = Lorenz();         % construct the Lorenz model
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    %
    % Authors
    %   Stewart Heitmann (2019b)

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE parameter definitions
    sys.pardef = [
        struct('name','sigma', 'value', 10)
        struct('name','r',     'value', 28)
        struct('name','b',     'value', 8/3)
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','x', 'value',40*rand-20, 'lim',[-20 20])
        struct('name','y', 'value',60*rand-30, 'lim',[-30 30]) 
        struct('name','z', 'value',50*rand,    'lim',[0 50])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '\textbf{Lorenz}';
        '';
        'The Lorenz equations in three dynamic variables';
        '\qquad $\dot x = \sigma \, (y - x)$';
        '\qquad $\dot y = rx - y - xz$';
        '\qquad $\dot z = xy - bz$';
        'where $\sigma,r,b$ are scalar constants.';
        ''
        'Chaos is observed for $\sigma{=}10$, $r{=}28$, $b{=}8/3$ and nearby parameter values.'
        };

    % Time Portrait panel 
    sys.panels.bdTimePortrait = [];

    % Phase Portrait panel
    sys.panels.bdPhasePortrait = [];
  
    % Solver panel
    sys.panels.bdSolverPanel = [];
    
    % Default time span (optional)
    sys.tspan = [0 20]; 

    % ODE solver options
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
    sys.odeoption.InitialStep = 0.1;    % Required by Euler method
end

% The ODE function.
function dY = odefun(t,Y,sigma,r,b)
    % extract the incoming state variables
    x = Y(1);
    y = Y(2);
    z = Y(3);
    
    % Lorenz Equations
    dx = sigma*(y-x);
    dy = r*x - y - x*z;
    dz = x*y - b*z;
    
    % return a column vector
    dY = [dx; dy; dz];
end
