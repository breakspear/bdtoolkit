% Tsodyks1997 model of inhibition-stabilised neural dynamics.
% The equations follow the Wilson-Cowan (1972) model of reciprocally-
% coupled populations of excitatory and inhibitory neurons
%    taue E' = -E + G(Jee*E - Jei*I - theta + Se)
%    taui I' = -I + G(Jie*E - Jii*I - theta + Si)
% where
%    E is the mean firing rate of the excitatory cells and
%    I is the mean firing rate of the inhibitory cells
%    Jei is the weight of the connection to E from I
%    theta is the firing threshold constant
%    Se and Si are injection currents
%    taue and taui are time constants
% For analytical purposes, the model uses a linear response function
%    G(x) = beta * x
% with slope beta. The values of G(x) are capped between 0 and 1.
%
% EXAMPLE
%    sys = Tsodyks1997();
%    gui = bdGUI(sys);
%
% REFERENCES
%    Tsodyks, Skaggs, Sejnowski, McNaughton (1997) J Neurosci 17(11).
%    Wilson, Cowan (1972) Biophysics Journal 12(1)
%
% AUTHOR
%   Stewart Heitmann (2019a)

% Copyright (C) 2016-2019 QIMR Berghofer Medical Research Institute
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
function sys = Tsodyks1997()

    % Handle to the ODE function
    sys.odefun = @odefun;
    
    % ODE parameters
    sys.pardef = [ struct('name','Jee',  'value', 25,   'lim',[0 50]);
                   struct('name','Jei',  'value', 25,   'lim',[0 50]);
                   struct('name','Jie',  'value', 15,   'lim',[0 50]);
                   struct('name','Jii',  'value',  7,   'lim',[0 50]);
                   struct('name','beta', 'value',0.1,  'lim',[0.02 0.2]);
                   struct('name','theta','value',  0,   'lim',[0 5]);
                   struct('name','Se',   'value',  5,   'lim',[0 5]); 
                   struct('name','Si',   'value',  0,   'lim',[0 5]);
                   struct('name','taue', 'value', 10,   'lim',[1 20]);
                   struct('name','taui', 'value',  5,   'lim',[1 20])];
              
    % ODE variables
    sys.vardef = [ struct('name','E', 'value',rand, 'lim',[-0.2 1.2]);
                   struct('name','I', 'value',rand, 'lim',[-0.2 1.2])];
 
    % Default time span
    sys.tspan = [0 500];
    
    % Default ODE options
    sys.odeoption.RelTol = 1e-6;
    
    % Latex Panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Tsodyks, et al (1997) Paradoxical Effects of External Modulation}'
        '\textbf{of Inhibitory Interneurons}'
                
        ''
        'The equations follow the Wilson-Cowan (1972) model of reciprocally'
        'coupled populations of excitatory and inhibitory neurons'
        ''
        '\qquad $\tau_e \; \dot E = -E + G\big(J_{ee} E - J_{ei} I + S_e\big)$'
        '\qquad $\tau_i \; \dot I \; = -I \; + G\big(J_{ie} E - J_{ii} I + S_i \big)$'
        ''
        'where'
        '\qquad $E(t)$ is the mean firing rate of the \textit{excitatory} population,'
        '\qquad $I(t)$ is the mean firing rate of the \textit{inhibitory} population,'
        '\qquad $J_{ei}$ is the weight of the connection to $E$ from $I$,'
        '\qquad $S_{e}$ is an external current injected into the excitatory cells,'
        '\qquad $S_{i}$ is an external current injected into the inhibitory cells,'
        '\qquad $\tau_{e}$ is the time constant of excitation,'
        '\qquad $\tau_{i}$ is the time constant of inhibition.'
        ''
        'For analytical purposes, it uses a linear response function'
        '\qquad $G(x)=\beta(x-\theta)$'
        'with slope $\beta$ and firing threshold $\theta$ where the values of $G(x)$ are'
        'capped between 0 and 1.'
        ''
        ''
        '\textbf{Inhibition-Stabilized Regime}'
        'The inhibition-stabilized regime occurs when $\beta J_{ee}>1$. It exhibits a'
        'concomitant reduction in both E and I when the inhibitory cell is'
        'stimulated. The reduction of activity in the inhibitory cell under'
        'increased stimulation appears to be paradoxical.'
        ''
        '\textbf{References}'
        'Tsodyks, Skaggs, Sejnowski \& McNaughton (1997) J Neurosci 17(11).'
        'Wilson \& Cowan (1972) Biophysics Journal 12(1).'
        };
    
    % Other Panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdPhasePortrait.vecfield = true;
    sys.panels.bdPhasePortrait.nullclines = true;
    sys.panels.bdSolverPanel = [];
end

% Linear variant of the Wilson-Cowan equations.
% Equations (1-2) in Tsodyks, et al (1997). 
function dY = odefun(~,Y,Jee,Jei,Jie,Jii,beta,theta,Se,Si,taue,taui)
    % extract incoming data from column vector Y
    E = Y(1);
    I = Y(2);
        
    % Wilson-Cowan Equations where G(x) is threshold-linear.
    dE = (-E + G(Jee*E - Jei*I - theta + Se, beta) )./taue;
    dI = (-I + G(Jie*E - Jii*I - theta + Si, beta) )./taui;
    
    % return a column vector
    dY = [dE; dI];
end

% Threshold-linear Response Function.
% Equation (3) in Tsodyks, et al (1997).
function y = G(x,beta)
    y = beta.*x;
    y = max(y,0);
    y = min(y,1);
end
