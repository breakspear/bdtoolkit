% EIE1D A cable of E-I-E neurons with Wilson-Cowan dynamics
% for the Brain Dynamics Toolbox (https://bdtoolbox.org)
%
% EXAMPLE:
%    addpath ~/bdtoolkit
%    n = 200;
%    sys = EIE1D(n)
%    gui = bdGUI(sys);
%
% AUTHOR
%   Stewart Heitmann (2018,2019)
%
% REFERENCES
%   Heitmann & Ermentrout (2020) Direction-selective motion discrimination
%      by traveling waves in visual cortex. PLOS Computational Biology.
%   Heitmann & Ermentrout (2016) Propagating Waves as a Cortical Mechanism
%      of Direction-Selectivity in V1 Motion Cells. Proc of BICT'15. New York.
%   http://modeldb.yale.edu/266770
function sys = EIE1D(n)
    % Handle to the ODE function
    sys.odefun = @odefun;
    
    % Model specific functions and data
    sys.UserData.conv1w = @conv1w;
    sys.UserData.gauss1d = @gauss1d;
    
    % ODE parameters
    sys.pardef = [
        struct('name','wee',    'value',12,         'lim',[0 30])       % weight to E from E
        struct('name','wei',    'value',10,         'lim',[0 30])       % weight to E from I
        struct('name','wie',    'value',10,         'lim',[0 30])       % weight to I from E
        struct('name','wii',    'value',1,          'lim',[0 30])       % weight to I from I
        struct('name','delta',  'value',0.02,       'lim',[-0.1 0.1])   % spatial offset of Ke
        struct('name','sigmaE', 'value',0.05,       'lim',[0.01 0.2])   % spatial spread of Ke
        struct('name','sigmaI', 'value',0.15,       'lim',[0.01 0.2])   % spatial spread of Ki   
        struct('name','r',      'value',0.4,        'lim',[0.4 0.6])    % spatial radius of Ke,Ki
        struct('name','be',     'value',1.75,       'lim',[0 10])       % firing threshold for E
        struct('name','bi',     'value',2.6,        'lim',[0 10])       % firing threshold for I
        struct('name','Smask',  'value',ones(n,1),  'lim',[0 1])        % stimulus spatial mask        
        struct('name','alpha',  'value',1,          'lim',[0 4])        % stimulus amplitude 
        struct('name','Fs',     'value',2.5,        'lim',[0 15])       % spatial frequency of stimulus
        struct('name','Ft',     'value',15,         'lim',[-40 40])     % temporal frequency of stimulus
        struct('name','taue',   'value',5,          'lim',[0.1 5])      % time constant of excitation
        struct('name','taui',   'value',10,         'lim',[0.1 5])      % time constant of inhibition
        struct('name','dx',     'value',0.01,       'lim',[0.01 0.1])   % spatial step size
        struct('name','bflag',  'value',1,          'lim',[0 1])        % boundary condition flag
        ];
              
    % ODE variables
    sys.vardef = [
        struct('name','Ue1', 'value',rand(n,1), 'lim',[0 1])        % E cells (layer 1)
        struct('name','Ui',  'value',rand(n,1), 'lim',[0 1])        % I cells (layer 2)
        struct('name','Ue2', 'value',rand(n,1), 'lim',[0 1])        % E cells (layer 3)
        ];
 
    % Default time span
    sys.tspan = [0 600];
    
    % Default ODE options
    sys.odeoption.RelTol = 1e-5;
    
    % Latex Panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{EIE1D}'
        ''
        num2str(n,'A cable of n=%d neural masses where each mass comprises two')
        'populations of excitatory cells ($U_{e1}$ and $U_{e2}$) and one population'
        'of inhibitory cells ($U_{i}$). The cell dynamics are based on the Wilson-'
        'Cowan model.  The lateral coupling profile is Gaussian with distance.'
        'The excitatory populations are connected to the inhibitory population'
        'but not to each other.'
        ''
        'The equations are,'
        '\qquad $\tau_e \; \dot U_{e1}(x,t) = -U_{e1}(x,t) + F\Big(w_{ee} V_{e1}(x,t) - w_{ei} V_i(x,t) - b_e + J(x) \Big)$'
        '\qquad $\tau_i \; \dot U_i(x,t) \;\; = -U_i(x,t) \; + F\Big(w_{ie} V_{e1}(x,t) + w_{ie} V_{e2}(x,t) - w_{ii} V_i(x,t) - b_i \Big)$'
        '\qquad $\tau_e \; \dot U_{e2}(x,t) = -U_{e2}(x,t) + F\Big(w_{ee} V_{e2}(x,t) - w_{ei} V_i(x,t) - b_e + J(x) \Big)$'
        'where'
        '\qquad $U(x,t)$ is the firing rate of the  given population at position $x$,'
        '\qquad $V(x,t) = \int K(x) \; U(x,t) \; dx$ is the spatial sum of activity near $x$,'
        '\qquad $w_{ei}$ is the weight of the connection to $e$ from $i$,'
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoidal firing-rate function,'
        '\qquad $b_{e}$ and $b_{i}$ are threshold constants,'
        '\qquad $\tau_{e}$ and $\tau_{i}$ are time constants,'
        '\qquad $dx$ is spatial step size.'
        ''
        'The spatial coupling kernel is,'
        '\qquad $K(x) = \exp(-x^2/\sigma^2) / (\sigma\sqrt\pi)$'
        'where'
        '\qquad $\sigma_e$ and $\sigma_i$ are the the spreads of $K_e(x)$ and $K_i(x)$,'
        '\qquad $\delta$ is a spatial shift applied to $K_e(x)$,'
        '\qquad $r$ is the radius of both kernel supports.'
        ''
        'The stimulus is a sinusoidal grating,'
        '\qquad $J(x) = 0.5 \; \alpha \; (\cos(2 \pi F_s x - 2 \pi F_t t)+1)$ '
        'where'
        '\qquad $\alpha$ is the stimulus amplitude,'
        '\qquad $F_s$ is the spatial frequency of the grating,'
        '\qquad $F_t$ is the temporal frequency of the grating.'
        ''
        'Boundary conditions are controlled by the $bflag$ parameter.'
        '\qquad $bflag=0$ for zero-padded boundaries.'
        '\qquad $bflag=1$ for periodic boundaries.'
        '\qquad $bflag=2$ for reflecting boundaries.'
        ''
        '\textbf{Reference}'
        'Heitmann \& Ermentrout. Propagating Waves as a Cortical Mechanism of'
        'Direction-Selectivity in V1 Motion Cells. First International Workshop on'
        'Computational Models of the Visual Cortex (CMVC 2015), New York.'
        };
    
    % Other Panels
    sys.panels.bdSpaceTime = [];
    sys.panels.bdAuxiliary.auxfun = {@KernelPlot, @KernelSpectrum, @StimulusPlot};
    sys.panels.bdSolverPanel = [];
end

% Our ODE function where
%   t = time (scalar)
%   U = [U11,..,U1n, U21,..,U2n, U31,..,U3n] are cell activation states.
%   wee,wei,wie,wii are the connection weights.
%   delta is the horizontal shift applied to kernel Ke.
%   sigmaE and sigmaI are the spreads of kernels Ke and Ki.
%   r is the radius of the kernel domain.
%   be and bi are threshold parameters of the sigmoid functions.
%   Smask is a spatial mask applied to the grating stimulus.
%   alpha is the amplitude of the grating stimulus.
%   Fs and Ft are the spatial and temporal frequencies of the grating.
%   taue and taui are the time constants of the E and I dynamics.
%   dx is the spatial step size.
%   bflag specifies the boundary conditions.
function dU = odefun(t,U,wee,wei,wie,wii,delta,sigmaE,sigmaI,r,be,bi,Smask,alpha,Fs,Ft,taue,taui,dx,bflag)
    % extract incoming data
    n = numel(U)/3;         % number of spatial cells
    Ue1 = U(1:n);           % excitatory cells 
    Ui  = U([1:n]+n);       % inhibitory cells
    Ue2 = U([1:n]+2*n);     % excitatory cells

    % construct the spatial kernels
    [Ke,Ki] = kernels(delta,sigmaE,sigmaI,r,dx);

    % compute the spatial convolutions
    switch bflag
        case 0
            % zero padded boundaries
            Ve1 = conv(Ue1,Ke(end:-1:1),'same');
            Vi  = conv(Ui,Ki(end:-1:1),'same');     
            Ve2 = conv(Ue2,Ke,'same');
        case 1
            % periodic boundaries
            Ve1 = conv1w(Ke,Ue1); 
            Vi  = conv1w(Ki,Ui);     
            Ve2 = conv1w(Ke(end:-1:1),Ue2);
        otherwise
            % reflecting boundaries
            Ve1 = conv1r(Ke,Ue1); 
            Vi  = conv1r(Ki,Ui);     
            Ve2 = conv1r(Ke(end:-1:1),Ue2);
    end

    % spatial stimulus
    J = Stimulus(t,Fs,Ft,n,dx,alpha,Smask);

    % Wilson-Cowan dynamics
    dUe1 = (-Ue1 + F(wee*Ve1 - wei*Vi + J - be) )./taue;
    dUi  = (-Ui  + F(wie*Ve1 - wii*Vi + wie*Ve2 - bi) )./taui;
    dUe2 = (-Ue2 + F(wee*Ve2 - wei*Vi + J - be) )./taue;
 
    % concatenate results
    dU = [dUe1; dUi; dUe2];
end

function [J,xdomain] = Stimulus(t,Fs,Ft,n,dx,alpha,Smask)
    % spatial domain
    xdomain = linspace(-0.5*(n-1)*dx,+0.5*(n-1)*dx,n)';

    % stimulus is a sinusoidal grating
    J = 0.5*alpha*(cos(2*pi*Fs*xdomain - 0.002*pi*Ft*t)+1) .* Smask;
end

function [Ke,Ki,Kx] = kernels(delta,sigmaE,sigmaI,r,dx)
    % construct the spatial kernels
    xx = 0:dx:r;
    Kx  = [-xx(end:-1:2) xx];
    Ke =  gauss1d(Kx-delta,sigmaE) * dx;      % axonal footprint of E cell
    Ki =  gauss1d(Kx,sigmaI) * dx;            % axonal footprint of I cell
end

function UserData = KernelPlot(ax,tt,sol,wee,wei,wie,wii,delta,sigmaE,sigmaI,r,be,bi,Smask,alpha,Fs,Ft,taue,taui,dx,bflag)
    [Ke,Ki,Kx] = kernels(delta,sigmaE,sigmaI,r,dx);
    plot(Kx,Ke,'g','LineWidth',3);
    plot(Kx(end:-1:1),Ke,'g','LineWidth',1);
    plot(Kx,Ki,'r','Linewidth',3);
    plot(Kx,Ke-Ki,'k--','Linewidth',1);
    xlim([Kx(1) Kx(end)]);
    xlabel('space');
    legend('Ke1','Ke2','Ki','Ke1 - Ki');
    title('Spatial Kernels');
    grid on
    
    % make the kernels accessible to the user's workspace 
    UserData.Kx = Kx;
    UserData.Ke = Ke;
    UserData.Ki = Ki;
end

function UserData = KernelSpectrum(ax,tt,sol,wee,wei,wie,wii,delta,sigmaE,sigmaI,r,be,bi,Smask,alpha,Fs,Ft,taue,taui,dx,bflag)
    [Ke,Ki,Kx] = kernels(delta,sigmaE,sigmaI,r,dx);
    [px,fx] = pspectrum(Ke-Ki,1/dx);
    plot(fx,px);
    xlabel('frequency (cycles/mm)');
    ylabel('power');
    title('Kernel Spectrum');
    grid on
    UserData.Kx = Kx;
    UserData.Ke = Ke;
    UserData.Ki = Ki;
    UserData.px = px;
    UserData.fx = fx;
end

function UserData = StimulusPlot(ax,tt,sol,wee,wei,wie,wii,delta,sigmaE,sigmaI,r,be,bi,Smask,alpha,Fs,Ft,taue,taui,dx,bflag)
    % number of spatial nodes 
    n = size(sol.y,1)/3; 
    
    % time domain
    tdomain = linspace(sol.x(1),sol.x(end),numel(sol.x));
    
    % recreate the space-time stimulus
    [J,xdomain] = Stimulus(tdomain,Fs,Ft,n,dx,alpha,Smask);

    % plot the stimulus
    imagesc(tdomain,xdomain,J);
    ylabel('space');
    xlabel('time');
    colorbar;
    axis tight;
    title('Stimulus Grating');
    
    % return stimulus data to user workspace
    UserData.xdomain = xdomain;
    UserData.tdomain = tdomain;
    UserData.J = J;
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

% Convolution in 1D using reflecting boundary conditions.
% K is a (1 x k) matrix of kernel weights (odd k is best).
% X is a (1 x n) matrix of data values.
% Returns Y as a (1 x n) matrix.
function Y = conv1r(K,X)
    % get dimensions of incoming vectors
    n = numel(X);           % dimensions of X data
    k = numel(K);           % dimensions of kernel (odd is best)
    khalf = floor(k/2);     % half width of kernel
    
    % Tile the incoming matrix X with indexes that achieve reflected boundary conditions.
    % For example, if n=5 then we want .... 3 4 5 4 3 2 [ 1 2 3 4 5 ] 4 3 2 1 2 3 ...
    indx = mod(-khalf:n+khalf-1, 2*n-2) + 1;    % 1 2 3 4 5 6 7 8 | 1 2 3 4 5 6 7 8 | 1 2 3
    ii = indx>n;                                % 0 0 0 0 0 1 1 1 | 0 0 0 0 0 1 1 1 | 0 0 0
    indx(ii) = 2*n - indx(ii);                  % 1 2 3 4 5 4 3 2 | 1 2 3 4 5 4 3 2 | 1 2 3
    
    % Use standard conv to do the work
    % The conv function reverses the K indexes. I don't like the flipped
    % result so I correct by flipping K before passing it to conv.
    % This makes no difference when the kernel is symmetric.
    Y = conv(X(indx),K(end:-1:1),'valid');
end

% Sigmoidal firing-rate function
function y = F(x)
    y = 1./(1+exp(-x));
end

% Gaussian spread function
function y = gauss1d(x,sigma)
    y = exp(-x.^2/sigma^2)./(sigma*sqrt(pi));
end


