% MorrisLecar1D A ring of Morris-Lecar neurons.
%
% Usage:
%   nn = 100;                      % Number of neurons
%   sys = MorrisLecar1D(nn);       % Construct the system structure
%   gui = bdGUI(sys);              % Open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2019)
%
% References
%   Morris and Lecar (1981) Voltage Oscillations in the Barnicle Giant Muscle Fiber. Biophys J, 35:193-213.
%   Lecar (2007) Morris-Lecar model. Scholarpedia, 2(10):1333.

% Copyright (C) 2019 Stewart Heitmann. All rights reserved.
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
function sys = MorrisLecar1D(N)
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Stimulus mask
    Imask = zeros(N,1);
    Imask(ceil(N/2)+[-1 0 1]) = 1;
    
    % Our ODE parameters (SNLC regime)
    sys.pardef = [
        struct('name','Cm',    'value',20,   'lim',[1 50])
        struct('name','G',     'value',10,   'lim',[0 20])
        struct('name','gCa',   'value',4,    'lim',[0 10])
        struct('name','gK',    'value',8,    'lim',[0 10])
        struct('name','gL',    'value',2,    'lim',[0 10])
        struct('name','ECa',   'value',120,  'lim',[0 200])
        struct('name','EK',    'value',-84,  'lim',[-100 0])
        struct('name','EL',    'value',-45,  'lim',[-100 0])
        struct('name','V1',    'value',-1.2, 'lim',[-50 50])
        struct('name','V2',    'value',18,   'lim',[-50 50])
        struct('name','V3',    'value',12,   'lim',[-50 50])
        struct('name','V4',    'value',17.4, 'lim',[-50 50])
        struct('name','Imask', 'value',Imask,'lim',[0 1])
        struct('name','Iamp',  'value',60,   'lim',[0 100])
        struct('name','Idur',  'value',1000, 'lim',[0 1000])
        struct('name','phi',   'value',0.067,'lim',[0 1])
        struct('name','dx',    'value',1,    'lim',[0.1 10])        
        ];

    % Our ODE variables        
    sys.vardef = [
        struct('name','V', 'value',-42*ones(N,1),  'lim',[-87 45])
        struct('name','n', 'value',zeros(N,1),     'lim',[-0.1 0.6])
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
        num2str(N,'A cable of $N{=}%g$ Morris-Lecar neurons');
        '\qquad $C_m \dot V = -g_{Ca} m_{\infty} (V-E_{Ca}) - g_K n (V-E_K) - g_L(V-E_L) + G\,\frac{\partial^2{V}}{\partial x^2} + I$'
        '\qquad $\tau \dot n = \phi (n_{\infty} - n)$'
        'where';
        '\qquad $V(x,t)$ is the membrane voltage,';
        '\qquad $n(x,t)$ is the potassium gating variable,';
        '\qquad $m_\infty(V) = 0.5 (1 + \tanh((V-V_1)/V_2))$ is the voltage-dependent calcium gate,';
        '\qquad $n_\infty(V) = 0.5 (1 + \tanh((V-V_3)/V_4))$ is the voltage-dependent potassium gate,';
        '\qquad $\tau(V) = 1 / \cosh((V-V_3)/(2V_4))$ is the time course of the potassium gate.';
        ''
        'Parameters';
        '\qquad $C_m$ is the membrane capacitance,';
        '\qquad $G$ is the conductance of the gap junction,';
        '\qquad $g_{Ca}$ is the maximal conductance of the calcium channel,';
        '\qquad $g_{K}$ is the maximal conductance of the potassium channel,';
        '\qquad $g_L$ is the leak conductance,';
        '\qquad $E_{Ca}$ is the reversal potential of the calcium channel,';
        '\qquad $E_{K}$ is the reversal potential of the potassium channel,';
        '\qquad $E_{L}$ is the reversal potential of the leak channel,';
        '\qquad $V_1,V_2,V_3,V4$ are parameters chosen to fit the voltage-clamp data,';
        '\qquad $I$ is an external current that is applied to the membrane,';
        '\qquad $\phi$ is the rate of the potassium channel.';
        '';
        'The stimulus is defined as';
        '\qquad $I(x,t) = I_{amp}(t) \times I_{mask}(x)$';
        'where'
        '\qquad $I_{mask}$ is the spatial profile of the stimulus,';
        '\qquad $I_{amp}$ is the amplitude of the stimulus,';
        '\qquad $I_{dur}$ is the duration of the stimulus.';
        '';
        'The spatial derivative is approximated by the second-order central';
        'central difference,';
        '\qquad $\partial^2 V / \partial x^2 \approx \big( V_{i-1} - 2V_{i} + V_{i+1} \big) / dx^2$,';
        'with periodic boundary conditions.';        
        '';
        'References:';
        '\quad Lecar (2007) Morris-Lecar model. Scholarpedia, 2(10):1333.';
        };
    
    % Display panels
    sys.panels.bdSpaceTime = [];
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function.
function [dY,Iapp] = odefun(t,Y,Cm,G,gCa,gK,gL,ECa,EK,EL,V1,V2,V3,V4,Imask,Iamp,Idur,phi,dx)  
    % extract incoming variables from Y
    Y = reshape(Y,[],2);
    V = Y(:,1);
    n = Y(:,2);

    % Spatial Derivative (periodic boundary conditions)
    Vl = circshift(V,-1);
    Vr = circshift(V,+1);
    Vxx = (Vl - 2*V + Vr) ./ dx^2;
    
    % Spatial Stimulus
    if (t>=0 && t<Idur)
        Iapp = Iamp*Imask;
    else
        Iapp = 0;
    end

    % Morris-Lecar equations
    Minf = 0.5*(1 + tanh((V-V1)./V2));
    Ninf = 0.5*(1 + tanh((V-V3)./V4));
    dV = ( -gCa*Minf.*(V-ECa) - gK*n.*(V-EK) - gL*(V-EL) + G*Vxx + Iapp ) ./ Cm;
    dn = phi * (Ninf - n) .* cosh((V-V3)./(2*V4));

    % return result
    dY = [dV; dn];
end