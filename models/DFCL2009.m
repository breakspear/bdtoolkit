% DFCL2009 Neural-mass model by Dafilis, Frascoli, Cadusch and Liley (2009)
% Constructs a system definition for the Liley model as described in
% Dafilis, Frascoli, Caduschm Liley (2009) Chaos and generalised multi-
% stability in a mesoscopic model of the electroencephalogram. Physica D
% Vol 238 p1056-1060.
%
% Example:
%   sys = DFCL2009();         % Construct the system struct
%   gui = bdGUI(sys);         % Open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2017c,2018a)

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
function sys = DFCL2009()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [ struct('name','pee',   'value',9.43);
                   struct('name','pie',   'value',0);
                   struct('name','pei',   'value',8.742);
                   struct('name','pii',   'value',0);
                   struct('name','abAB',  'value',[1/0.99 1/7.06 1.22 3.6]);   % [a b A B]
                   struct('name','Nqq',   'value',[3034 536 3034 536]);   % [Nee Nie Nei Nii]
                   struct('name','hr',    'value',[-70 -70]);   % [her hir]
                   struct('name','heq',   'value',[45 -90]);    % [heeq hieq]
                   struct('name','Smax',  'value',[0.5 0.5]);   % [Semax Simax]
                   struct('name','theta', 'value',[-49 -41]);   % [thetae thetai]
                   struct('name','s',     'value',[4.75 5.25]); % [se si]
                   struct('name','tau',   'value',[98 34]);     % [taue taui]
                 ];
                   
    % Our ODE variables
    sys.vardef = [ struct('name','he',  'value',-78+13*rand);
                   struct('name','hi',  'value',-90+35*rand);
                   struct('name','Iqq', 'value',rand(4,1));
                   struct('name','Jqq', 'value',rand(4,1));
                 ];

    % Default time span
    sys.tspan = [-100 1000];
              
    % Specify ODE solvers and default options
    sys.odesolver = {@ode45,@ode23,@ode113};            % ODE solvers
    sys.odeoption = odeset('RelTol',1e-6);              % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{DFCL2009}';
        '';
        'Neural-mass model of the electroencephalogram (EEG) described in';
        'Dafilis, Frascoli, Cadush, Liley (2009) Physica D 238:1056-1060.';
        '';
        'It models the mass neural activity of a single cortical macro-column driven by the thalamus';
        '\qquad $\tau_e \dot h_e    = (h_{er}-h_e)   + \frac{h_{eeq}-h_e}{|h_{eeq}-h_{er}|} I_{ee}    + \frac{h_{ieq}-h_e}{|h_{ieq}-h_{er}|} I_{ie} $';
        '\qquad $\tau_i \dot h_i \, = (h_{ir}-h_i)\, + \frac{h_{eeq}-h_i}{|h_{eeq}-h_{ir}|} I_{ei} \, + \frac{h_{ieq}-h_i}{|h_{ieq}-h_{ir}|} I_{ii} $';
        '\qquad $\dot I_{ee}    = J_{ee}$';
        '\qquad $\dot I_{ie} \, = J_{ie}$';
        '\qquad $\dot I_{ei} \, = J_{ei}$';
        '\qquad $\dot I_{ii} \; = J_{ii}$';
        '\qquad $\dot J_{ee}    = -2a J_{ee}    - a^2 I_{ee}    + A a e \, \big(N_{ee} S_e(h_e)    + p_{ee}\big)$';
        '\qquad $\dot J_{ie} \, = -2b J_{ie} \, - b^2 I_{ie} \, + B b e \, \big(N_{ie} S_i(h_i) \; + p_{ie}\big)$';
        '\qquad $\dot J_{ei} \, = -2a J_{ei}    - a^2 I_{ei} \, + A a e \, \big(N_{ei} S_e(h_e)    + p_{ei}\big)$';
        '\qquad $\dot J_{ii} \; = -2b J_{ii} \, - b^2 I_{ii} \; + B b e \, \big(N_{ii} S_i(h_i) \; + p_{ii}\big)$';
        'where';
        '\qquad $S(h) = \frac{S^{max}}{1 + \exp(-\sqrt{2}(h - \theta)/s)}$ is a sigmoidal activation function,';
        '\qquad $h_e(t)$ and $h_i(t)$ are the mean somatic potentials of the \textit{excitatory} and \textit{inhibitory} neural populations,';
        '\qquad $I_{ei}(t)$ is the mean synaptic current from the \textit{excitatory} to the \textit{inhibitory} population,';
        '\qquad $J_{ei}(t)$ is the instantaneous rate of change of the synaptic current $I_{ei}(t)$,';
        '\qquad $\tau_e$ and $\tau_i$ are the time constants of \textit{excitation} and \textit{inhibition},';
        '\qquad $h_{er}$ and $h_{ir}$ are the resting potentials of \textit{excitatory} and \textit{inhibitory} membranes,';
        '\qquad $h_{eeq}$ and $h_{ieq}$ are the ionic reversal potentials for \textit{excitatory} and \textit{inhibitory} membranes,';
        '\qquad $1/a$ and $1/b$ are the rise times of the \textit{excitatory} and \textit{inhibitory} post-synaptic potentials (PSPs),';
        '\qquad $A$ and $B$ are the (average) peak amplitudes of the \textit{excitatory} and \textit{inhibitory} PSPs,';
        '\qquad $N_{ei}$ is the (average) number of synapses from \textit{excitatory} cells to \textit{inhibitory} cells,';
        '\qquad $p_{ei}$ is the exogenous input from \textit{excitatory} thalamic cells to \textit{inhibitory} cortical cells.';
        '';
        'The parameters of the model are grouped into the following control vectors for brevity';
        '\qquad abAB = $[a,b,A,B]$,';
        '\qquad Nqq = $[N_{ee},N_{ie},N_{ei},N_{ii}]$,';
        '\qquad hr = $[h_{er},h_{ir}]$,';
        '\qquad heq = $[h_{eeq},h_{ieq}]$,';
        '\qquad Smax = $[S_{e}^{max},S_{i}^{max}]$,';
        '\qquad theta = $[\theta_{e},\theta_{i}]$,';
        '\qquad s = $[s_{e},s_{i}]$,';
        '\qquad tau = $[\tau_{e},\tau_{i}]$,';
        '';
        'The dynamic variables $I(t)$ and $J(t)$ are likewise grouped into vectors';
        '\qquad Iqq = $[I_{ee}, I_{ie}, I_{ei}, I_{ii}]$,';
        '\qquad Jqq = $[J_{ee}, J_{ie}, J_{ei}, J_{ii}]$,';
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function. 
% See Dhamala, Jirsa and Ding (2004) Phys Rev Lett.
function dY = odefun(t,Y,pee,pie,pei,pii,abAB,Nqq,hr,heq,Smax,theta,s,tau) 
    % constants
    e = exp(1);
    sqrt2 = sqrt(2);
    
    % extract incoming variables from vector Y
    he  = Y(1); 
    hi  = Y(2);
    Iee = Y(3);
    Iie = Y(4);
    Iei = Y(5);
    Iii = Y(6);
    Jee = Y(7);
    Jie = Y(8);
    Jei = Y(9);
    Jii = Y(10);
    
    % extract the parameters from vector abAB
    a = abAB(1);
    b = abAB(2);
    A = abAB(3);
    B = abAB(4);
    
    % extract the parameters from vector Nqq
    Nee = Nqq(1);
    Nie = Nqq(2);
    Nei = Nqq(3);
    Nii = Nqq(4);

    % extract the parameters from vector hr
    her = hr(1);
    hir = hr(2);

    % extract the parameters from vector heq
    heeq = heq(1);
    hieq = heq(2);

    % extract the parameters from vector tau
    taue = tau(1);
    taui = tau(2);
    
    % sigmoid function
    Semax = Smax(1);
    Simax = Smax(2);
    the = theta(1);
    thi = theta(2);
    se = s(1);
    si = s(2);
    She = Semax ./ (1+exp(-sqrt2*(he-the)/se));
    Shi = Simax ./ (1+exp(-sqrt2*(hi-thi)/si));

    % ordinary differential equations
    dhe = (her-he) + (heeq-he)/abs(heeq-her)*Iee + (hieq-he)/abs(hieq-her)*Iie;
    dhi = (hir-hi) + (heeq-hi)/abs(heeq-hir)*Iei + (hieq-hi)/abs(hieq-hir)*Iii;
    dIee = Jee;
    dIie = Jie;
    dIei = Jei;
    dIii = Jii;
    dJee = -2*a*Jee - a^2*Iee + A*a*e*(Nee*She + pee);
    dJie = -2*b*Jie - b^2*Iie + B*b*e*(Nie*Shi + pie);
    dJei = -2*a*Jei - a^2*Iei + A*a*e*(Nei*She + pei);
    dJii = -2*b*Jii - b^2*Iii + B*b*e*(Nii*Shi + pii);
    
    % return vector dY
    dY = [dhe/taue; dhi/taui; dIee; dIie; dIei; dIii; dJee; dJie; dJei; dJii];
end
