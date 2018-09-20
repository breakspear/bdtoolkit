% WilsonCowan Wilson-Cowan model of excitatory and inhibitory neural populations.
% The Wilson-Cowan equations describe the mean firing rates of reciprocally-
% coupled populations of excitatory and inhibitory neurons
%    E' = (-E + F(wee*E - wei*I - be + Je) )./taue;
%    I' = (-I + F(wie*E - wii*I - bi + Ji) )./taui;
% where
%    E is the mean firing rate of the excitatory cells and
%    I is the mean firing rate of the inhibitory cells
%    wei is the weight of the connection to E from I
%    be and bi are threshold constants
%    Je and Ji are injection currents
%    taue and taui are time constants
%    F(v)=1/(1+\exp(-v)) is a sigmoid function
%
% SYNTAX
%    sys = WilsonCowan();
%
% EXAMPLE
%    sys = WilsonCowan();
%    gui = bdGUI(sys);
%
% SEE ALSO
%    WilsonCowanNet
%    WilsonCowanRing
%
% AUTHOR
%   Stewart Heitmann (2018b)

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

function sys = WilsonCowan()

    % Handle to the ODE function
    sys.odefun = @odefun;
    
    % ODE parameters
    sys.pardef = [ struct('name','wee',  'value',11,   'lim',[0 30]);
                   struct('name','wei',  'value',10,   'lim',[0 30]);
                   struct('name','wie',  'value',10,   'lim',[0 30]);
                   struct('name','wii',  'value', 1,   'lim',[0 30]);
                   struct('name','be',   'value', 2.5, 'lim',[0 10]);
                   struct('name','bi',   'value', 3,   'lim',[0 10]);
                   struct('name','Je',   'value', 0,   'lim',[0 5]); 
                   struct('name','Ji',   'value', 0,   'lim',[0 5]);
                   struct('name','taue', 'value', 5,   'lim',[1 20]);
                   struct('name','taui', 'value',10,   'lim',[1 20])];
              
    % ODE variables
    sys.vardef = [ struct('name','E', 'value',rand, 'lim',[0 1]);
                   struct('name','I', 'value',rand, 'lim',[0 1])];
 
    % Default time span
    sys.tspan = [0 300];
    
    % Default ODE options
    sys.odeoption.RelTol = 1e-5;
    
    % Latex Panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{WilsonCowan}'
        ''
        'Describes the mean firing rates of reciprocally-coupled populations'
        'of excitatory and inhibitory neurons'
        ''
        '\qquad $\tau_e \; \dot E = -E + F\big(w_{ee} E - w_{ei} I - b_e + J_e\big)$'
        '\qquad $\tau_i \; \dot I \; = -I \; + F\big(w_{ie} E - w_{ii} I - b_i + J_i \big)$'
        ''
        'where'
        '\qquad $E(t)$ is the mean firing rate of the \textit{excitatory} population,'
        '\qquad $I(t)$ is the mean firing rate of the \textit{inhibitory} population,'
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoidal firing-rate function,'
        '\qquad $w_{ei}$ is the weight of the connection to $E$ from $I$,'
        '\qquad $b_{e}$ is the firing threshold for excitatory cells,'
        '\qquad $b_{i}$ is the firing threshold for inhibitory cells,'
        '\qquad $J_{e}$ is an external current injected into the excitatory cells,'
        '\qquad $J_{i}$ is an external current injected into the inhibitory cells,'
        '\qquad $\tau_{e}$ is the time constant of excitation,'
        '\qquad $\tau_{i}$ is the time constant of inhibition.'
        ''
        '\textbf{References}'
        'Wilson \& Cowan (1972) Biophysics Journal 12(1):1-24.'
        'Wilson \& Cowan (1973) Kybernetik 13(2):55-80.'
        'Kilpatrick (2013) Encyclopedia of Computational Neuroscience. Springer.'
        };
    
    % Other Panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdPhasePortrait = [];
    sys.panels.bdAuxiliary.auxfun = {@compound};
    sys.panels.bdSolverPanel = [];
end

% The Wilson-Cowan ODE function
function dY = odefun(~,Y,wee,wei,wie,wii,be,bi,Je,Ji,taue,taui)
    % extract incoming data from column vector Y
    E = Y(1);
    I = Y(2);
    
    % Wilson-Cowan Equations
    dE = (-E + F(wee*E - wei*I - be + Je) )./taue;
    dI = (-I + F(wie*E - wii*I - bi + Ji) )./taui;
    
    % return a column vector
    dY = [dE; dI];
end

% Sigmoidal firing-rate function
function y = F(x)
    y = 1./(1+exp(-x));
end

% Auxiliary plot of the compound firing rate (Local Field Potential)
function compound(ax,~,sol,wee,wei,wie,wii,be,bi,Je,Ji,taue,taui)
    % extract solution data
    t = sol.x;
    E = sol.y(1,:);
    I = sol.y(2,:);
    
    plot(t,E+I, 'k','Linewidth',2);
    plot(t,E, 'k-.');
    plot(t,I, 'k:');
    legend('E+I','E','I');
    xlim([t(1) t(end)]);
    ylim([0 2]);
    title('Compound Firing Rate')
    xlabel('time');
end