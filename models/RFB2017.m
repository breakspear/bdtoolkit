% RFB2017  Roberts, Friston & Breakspear (2017)
%   Clinical Applications of Stochastic Dynmics Models of the Brain,
%   Part I: A Primer.
%   Biological Psychiatry: Cognitive Neuroscience and Neuroimaging.
%
% Usage:
%   sys = RFB2017()
%
% Example:
%   sys = RFB2017();            % Construct the system struct.
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI.
%
% Authors
%   Stewart Heitmann (2017b,2018a)

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
function sys = RFB2017()
    % Handles to our SDE functions
    sys.sdeF = @sdeF;
    sys.sdeG = @sdeG;
    
    % SDE Parameters
    sys.pardef = [
        % Connection weights [aee, aei, aie, ane, ani]
        struct('name','a',    'value', [0.36, 2.0, 2.0, 1.0, 0.4]);
        
        % Time constant of inhibition
        struct('name','b',    'value',  0.10);

        % Relative contribution of NMDA versus AMPA receptors
        struct('name','r',    'value',  0.25); 

        % Temperature scaling factor                   
        struct('name','phi',  'value',  0.7);

        % Ion channel parameters
        struct('name','gion', 'value', [1.0, 2.0, 6.70, 0.5]);     % Ion Conductances [gCa, gK, gNa, gL]
        struct('name','Vion', 'value', [1.0,-0.7, 0.53,-0.5]);     % Nernst Potential [VCa, VK, VNa, VL]
                   
        % Gain parameters
        struct('name','thrsh', 'value', [ 0.00, 0.00,-0.01, 0.00, 0.30]);    % Firing threshold [VT, ZT, TCa, TK, TNa]
        struct('name','delta', 'value', [ 0.65, 0.65, 0.15, 0.30, 0.15]);    % Firing fun slope [deltaV, deltaZ, deltaCa, deltaK, deltaNa]

        % Strength of subcortical input
        struct('name','I',    'value', 0.3);
        
        % Noise volatility parameters
        struct('name','alpha', 'value', 0);
        struct('name','beta',  'value', 0);
        ];
               
    % SDE state variables
    sys.vardef = [ struct('name','V', 'value',-0.2);      % Mean firing rate of excitatory cells
                   struct('name','W', 'value', 0.3);      % Proportion of open K channels
                   struct('name','Z', 'value', 0.12) ];   % Mean firing rate of inhibitory cells
               
    % Integration time span
    sys.tspan = [0 2000]; 

    % SDE solver options
    sys.sdesolver = {@sdeEM};           % Euler-Murayama solvers
    sys.sdeoption.InitialStep = 0.1;    % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = 1;     % Number of Wiener noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Roberts, Friston \& Breakspear (2017)} Biol. Psychiatry: Cognitive Neuroscience \& Neuroimaging.';
        'Clinical Applications of Stochastic Dynamic Models of the Brain, Part 1: A Primer.';
        '\qquad $dV = \Big( -(g_{Ca} + r\,a_{ee}\, Q_V)\,m_{Ca}\,(V {-} V_{Ca}) \, - \, (g_{Na}\,m_{Na} + a_{ee}\,Q_V)\,(V {-} V_{Na}) $';
        '\qquad \qquad \qquad $ - \, g_K\,W\,(V {-} V_K) \, - \, g_L\,(V {-} V_L) \, - \, a_{ie}\,Z\,Q_Z + a_{ne}\,I \Big)\,dt \, + \, a_{ne}\,\big( \alpha + \beta\,V \big) \,d \xi,$';
        '';
        '\qquad $dW = \frac{\phi}{\tau}\,(m_K {-} W) \, dt$';
        '';
        '\qquad $dZ = b\,(a_{ni}\,I + a_{ei}\,V\,Q_V) \, dt$';
        'where';
        '\qquad $V(t)$ is the average membrane potential of \textit{excitatory} cells,';
        '\qquad $W(t)$ is the proportion of open Potassium channels,';
        '\qquad $Z(t)$ is the average membrane potential of \textit{inhibitory} cells,';
        '\qquad $d\xi(t)$ is a Wiener noise process,';
        '\qquad $m_{ion} = \frac{1}{2} \big(1 + \tanh((V{-}V_{ion})/\delta_{ion})\big)$ is the proportion of open ion channels for a given $V,$';
        '\qquad $Q_{V} = \frac{1}{2} \big(1 + \tanh((V{-}V_{T})/\delta_{V})\big)$ is the mean firing rate of \textit{excitatory} cells,';
        '\qquad $Q_{Z} = \frac{1}{2} \big(1 + \tanh((Z{-}Z_{T})/\delta_{Z})\big)$ is the mean firing rate of \textit{inhibitory} cells,';
        '\qquad a $= [a_{ee},a_{ei},a_{ie},a_{ne},a_{ni}]$ are the connection weights ($a_{ei}$ denotes $e$ to $i$),';
        '\qquad b is the time constant of inhibition,';
        '\qquad r is the number of NMDA receptors relative to the number of AMPA receptors,';
        '\qquad phi $=\frac{\phi}{\tau}$ is the temperature scaling factor,';
        '\qquad gion $= [g_{Ca},g_{K},g_{Na},g_L]$ are the ion conducances, Vion $= [V_{Ca},V_{K},V_{Na},V_L]$ are the Nernst potentials,';
        '\qquad thrsh $= [V_T,Z_T,T_{Ca},T_K,T_{Na}]$ are the gain thresholds, delta $= [\delta_V,\delta_Z,\delta_{Ca},\delta_K,\delta_{Na}]$ are the gain slopes,';
        '\qquad $I$ is the strength of the subcortical input,';
        '\qquad $\alpha$ is the volatility of the \textit{additive} noise,';
        '\qquad $\beta$ is the volatility of the \textit{multiplicative} noise,';
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = []; 
end

% The deterministic part of the model
%   dY = sdeF(t,Y,a,b,r,phi,gion,Vion,thrsh,delta,I,alpha,beta) 
% is based on the model of an isolated neural mass by Breakspear,
% Terry & Friston (2003) Network: Comp Neural Syst (14).
function dY = sdeF(~,Y,a,b,r,phi,gion,Vion,thrsh,delta,I,~,~)  
    % Extract incoming values from Y
    V = Y(1);
    W = Y(2);
    Z = Y(3);

    % Extract conductance parameters
    gCa = gion(1);
    gK  = gion(2);
    gNa = gion(3);
    gL  = gion(4);
    
    % Extract Nerst potentials
    VCa = Vion(1);
    VK  = Vion(2);
    VNa = Vion(3);
    VL  = Vion(4);
    
    % Extract Gain threshold parameters
    VT  = thrsh(1);
    ZT  = thrsh(2);
    TCa = thrsh(3);
    TK  = thrsh(4);
    TNa = thrsh(5);
    
    % Extract Gain slope parameters
    deltaV  = delta(1);
    deltaZ  = delta(2);
    deltaCa = delta(3);
    deltaK  = delta(4);
    deltaNa = delta(5);
    
    % extract connection weights
    aee = a(1);     % E to E synaptic strength
    aei = a(2);     % E to I synaptic strength
    aie = a(3);     % I to E synaptic strength
    ane = a(4);     % any to E synaptic strength
    ani = a(5);     % any to I synaptic strength
    
    % firing-rate functions
    Qv = gain(V, VT, deltaV);
    Qz = gain(Z, ZT, deltaZ);

    % fraction of open channels
    mCa = gain(V, TCa, deltaCa);
    mK  = gain(V, TK,  deltaK );
    mNa = gain(V, TNa, deltaNa);
    
    % excitatory cell dynamics
    dV = -(gCa + r*aee*Qv)*mCa*(V-VCa) ...
         - gK*W*(V-VK) ...
         - gL*(V-VL) ... 
         - (gNa*mNa + aee*Qv)*(V-VNa) ...
         + ane*I ...
         - aie*Qz*Z;
     
    % K cell dynamics
    dW = phi*(mK-W);
    
    % inhibitory cell dynamics
    dZ = b*(ani*I + aei*Qv*V);

    % return a column vector
    dY = [dV; dW; dZ]; 
end

% The stochastic part of the model
%   G = sdeG(t,Y,a,b,r,phi,gion,Vion,thrsh,delta,I,alpha,beta) 
% returns the (nxm) noise coefficients where n=3 is the number of state
% variables and m=1 is the number of noise sources. In this case
% noise is only applied to the first state variable (which is V).
function G = sdeG(~,Y,a,~,~,~,~,~,~,~,~,alpha,beta)
    V = Y(1);
    ane = a(4);                        % any-to-E connection weight
    G = [ane*(alpha+beta*V); 0; 0];    % noise coefficients (3x1)
end

% Non-linear gain function
function f = gain(VAR,C1,C2)
    f = 0.5*(1+tanh((VAR-C1)./C2));
end

