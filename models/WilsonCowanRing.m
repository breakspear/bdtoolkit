% WilsonCowanRing A ring of Wilson-Cowan E-I neural populations.
% The Wilson-Cowan equations describe the mean firing rates of reciprocally
% coupled populations of excitatory and inhibitory neurons. Here we model a
% a ring of Wilson-Cowan neural populations that are non-locally coupled
% according to the user-defined coupling kernels Ke and Ki.
%
% The differential equations are
%    Ue' = (-Ue + F(wee*Ve - wei*Vi - be + Je) )./taue;
%    Ui' = (-Ui + F(wie*Ve - wii*Vi - bi + Ji) )./taui;
% where
%    Ue is the mean firing rate of the excitatory cells (nx1)
%    Ui is the mean firing rate of the inhibitory cells (nx1)
%    wei is the weight of the connection to E from I
%    Ve = conv1w(ke*Ke,Ue) is the convolution of Ue with Ke
%    Vi = conv1w(ki*Ki,Ui) is the convolution of Ui with Ki
%    Ke is the coupling kernel of the excitatory cells (kx1)
%    Ki is the coupling kernel of the inhibitory cells (kx1)
%    ke and ki are scaling constants
%    be and bi are threshold constants
%    Je and Ji are injection currents (either 1x1 scalars or nx1 vectors)
%    taue and taui are time constants
%    F(v)=1/(1+\exp(-v)) is a sigmoid function
%    n is the number of nodes in the ring
%    k in the number of nodes in the coupling kernel
%    conv1w(K,U) performs 1D convolution with periodic boundary conditions
%
% Usage:
%    sys = WilsonCowanRing(n,Ke,Ki)
%
% Example:
%   % Spatial domain
%   n = 100;                           % number of spatial steps
%   dx = 0.5;                          % length of each spatial step (mm)
% 
%   % Gaussian coupling kernels
%   gauss1d = @(x,sigma) exp(-x.^2/sigma^2)./(sigma*sqrt(pi));
%   sigmaE = 2;                        % spread of excitatory gaussian
%   sigmaI = 4;                        % spread of inhibitory gaussian
%   kernelx = -10:dx:10;               % spatial domain of kernel (mm)
%   Ke = gauss1d(kernelx,sigmaE)*dx;   % excitatory coupling kernel
%   Ki = gauss1d(kernelx,sigmaI)*dx;   % inhibitory coupling kernel
%
%   % Injection currents
%   Je = 0.7;
%   Ji = 0;
%
%   % Construct and run the model
%   sys = WilsonCowanRing(n,Ke,Ki,Je,Ji);
%   gui = bdGUI(sys)
%
% SEE ALSO:
%   WilsonCowan
%   WilsonCowanNet
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

function sys = WilsonCowanRing(n,Ke,Ki,Je,Ji)
    % Handle to the ODE function
    sys.odefun = @odefun;
    
    % Determine the best limits for Ke and Ki
    KeLim = bdPanel.RoundLim(min(Ke),max(Ke));
    KiLim = bdPanel.RoundLim(min(Ki),max(Ki));
    
    % ODE parameters
    sys.pardef = [ struct('name','wee',  'value',10,   'lim',[0 30]);
                   struct('name','wei',  'value',8.5,  'lim',[0 30]);
                   struct('name','wie',  'value',12,   'lim',[0 30]);
                   struct('name','wii',  'value', 3,   'lim',[0 30]);
                   struct('name','Ke',   'value', Ke,  'lim',KeLim);
                   struct('name','Ki',   'value', Ki,  'lim',KiLim);                   
                   struct('name','ke',   'value', 1,   'lim',[0 5]);
                   struct('name','ki',   'value', 1,   'lim',[0 5]);                   
                   struct('name','be',   'value', 2,   'lim',[0 10]);
                   struct('name','bi',   'value', 3,   'lim',[0 10]);
                   struct('name','Je',   'value', Je,   'lim',[0 5]); 
                   struct('name','Ji',   'value', Ji,   'lim',[0 5]);
                   struct('name','taue', 'value', 10,   'lim',[1 20]);
                   struct('name','taui', 'value', 30,   'lim',[1 20])];
              
    % ODE variables
    sys.vardef = [ struct('name','Ue', 'value',rand(n,1), 'lim',[0 1]);
                   struct('name','Ui', 'value',rand(n,1), 'lim',[0 1])];
 
    % Default time span
    sys.tspan = [0 1000];
    
    % Default ODE options
    sys.odeoption.RelTol = 1e-5;
    
    % Latex Panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{WilsonCowanRing}'
        ''
        'A ring of non-locally coupled Wilson-Cowan equations where the nodes of'
        'the ring represent local populations of excitatory and inhibitory neurons.'
        'The dynamical equations are defined as'
        ''
        '\qquad $\tau_e \; \dot U_e(x,t) = -U_e(x,t) + F\Big(w_{ee} V_e(x,t) - w_{ei} V_i(x,t) - b_e + J_e(x) \Big)$'
        '\qquad $\tau_i \; \dot U_i(x,t) \; = -U_i(x,t) \; + F\Big(w_{ie} V_e(x,t) - w_{ii} V_i(x,t) - b_i + J_i(x) \Big)$'
        ''
        'where the non-local coupling is defined by the spatial convolution'
        ''
        '\qquad $V(x,t) = k \int K(x) \; U(x,t) \; dx$'
        ''
        'where'
        '\qquad $U_e(x,t)$ is the firing rate of the \textit{excitatory} population at position $x$,'
        '\qquad $U_i(x,t)$ is the firing rate of the \textit{inhibitory} population at position $x$,'
        '\qquad $V_e(x,t)$ is the spatial sum of \textit{excitation} at position $x$,'
        '\qquad $V_i(x,t)$ is the spatial sum of \textit{inhibition} at position $x$,'
        '\qquad $w_{ei}$ is the weight of the connection to $e$ from $i$,'
        '\qquad $K_e(x)$ and $K_i(x)$ are spatial coupling kernels,'
        '\qquad $k_e$ and $k_i$ are scaling constants,'
        '\qquad $b_{e}$ and $b_{i}$ are threshold constants,'
        '\qquad $J_{e}(x)$ and $J_i(x)$ are spatially extended injection currents,'
        '\qquad $\tau_{e}$ and $\tau_{i}$ are time constants,'
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoidal firing-rate function,'
        ''
        '\textbf{References}'
        'Wilson \& Cowan (1973) Kybernetik 13(2):55-80.'
        'Rule, Stoffregen \& Ermentrout (2011) PLoS Computational Biology 7(9).'
        'Heitmann, Rule, Truccolo \& Ermentrout (2017) PLoS Computational Biology 13(1).'
        };
    
    % Other Panels
    sys.panels.bdSpaceTime = [];
    sys.panels.bdSolverPanel = [];
end

function dU = odefun(~,U,wee,wei,wie,wii,Ke,Ki,ke,ki,be,bi,Je,Ji,taue,taui)
    % extract incoming data
    n = numel(U)/2;
    Ue = U(1:n);
    Ui = U([1:n]+n);
    
    % compute spatial convolutions.
    Ve = conv1w(ke.*Ke,Ue);
    Vi = conv1w(ki.*Ki,Ui);

    % Wilson-Cowan dynamics
    dUe = (-Ue + F(wee*Ve - wei*Vi + Je - be) )./taue;
    dUi = (-Ui + F(wie*Ve - wii*Vi + Ji - bi) )./taui;
    
    % concatenate results
    dU = [dUe;dUi];
end

% Convolution in 1D using periodic (wrapped) boundary conditions.
% K is a (1 x k) matrix of kernel weights (odd k is best).
% X is a (1 x n) matrix of data values.
% Returns Y as a (1 x n) matrix.
function Y = conv1w(K,X)
    % get dimensions of incoming vectors
    n = numel(X);           % dimensions of X data
    k = numel(K);           % dimensions of kernel (odd is best)
    khalf = floor(k/2);     % half width f kernel
    
    % Tile the incoming matrix X to achieve periodic boundary conditions.
    % We do this by imagining the X data already happens to be tiled within
    % an infinite index space that extends beyond the bounds of the matrix.
    % We then define our region of interest within that imagined index space
    % and wrap the indexes back to the legal bounds of matrix X using mod.
    % The matrix data referenced by those wrapped indexes corresponds to a
    % tiled version of the original data. Moroever, the tiling repeats as
    % many times as necessary to fill the target matrix. So the algorithm 
    % still works even when the kernel K is many times larger than X.
    indx = mod(-khalf:n+khalf-1,n)+1;

    % Use standard conv to do the work
    % The conv function reverses the K indexes. I don't like the flipped
    % result so I correct by flipping K before passing it to conv2.
    % This makes no difference when the kernel is symmetric.
    Y = conv(X(indx),K(end:-1:1),'valid');
end

% Sigmoidal firing-rate function
function y = F(x)
    y = 1./(1+exp(-x));
end
