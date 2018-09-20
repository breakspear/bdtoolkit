% BOLDHRF BOLD Haemodynamic Response Function
% sys = BOLDHRF()
%   
% Example:
% See Chapter 5 of the Handbook for the Brain Dynamics Toolbox (2018b)
% for a description of the BOLD haemodynamic model.
%
% Authors
%   Stewart Heitmann (2018b)

% Copyright (C) 2018 QIMR Berghofer Medical Research Institute
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
function sys = BOLDHRF()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','V0',    'value',0.02,   'lim',[0 1]);
        struct('name','E0',    'value',0.34,   'lim',[0.01 1]);
        struct('name','tau0',  'value',0.98,   'lim',[0.01 2]);
        struct('name','tau1',  'value',1.00,   'lim',[0.01 2]);
        struct('name','alpha', 'value',0.33,   'lim',[0.01 1]);
        struct('name','kappa', 'value',0.65,   'lim',[0 1]);
        struct('name','gamma', 'value',0.41,   'lim',[0 1]);
        struct('name','Z',     'value',1.00,   'lim',[0 2]);
        struct('name','ton',   'value',0,      'lim',[0 1]);
        struct('name','toff',  'value',1,      'lim',[0 1]);
        ];
                   
    % Our ODE variables
    sys.vardef = [
        struct('name','v', 'value',1, 'lim',[0.9 1.4]);
        struct('name','q', 'value',1, 'lim',[0.7 1.1])
        struct('name','f', 'value',1, 'lim',[0.8 1.9]);
        struct('name','s', 'value',0, 'lim',[-0.3 0.8]);
        ];

    % Default time span
    sys.tspan = [0 30];
              
    % ODE solvers options
    sys.odeoption = odeset('RelTol',1e-6);

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{BOLDHRF}';
        '';
        'The haemodynamic model of the fMRI BOLD response is';
        '\qquad $y(t) = V_0 \; ( k_1\;(1-q) + k_2\;(1-q/v) + k_3\;(1-v))$';
        'where';
        '\qquad $v(t)$ is the normalised volume of blood';
        '\qquad $q(t)$ is the normalised deoxyhaemoglobin content';
        '\qquad $V_0 \approx 0.02$ is the resting blood volume';
        '\qquad $k_1 = 7 E_0$';
        '\qquad $k_2 = 2$';
        '\qquad $k_3 = 2 E_0 - 0.2$';
        '\qquad $E_0 \approx 0.34$ is the resting oxygen extraction fraction';
        '';
        'The changes in blood volume and deoxyhaemoglobin are governed';
        'by the net inflow and outflow of blood acording to the equations,';
        '\qquad $\tau_0 \; \dot v = f_{in} - f_{out}$';
        '\qquad $\tau_0 \; \dot q = f_{in} \, E(f_{in})/E_0 - f_{out} \, q/v$';
        'where $\tau_0 \approx 0.98$ seconds and $E(f)=1-(1{-}E_0)^{1/f}$.';
        '';
        '\textbf{Blood outflow}';
        'The rate of blood outflow depends on the volume of blood,';
        '\qquad $f_{out}(v) = v^{1/\alpha}$';       
        'where $\alpha \approx 0.33$ is the stiffness of the venous balloon.';
        '';
        '\textbf{Blood inflow}';
        'The inflow of blood changes in response to an unspecified';
        'vasodilatory signal that is mediated by neural activity,';
        '\qquad $\tau_1 \dot f = s$';       
        '\qquad $\tau_1 \dot s = u(t) - \kappa s - \gamma\; (f-1)$';
        'where';
        '\qquad $s(t)$ is the vasodilatory signal';
        '\qquad $u(t)$ is the neural activity in the voxel';
        '\qquad $\kappa \approx 0.65$ represents the decay rate of $s(t)$';
        '\qquad $\gamma \approx 0.41$ represents autoregulatory feedback for $s(t)$';
        '';
        '\textbf{Neuronal activity}';
        'The neuronal activity in this simulation is a square pulse, ';
        '\qquad $u(t) = Z$ when $t_{on} \leq t < t_{off}$';
        '\qquad $u(t) = 0$ otherwise.';
        'The response to the pulse can be used to create a convolution kernel.';
        '';
        '\textbf{Further Reading}';
        'A complete description of the haemodynamic model is included';
        'in the Handbook for the Brain Dynamics Toolbox (2018b).';
        };
    
    % Display Panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdAuxiliary.auxfun = {@BOLD,@NeuralActivity};
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function for the Haemodynamic model of BOLD response
function dY = odefun(t,Y,V0,E0,tau0,tau1,alpha,kappa,gamma,Z,ton,toff)  
    % extract incoming variables from Y
    v = Y(1);                   % blood volume
    q = Y(2);                   % deoxyhaemoglobin
    f = Y(3);                   % blood flow
    s = Y(4);                   % vasodilatory signal
    
    % force negative blood volume, blood inflow and deoxyhaemoglobin to zero
    v = max(v,0);
    q = max(q,0);
    f = max(f,0);
    
    % neuronal activity is a pulse
    if (ton<=t && t<toff) 
        u = Z;
    else
        u = 0;
    end    
    
    % differential equations
    dv = (f - v.^(1/alpha)) / tau0;
    dq = (f*(1-(1-E0).^(1/f))/E0 - v^((1-alpha)/alpha)*q ) / tau0;
    df = s / tau1;
    ds = (u - kappa*s - gamma*(f-1)) / tau1;

    % return result
    dY = [dv; dq; df; ds];
end

% Auxiliary function for plotting the BOLD response 
function UserData = BOLD(ax,t,sol,V0,E0,tau0,tau1,alpha,kappa,gamma,Z,ton,toff)
    % extract solution
    v = sol.y(1,:);                   % blood volume
    q = sol.y(2,:);                   % deoxyhaemoglobin
    
    % compute the BOLD signal
    k1 = 7*E0;
    k2 = 2;
    k3 = 2*E0 - 0.2;
    y = V0*(k1*(1-q) + k2*(1-q./v) + k3*(1-v));
    t = sol.x;
    
    % plot the BOLD signal
    plot(t, 100*y, 'color','k', 'LineWidth',1);
    ylabel('BOLD (%)');
    xlabel('time');
    title('BOLD Haemodynamic Response');
    
    % make the data accessible to the workspace
    UserData.t = t;
    UserData.y = y;
end

% Auxiliary function for plotting the profile of the neural activity 
function UserData = NeuralActivity(ax,t,sol,V0,E0,tau0,tau1,alpha,kappa,gamma,Z,ton,toff)
    % time steps of the solution
    t = sol.x;

    % reconstruct the neural activity profile
    u = zeros(size(t));
    tindx = (ton<=t & t<toff);
    u(tindx) = Z;
    
    stairs(t, u, 'color','k', 'LineWidth',1);
    ylabel('u(t)');
    xlabel('time');
    title('Neural Activity Pulse');
    
    % make the data accessible to the workspace
    UserData.t = t;
    UserData.u = u;
end
