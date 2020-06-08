function sys = Othmer1997()
    % Othmer1997 Four-state model of intracellular calcium dynamics
    %
    % Brain Dynamics Toolbox model of the signaling response of intra-
    % cellular calcium to the hormone-mediated secondary messenger InsP3.
    %
    % Example:
    %   sys = Othmer1997();     % construct the model
    %   gui = bdGUI(sys);       % open the Brain Dynamics GUI
    %
    % Authors
    %   The original equations were published by Othmer and Tang (1993)
    %   'Oscillations and waves in a model of InsP3-controlled calcium
    %   dynamics' in Exp Theor Adv Biol Pattern Form. This implementation
    %   for the Brain Dynamics Toolbox (bdtoolbox.org) was written by
    %   Stewart Heitmann.
    % 
    % Copyright (C) 2020 Stewart Heitmann <heitmann@bdtoolbox.org>
    % All rights reserved.

    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE parameter definitions
    sys.pardef = [
        struct('name','I',      'value', 0.5,    'lim',[0 2])
        struct('name','Idur',   'value', 2,      'lim',[0 100])
        struct('name','k1',     'value', 12.0,   'lim',[0 20])
        struct('name','k2bar',  'value', 15.0,   'lim',[0 20])
        struct('name','k3bar',  'value',  1.8,   'lim',[0 5])
        struct('name','k1rev',  'value',  8.0,   'lim',[0 10])
        struct('name','k2rev',  'value',  1.65,  'lim',[0 2])
        struct('name','k3rev',  'value',  0.21,  'lim',[0 1])
        struct('name','gamma0', 'value',  0.1,   'lim',[0 1])
        struct('name','gamma1', 'value', 20.5,   'lim',[0 30])
        struct('name','p1bar',  'value', 8.5,    'lim',[0 10])
        struct('name','p2bar',  'value', 0.065,  'lim',[0 0.1])
        struct('name','vr',     'value', 0.185,  'lim',[0 0.5])
        struct('name','C0',     'value', 1.56,   'lim',[0 5])
        ];
    
    % ODE variable definitions
    sys.vardef = [
        struct('name','x1', 'value',0.016, 'lim',[0 1])
        struct('name','x2', 'value',2.17,  'lim',[0 1])
        struct('name','x3', 'value',0,     'lim',[0 1])
        struct('name','x4', 'value',0,     'lim',[0 2])
        struct('name','x5', 'value',0,     'lim',[0 3])
        ];

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = { 
        '\textbf{Othmer1997}';
        '';
        'Four-state model of InsP3-induced calcium secondary messenger dynamics';
        ''
        '\qquad $I + R \rightleftharpoons RI$'
        '\qquad $RI + C \rightleftharpoons RIC^+$'
        '\qquad $RIC^+ + C \rightleftharpoons RIC^+C^-$'
        'where'
        '\qquad $R$ is the bare receptor'
        '\qquad $I$ is the InsP3 messenger (stimulus)'
        '\qquad $C$ is the calcium concentration'
        '\qquad $RI$ is the receptor-InsP3 complex'
        '\qquad $RIC^+$ is RI with calcium bound at the activating site'
        '\qquad $RIC^+C^-$ is RI with calcium bound at the activating and inhibitory sites.'
        ''
        'The dynamical equations are defined as,'
        '\qquad $\dot x_1 = \lambda (\gamma_0 + \gamma_1 x_4)(1-x_1) - p_1 x_1^4 / (p_2^4 + x_1^4)$'
        '\qquad $\dot x_2 = -k_1 I x_2 + k_{-1} x+3$'
        '\qquad $\dot x_3 = -(k_{-1} + \bar{k_2} x_1) x_3 + k_1 I x_2 + k_{-2} x_4$'
        '\qquad $\dot x_4 = k_2 x_1 x_3 + \bar{k_{-3}} x_5 - (\bar{k_{-2}} + k_3 x_1) x_4$'
        '\qquad $\dot x_5 = \bar{k_3} x_1 x_4 - k_{-3} x_5$'
        'where'
        '\qquad $x_1$ is the concentration of intracellular calcium (normalized to $C_0)$'
        '\qquad $x_2$ is the fraction of chemical complexes in state R'
        '\qquad $x_3$ is the fraction of chemical complexes in state RI'
        '\qquad $x_4$ is the fraction of chemical complexes in state RIC+'
        '\qquad $x_5$ is the fraction of chemical complexes in state RIC+C-'
        ''
        '\textbf{References}'
        'Othmer and Tang (1993) Oscillations and waves in a model of InsP3-'
        '\qquad controlled calcium dynamics. Exp Theor Adv Biol Pattern Form.'
        'Othmer (1997) Signal transduction and second messenger systems.'
        '\qquad In Case Studies in Mathematical Modeling. Prentice Hall.'
        };

    % Time Portrait panel 
    sys.panels.bdTimePortrait = [];

    % Phase Portrait panel
    sys.panels.bdPhasePortrait = [];
  
    % Solver panel
    sys.panels.bdSolverPanel = [];
    
    % Default time span (optional)
    sys.tspan = [-5 50]; 

    % ODE solver options
    sys.odeoption.RelTol = 1e-6;        % Relative Tolerance
    sys.odeoption.InitialStep = 0.01;   % Required by Euler method
    sys.odeoption.MaxStep = 1;
end

% The ODE function.
function dY = odefun(t,Y,I,Idur,k1,k2bar,k3bar,k1rev,k2rev,k3rev,gamma0,gamma1,p1bar,p2bar,vr,C0)
    % incoming state variables 
    x1 = Y(1);
    x2 = Y(2);
    x3 = Y(3);
    x4 = Y(4);
    x5 = Y(5);
    
    % intermediate expressions
    lambda = 1 + vr;
    k2 = k2bar * C0;
    k3 = k3bar * C0;
    p1 = p1bar / C0;
    p2 = p2bar / C0;
    
    % stimulus pulse
    if t<0 || t>Idur
        I = 0;
    end
    
    % calcium pump current
    gC = p1 * x1^4 ./ (p2^4 + x1^4);
    
    dx1 = lambda * (gamma0 + gamma1 * x4) * (1 - x1) - gC;
    dx2 = -k1 * I * x2 + k1rev * x3;
    dx3 = -(k1rev + k2 * x1)*x3 + k1 * I * x2 + k2rev * x4;
    dx4 = k2 * x1 * x3 + k3rev * x5 - (k2rev + k3 * x1)*x4;
    dx5 = k3 * x1 * x4 - k3rev * x5;
    
    % return result
    dY = [dx1; dx2; dx3; dx4; dx5];
end
