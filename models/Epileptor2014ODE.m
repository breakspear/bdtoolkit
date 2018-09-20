% Epileptor model of seizure evolution by Jirsa et al (2014).
% This ODE variant represents the deterministic equations only.
%
% Example
%    sys = Epileptor2014ODE();
%    gui = bdGUI(sys);
%
% Authors
%   Stewart Heitmann (2018b)
%
% References:
% Jirsa, Stacey, Quilichini, Ivanov, Bernard (2014) On the nature of 
%   seizure dynamics. Brain. doi:10.1093/brain/awu133
%
function sys = Epileptor2014ODE()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','x0',     'value',-1.6,   'lim',[-2 1]); 
        struct('name','y0',     'value',1,      'lim',[0 2]);
        struct('name','tau0',   'value',2857,   'lim',[0.1 3000]);
        struct('name','tau2',   'value',10,     'lim',[0.1 20]);
        struct('name','Irest1', 'value',3.1,    'lim',[-5 5]);
        struct('name','Irest2', 'value',0.45,   'lim',[-5 5]);
        struct('name','gamma',  'value',0.01,   'lim',[0 0.1]);
        ];
               
    % Our ODE variables        
    sys.vardef = [ 
        struct('name','x1', 'value',0,      'lim',[-2 1]);
        struct('name','y1', 'value',-5,     'lim',[-20 2]);
        struct('name','z',  'value',3,      'lim',[2 5]);
        struct('name','x2', 'value',0,      'lim',[-2 0]);
        struct('name','y2', 'value',0,      'lim',[0 2]);
        struct('name','u',  'value',0,      'lim',[-0.5 0.1]);
        ];
    
    % Simulation time span
    sys.tspan = [0 3000];

    % Solver options
    sys.odeoption.RelTol = 1e-6;
    sys.odeoption.InitialStep = 0.1;
    
    % Latex (Equations) panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Epileptor} (Jirsa et al 2014). The deterministic equations.';
        '';
        'Characterizes the dynamical behaviour of epileptic seizures using five';
        'state variables $(x_1,y_1,x_2,y_2,z)$ plus a dummy variable $(u)$.';
        '\qquad $\dot x_1 = y_1 - f_1(x_1,y_1,z) - z + I_{rest,1}$';
        '\qquad $\dot y_1 = y_0 - 5 x_1^2 - y_1$';
        '\qquad $\tau_0 \; \dot z = 4(x_1- x_0) - z$';
        '\qquad $\dot x_2 = -y_2 + x_2 - x_2^3 + I_{rest,2} + 2u - 0.3(z-3.5)$';
        '\qquad $\tau_2 \;\dot y_2 = -y_2 + f_2(x_2)$';
        '\qquad $\dot u = -\gamma (u - 0.1 x_1)$';
        'where';
        '\qquad $x_1(t), y_1(t)$ govern the rapid discharges on the fast timescale,';
        '\qquad $x_2(t), y_2(t)$ govern spike-and-waves on the intermediate timescale,';
        '\qquad $z(t)$ is the permittivity variable that operates on a slow timescale,';
        '\qquad $u(t)$ is a dummy variable for low-pass filtering signals from x1 to x2,';
        '\qquad $x_0, y_0$ are threshold constants,';
        '\qquad $\tau_0$ and $\tau_2$ are time constants,';
        '\qquad $I_{rest,1}$ and $I_{rest,2}$ are injection currents.';
        '\qquad $\gamma$ is the time constant of the low-pass filter,';
        'and';
        '\qquad $f_1(x_1,x_2,z) = x_1^3 - 3 x_1^2 \;$ \qquad \qquad \qquad \quad when $x_1 < 0$,';
        '\qquad $f_1(x_1,x_2,z) = (x_2 - 0.6 (z-4)^2) \; x_1$ \qquad otherwise,';
        'and';
        '\qquad $f_2(x_2) = 0 \;\;$ \qquad \qquad \qquad \quad when $x_2 < -0.25$,';
        '\qquad $f_2(x_2) = 6(x_2 + 0.25)\;\;\;$ \qquad otherwise.';
        '';
        '';
        '\textbf{References}';
        'Jirsa, et al (2014) On the nature of seizure dynamics. Brain.';
        };
    
    % Time-Portrait panel
    sys.panels.bdTimePortrait = [];
    
    % Phase-Portrait panel
    sys.panels.bdPhasePortrait = [];
    
    % Auxiliary Plot panel
    sys.panels.bdAuxiliary.auxfun = {@FieldPotential};

    sys.panels.bdSolverPanel = [];                 
end

% Our ODE function
function dY = odefun(~,Y,x0,y0,tau0,tau2,Irest1,Irest2,gamma)  
    % extract incoming variables from Y
    x1 = Y(1);
    y1 = Y(2);
    z  = Y(3);
    x2 = Y(4);
    y2 = Y(5);
    u  = Y(6);
    
    dx1 = y1 - f1(x1,x2,z) - z + Irest1;
    dy1 = y0 - 5*x1^2 - y1;
    dz  = (4*(x1-x0) - z)./tau0;
    dx2 = -y2 + x2 - x2^3 + Irest2 + 2*u - 0.3*(z-3.5);
    dy2 = (-y2 + f2(x2))./tau2;
    du  = -gamma*(u - 0.1*x1);
    
    % return result
    dY = [dx1; dy1; dz; dx2; dy2; du];
end

function y = f1(x1,x2,z)
    if x1 < 0
        y = x1^3 - 3*x1^2;
    else
        y = (x2 - 0.6*(z-4)^2) * x1;
    end
end

function y = f2(x2)
    if x2 < -0.25
        y = 0;
    else
        y = 6*(x2 + 0.25);
    end
end

% Auxiliary function that plots the time course of the simulated field
% potential (-x1+x2)
function UserData = FieldPotential(ax,~,sol,~,~,~,~,~,~,~)
    % extract the solution data
    t = sol.x;
    x1 = sol.y(1,:);
    x2 = sol.y(4,:);

    % Plot the conductances.
    plot(t, -x1+x2, 'k-');
    ylim([-5 5]);
    xlim([t(1) t(end)]);
    title('Simulated Field Potential'); 
    ylabel('-x1 + x2');
    xlabel('time');
    
    % Make the data available to the workspace
    UserData.t = t;
    UserData.p = -x1+x2;
end


