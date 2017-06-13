% BTF2003DDE Time-delayed variant of  Breakspear, Terry and Friston (2003)
%   Modulation of excitatory synaptic coupling facilitates synchronization
%   and complex dynamics in a biophysical model of neuronal dynamics.
%   Network: Comput. Neural Syst., 14 (2003) 703-732  
%   PII: S0954-898X(03)55346-5
%
% Usage:
%   sys = BTF2003DDE(Kij)
%   where Kij is an (nxn) connectivity matrix in which the entry at row i
%   and column j is the weight of the connection from node i to node j.
%
% Example:
%   load cocomac242 MacCrtx     % Load a connectivity matrix. 
%   sys = BTF2003(MacCrtx);     % Construct the system struct.
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI.
%
% Authors
%   Michael Breakspear (2017b)
%   Stewart Heitmann (2017b)

% Copyright (C) 2017 QIMR Berghofer Medical Research Institute
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
function sys = BTF2003DDE(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);

    % Handle to our DDE function
    sys.ddefun = @ddefun;
    
    % System parameters from Table 1 of Breakspear, Terry & Friston (2003)
    sys.pardef = [
        % Connection Matrix (nxn) 
        struct('name','Kij',   'value',  Kij);            
                   
        % Connection weights [aee, aei, aie, ane, ani]
        struct('name','a',    'value', [0.4, 2.0, 2.0, 1.0, 0.4]);
        
        % Time constant of inhibition
        struct('name','b',    'value',  0.10);

        % Relative contribution of excitatory connection between versus within enembles
        struct('name','C',    'value',  0);

        % Relative contribution of NMDA versus AMPA receptors
        struct('name','r',    'value',  0.25); 

        % Temperature scaling factor                   
        struct('name','phi',  'value',  0.7);

        % Ion channel parameters
        struct('name','gion', 'value', [1.1, 2.0, 6.70, 0.5]);     % Ion Conductances [gCa, gK, gNa, gL]
        struct('name','Vion', 'value', [1.0,-0.7, 0.53,-0.5]);     % Nernst Potential [VCa, VK, VNa, VL]
                   
        % Gain parameters
        struct('name','thrsh', 'value', [ 0.0, 0.0,-0.01, 0.00, 0.30]);    % Firing threshold [VT, ZT, TCa, TK, TNa]
        struct('name','delta', 'value', [ 0.7, 0.7, 0.15, 0.30, 0.15]);    % Firing fun slope [deltaV, deltaZ, deltaCa, deltaK, deltaNa]

        % Strength of subcortical input
        struct('name','I',    'value', 0.3);
        ];
              
    % lag variables
    sys.lagdef = struct('name','d', 'value',1);   % the same lag is applied to all long-range connections
    
    % ODE state variables
    sys.vardef = [ struct('name','V', 'value',rand(n,1)./2.3 - 0.1670);    % Mean firing rate of excitatory cells
                   struct('name','W', 'value',rand(n,1)./2.6 + 0.27);      % Proportion of open K channels
                   struct('name','Z', 'value',rand(n,1)./10) ];            % Mean firing rate of inhibitory cells
               
    % Integration time span
    sys.tspan = [0 1000]; 
   
    % Specify DDE solvers and default options
    sys.ddesolver = {@dde23,@dde23hack};       % DDE solvers
    sys.ddeoption = ddeset('RelTol',1e-6);     % DDE solver options    

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Breakspear, Terry \& Friston (2003)} Network: Comput Neural Syst (14).';
        'Time-delayed variant of a neural network comprised of densely connected local ensembles of excitatory';
        'and inhibitory neurons with long-range excitatory coupling between ensembles. Transmission delays';
        'apply only to the long-range connections and all delays are identical.';
        '\qquad $\dot{V}^{(j)}(t) = -\Big(g_{Ca} + r\,a_{ee}\, K_{jj}\, Q_V^{(j)}(t) + r\,a_{ee}\, \sum_i K_{ij} Q_V^{(i)}(t{-}d) / k^{(j)} \Big)\,m_{Ca}^{(j)}(t)\,\big(V^{(j)}(t) {-} V_{Ca}\big)$';
        '\qquad \qquad \qquad $ - \, \Big(g_{Na}\,m_{Na}^{(j)}(t) + a_{ee}\,K_{jj}\,Q_V^{(j)}(t) + \,a_{ee}\, \sum_i K_{ij} Q_V^{(i)}(t{-}d) / k^{(j)} \Big)\,\big(V^{(j)}(t) {-} V_{Na}\big) $';
        '\qquad \qquad \qquad $ - \, g_K\,W^{(j)}(t)\,\big(V^{(j)}(t) {-} V_K\big) \, - \, g_L\,\big(V^{(j)}(t) {-} V_L\big) \, - \, a_{ie}\,Z^{(j)}(t)\,Q_Z^{(j)}(t) + a_{ne}\,I,$';
        '';
        '\qquad $\dot{W}^{(j)}(t) = \frac{\phi}{\tau}\,\big(m_K^{(j)}(t) {-} W^{(j)}(t)\big)$';
        '';
        '\qquad $\dot{Z}^{(j)}(t) = b\,\big(a_{ni}\,I + a_{ei}\,V^{(j)}(t)\,Q_V^{(j)}(t)\big)$';
        'where';
        '\qquad $V^{(j)}$ is the average membrane potential of \textit{excitatory} cells in the $j^{th}$ neural ensemble,';
        '\qquad $W^{(j)}$ is the proportion of open Potassium channels in the $j^{th}$ neural ensemble,';
        '\qquad $Z^{(j)}$ is the average membrane potential of \textit{inhibitory} cells in the $j^{th}$ neural ensemble,';
        '\qquad $m_{ion}^{(j)} = \frac{1}{2} \big(1 + \tanh((V^{(j)}{-}V_{ion})/\delta_{ion})\big)$ is the proportion of open ion channels for a given $V$,';
        '\qquad $Q_{V}^{(j)} = \frac{1}{2} \big(1 + \tanh((V^{(j)}{-}V_{T})/\delta_{V})\big)$ is the mean firing rate of \textit{excitatory} cells in the $j^{th}$ ensemble,';
        '\qquad $Q_{Z}^{(j)} = \frac{1}{2} \big(1 + \tanh((Z^{(j)}{-}Z_{T})/\delta_{Z})\big)$ is the mean firing rate of \textit{inhibitory} cells in the $j^{th}$ ensemble,';
        '\qquad $K_{ij}$ is the network connection weight from ensemble $i$ to ensemble $j$,';
        '\qquad $k^{(j)} = \sum_i K_{ij}$ for $i \neq j$ is the sum of incoming connection weights to ensemble $j$,';
        '\qquad a $= [a_{ee},a_{ei},a_{ie},a_{ne},a_{ni}]$ are the connection weights ($a_{ei}$ denotes \textit{excitatory-to-inhibitory}),';
        '\qquad $b$ is the time constant of inhibition,';
        '\qquad $d$ is the transmission delay between ensembles,';
        '\qquad $r$ is the number of NMDA receptors relative to the number of AMPA receptors,';
        '\qquad phi $=\frac{\phi}{\tau}$ is the temperature scaling factor,';
        '\qquad gion $= [g_{Ca},g_{K},g_{Na},g_L]$ are the ion conducances, Vion $= [V_{Ca},V_{K},V_{Na},V_L]$ are the Nernst potentials,';
        '\qquad thrsh $= [V_T,Z_T,T_{Ca},T_K,T_{Na}]$ are the gain thresholds, delta $= [\delta_V,\delta_Z,\delta_{Ca},\delta_K,\delta_{Na}]$ are the gain slopes,';
        '\qquad $I$ is the strength of the subcortical input.';
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Hilbert Transform panel in the GUI
    sys.panels.bdHilbert = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = []; 
    
    % Handle to the user-defined function that GUI calls to construct a new system. 
    sys.self = @self;
end

function dYdt = ddefun(~,Y,Ylag,Kij,a,b,C,r,phi,gion,Vion,thrsh,delta,I)  
    % Extract incoming values from Y
    Y = reshape(Y,[],3);        % reshape Y to 3 columns
    V = Y(:,1);                 % 1st column of Y contains vector V
    W = Y(:,2);                 % 2nd column of Y contains vector W    
    Z = Y(:,3);                 % 3rd column of Y contains vector Z
    
    % number of network nodes (neural ensembles)
    n = numel(V);
    
    % Extract incoming lag values from Ylag
    Vlag = Ylag(1:n);
    
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
    Qvlag = gain(Vlag, VT, deltaV); % (nx1) vector
    Qv = gain(V, VT, deltaV);       % (nx1) vector
    Qz = gain(Z, ZT, deltaZ);       % (nx1) vector

    % fraction of open channels
    mCa = gain(V, TCa, deltaCa);    % (nx1) vector
    mK  = gain(V, TK,  deltaK );    % (nx1) vector
    mNa = gain(V, TNa, deltaNa);    % (nx1) vector
    
    % Extract the diagonals from Kij
    Kii = Kij(1:(n+1):end)';        % (nx1) vector
    
    % Zero the diagonals in Kij
    Kij(1:(n+1):end) = 0;           % (nxn) matrix
    
    % mean firing rates (off-diagonals only)
    k = sum(Kij)';                  % (1xn) vector
    QvMean = ((Qvlag'*Kij)')./k;    % (1xn) vector
    QvMean(isnan(QvMean)) = 0;    

    % excitatory cell dynamics
    dV = -(gCa + r.*aee.*Kii.*Qv + r.*aee.*QvMean).*mCa.*(V-VCa) ...
         - gK.*W.*(V-VK) ...
         - gL.*(V-VL) ... 
         - (gNa.*mNa + aee.*Kii.*Qv + aee.*QvMean).*(V-VNa) ...
         + ane.*I ...
         - aie.*Qz.*Z;
     
    % K cell dynamics
    dW = phi.*(mK-W);
    
    % inhibitory cell dynamics
    dZ = b.*(ani.*I + aei.*Qv.*V);

    % return a column vector
    dYdt = [dV; dW; dZ]; 
end

% Non-linear gain function
function f = gain(VAR,C1,C2)
    f = 0.5*(1+tanh((VAR-C1)./C2));
end

% The self function is called by bdGUI to reconfigure the model
function sys = self()
    % Prompt the user to load Kij from file. 
    info = {mfilename,'','Load the connectivity matrix, Kij'};
    Kij = bdLoadMatrix(mfilename,info);
    if isempty(Kij) 
        % the user cancelled the operation
        sys = [];  
    else
        % pass Kij to our main function
        mainfunc = str2func(mfilename);
        sys = mainfunc(Kij);
    end
end
