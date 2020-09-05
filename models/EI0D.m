% EI0D Point model of E-I cells with Wilson-Cowan dynamics 
% for the Brain Dynamics Toolbox (https://bdtoolbox.org)
%
% EXAMPLE:
%    addpath ~/bdtoolkit
%    sys = EI0D();
%    gui = bdGUI(sys);
%
% AUTHOR
%   Stewart Heitmann (2018,2019,2020)
%
% REFERENCES
%   Heitmann & Ermentrout (2020) Direction-selective motion discrimination
%      by traveling waves in visual cortex. PLOS Computational Biology.
%   Heitmann & Ermentrout (2016) Propagating Waves as a Cortical Mechanism
%      of Direction-Selectivity in V1 Motion Cells. Proc of BICT'15. New York.
%   http://modeldb.yale.edu/266770
function sys = EI0D()
    % Handle to the ODE function
    sys.odefun = @odefun;
    
    % ODE parameters
    sys.pardef = [
        struct('name','wee',    'value',12,         'lim',[0 30])       % weight to E from E
        struct('name','wei',    'value',10,         'lim',[0 30])       % weight to E from I
        struct('name','wie',    'value',10,         'lim',[0 30])       % weight to I from E
        struct('name','wii',    'value',1,          'lim',[0 30])       % weight to I from I
        struct('name','be',     'value',1.75,       'lim',[0 10])       % firing threshold for E
        struct('name','bi',     'value',2.6,        'lim',[0 10])       % firing threshold for I
        struct('name','alpha',  'value',1,          'lim',[0 4])        % stimulus amplitude 
        struct('name','Ft',     'value',0,          'lim',[-40 40])     % temporal frequency of stimulus
        struct('name','taue',   'value',5,          'lim',[0.1 5])      % time constant of excitation
        struct('name','taui',   'value',10,         'lim',[0.1 5])      % time constant of inhibition
        ];
              
    % ODE variables
    sys.vardef = [
        struct('name','Ue', 'value',0.1163, 'lim',[0 1])     % E cell
        struct('name','Ui', 'value',0.1674, 'lim',[0 1])     % I cell
        ];
 
    % Default time span
    sys.tspan = [0 500];
    
    % Default ODE options
    sys.odeoption.AbsTol = 1e-6;
    sys.odeoption.RelTol = 1e-6;
    
    % Latex Panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{EI0D}'
        ''
        'Point model of excitatory-inhibitory cells with Wilson-Cowan dynamics.' 
        'The equations are,'
        '\qquad $\tau_e \; \dot U_e = -U_e + F\Big(w_{ee} U_e - w_{ei} U_i - b_e + J \Big)$'
        '\qquad $\tau_i \; \dot U_i = -U_i + F\Big(w_{ie} U_e - w_{ii} U_i - b_i \Big)$'
        'where'
        '\qquad $U_e(t)$ is the mean firing rate of the \textit{excitatory} population,'
        '\qquad $U_i(t)$ is the mean firing rate of the \textit{inhibitory} population,'
        '\qquad $w_{ei}$ is the weight of the connection to $e$ from $i$,'
        '\qquad $b_{e}$ and $b_{i}$ are firing thresholds,'
        '\qquad $\tau_{e}$ and $\tau_{i}$ are time constants (ms),'
        ''
        'The sigmoidal firing-rate function is,'
        '\qquad $F(v)=1/(1+\exp(-v))$'
        'with unit slope and zero threshold.'
        ''
        'The stimulus is sinusoidal'
        '\qquad $J(t) = 0.5 \, \alpha \, (\cos(0.002 \, \pi \, F_t \, t)+1)$'
        'with amplitide $\alpha$ and frequency $F_t$ (Hz). It is onset at $t=0.$' 
        ''
        '\textbf{Reference}'
        'Heitmann \& Ermentrout (2015) Propagating Waves as a Cortical Mechanism'
        '\qquad of Direction-Selectivity in V1 Motion Cells. First International Workshop'
        '\qquad on Computational Models of the Visual Cortex (CMVC), New York.'
        };
    
    % Other Panels
    sys.panels.bdTimePortrait = [];
    sys.panels.bdPhasePortrait = [];
    sys.panels.bdAuxiliary.auxfun = {@StimulusPlot};
    sys.panels.bdSolverPanel = [];
end

% Our ODE function where
%   t = time (scalar)
%   U = [Ue Ui1] are cell activation states.
%   wee,wei,wie,wii are the connection weights.
%   be and bi are threshold parameters of the sigmoid functions.
%   alpha is the amplitude of the stimulus.
%   Ft is temporal frequency of the stimulus.
%   taue and taui are the time constants of the E and I dynamics.
function dU = odefun(t,U,wee,wei,wie,wii,be,bi,alpha,Ft,taue,taui)
    % extract incoming data
    Ue = U(1);            % excitatory cell 
    Ui = U(2);            % inhibitory cell

    % stimulus
    J = Stimulus(t,Ft,alpha);

    % Wilson-Cowan dynamics
    dUe = (-Ue + F(wee*Ue - wei*Ui + J - be) )./taue;
    dUi = (-Ui + F(wie*Ue - wii*Ui - bi) )./taui;

    % concatenate results
    dU = [dUe; dUi];
end

function J = Stimulus(t,Ft,alpha)
    % The stimulus is a sinusoidal signal for t>0
    % and is zero elsewhere.
    A = alpha * ones(size(t));
    A(t<0) = 0;
    J = 0.5*A.*(cos(0.002*pi*Ft*t)+1);
end

function UserData = StimulusPlot(ax,tt,sol,wee,wei,wie,wii,be,bi,alpha,Ft,taue,taui)
    % time domain
    tdomain = linspace(sol.x(1),sol.x(end),numel(sol.x));
    
    % recreate the stimulus
    J = Stimulus(tdomain,Ft,alpha);

    % plot the stimulus
    plot(tdomain,J);
    ylabel('stimulus');
    xlabel('time');
    title('Stimulus Time Course');
    
    % return stimulus data to user workspace
    UserData.tdomain = tdomain;
    UserData.J = J;
end

% Sigmoidal firing-rate function
function y = F(x)
    y = 1./(1+exp(-x));
end
