% MorrisLecar The Morris-Lecar model of neural excitability.
% This model has three presets that correspond to parameters given in Table 3.1
% of Ermentrout and Terman (2010). Specifically the Hopf regime, the Saddle-
% Node on Limit Cycle (SNLC), and the Homoclinic regime.
%
% Usage:
%   sys = MorrisLecar('Hopf');
%   sys = MorrisLecar('SNLC');
%   sys = MorrisLecar('Homoclinic');
%
% Example:
%   sys = MorrisLecar('Hopf');        % Construct the system struct.
%   gui = bdGUI(sys);                 % Open the Brain Dynamics GUI.
%
% Authors
%   Stewart Heitmann (2019a)
%
% References
%   Morris and Lecar (1981) Voltage Oscillations in the Barnicle Giant Muscle Fiber. Biophys J, 35:193-213.
%   Lecar (2007) Morris-Lecar model. Scholarpedia, 2(10):1333.
%   Ermentrout and Terman (2010) Mathematical Foundations of Neuroscience. Chapter 3.

% Copyright (C) 2019 Stewart Heitmann. All rights reserved.
function sys = MorrisLecar(flag)
    % Preset parameters from Table 3.1 of Ermentrout & Terman (2010) 
    switch flag 
        case 'Hopf'
            gCa = 4.4;
            V3 = 2;
            V4 = 30;
            phi = 0.04;
        case 'SNLC'
            gCa = 4;
            V3 = 12;
            V4 = 17.4;
            phi = 0.067;
        case 'Homoclinic'
            gCa = 4;
            V3 = 12;
            V4 = 17.4;
            phi = 0.23;
        otherwise
            error('flag must be ''Hopf'', ''SNLC'' or ''Homoclinic''');
    end

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','Cm',    'value',20,   'lim',[1 50])
        struct('name','gCa',   'value',gCa,  'lim',[0 10])
        struct('name','gK',    'value',8,    'lim',[0 10])
        struct('name','gL',    'value',2,    'lim',[0 10])
        struct('name','ECa',   'value',120,  'lim',[0 200])
        struct('name','EK',    'value',-84,  'lim',[-100 0])
        struct('name','EL',    'value',-60,  'lim',[-100 0])
        struct('name','V1',    'value',-1.2, 'lim',[-50 50])
        struct('name','V2',    'value',18,   'lim',[-50 50])
        struct('name','V3',    'value',V3,   'lim',[-50 50])
        struct('name','V4',    'value',V4,   'lim',[-50 50])
        struct('name','Iapp',  'value',60,   'lim',[0 100])
        struct('name','phi',   'value',phi,  'lim',[0 1])
        ];

    % Our ODE variables        
    sys.vardef = [
        struct('name','V', 'value',rand,     'lim',[-87 45])
        struct('name','n', 'value',rand,     'lim',[-0.1 0.6])
        ];
    
    % Default time span
    sys.tspan = [0 300];
              
    % Specify ODE solvers and default options
    sys.odeoption = odeset('RelTol',1e-6, 'InitialStep',0.1);        % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Morris-Lecar}';
        '';
        'The Morris-Lecar conductance-based model of neural excitability';
        '\qquad $C_m \dot V = -g_{Ca} m_{\infty} (V-E_{Ca}) - g_K n (V-E_K) - g_L(V-E_L) + I_{app}$'
        '\qquad $\tau \dot n = \phi (n_{\infty} - n)$'
        'where';
        '\qquad $V(t)$ is the membrane voltage,';
        '\qquad $n(t)$ is the potassium gating variable,';
        '\qquad $m_\infty(V) = 0.5 (1 + \tanh((V-V_1)/V_2))$ is the voltage-dependent calcium gate,';
        '\qquad $n_\infty(V) = 0.5 (1 + \tanh((V-V_3)/V_4))$ is the voltage-dependent potassium gate,';
        '\qquad $\tau(V) = 1 / \cosh((V-V_3)/(2V_4))$ is the time course of the potassium gate.';
        ''
        'Parameters';
        '\qquad $C_m$ is the membrane capacitance,';
        '\qquad $g_{Ca}$ is the maximal conductance of the calcium channel,';
        '\qquad $g_{K}$ is the maximal conductance of the potassium channel,';
        '\qquad $g_L$ is the leak conductance,';
        '\qquad $E_{Ca}$ is the reversal potential of the calcium channel,';
        '\qquad $E_{K}$ is the reversal potential of the potassium channel,';
        '\qquad $E_{L}$ is the reversal potential of the leak channel,';
        '\qquad $V_1,V_2,V_3,V4$ are parameters chosen to fit the voltage-clamp data,';
        '\qquad $I_{app}$ is an external current that is applied to the membrane,';
        '\qquad $\phi$ is the rate of the potassium channel.';
        '';
        'References:';
        '\quad Morris and Lecar (1981) Voltage Oscillations in the Barnicle Giant Muscle Fiber. Biophys J, 35:193-213.';
        '\quad Lecar (2007) Morris-Lecar model. Scholarpedia, 2(10):1333.';
        '\quad Ermentrout and Terman (2010) Mathematical Foundations of Neuroscience. Chapter 3.';
        };
    
    % Display panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdPhasePortrait = [];
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function.
function [dY,Iapp] = odefun(t,Y,Cm,gCa,gK,gL,ECa,EK,EL,V1,V2,V3,V4,Iapp,phi)  
    % extract incoming variables from Y
    V = Y(1);
    n = Y(2);

    % Morris-Lecar equations
    Minf = 0.5*(1 + tanh((V-V1)/V2));
    Ninf = 0.5*(1 + tanh((V-V3)/V4));
    dV = ( -gCa*Minf*(V-ECa) - gK*n*(V-EK) - gL*(V-EL) + Iapp ) ./ Cm;
    dn = phi * (Ninf - n) * cosh((V-V3)/(2*V4));

    % return result
    dY = [dV; dn];
end