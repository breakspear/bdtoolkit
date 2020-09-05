% EIE0D Point model of E-I-E cells with Wilson-Cowan dynamics 
% for the Brain Dynamics Toolbox (https://bdtoolbox.org)
%
% EXAMPLE:
%    addpath ~/bdtoolkit
%    sys = EIE0D();
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
function sys = EIE0D
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % ODE variables
    sys.vardef = [ struct('name','Ue1', 'value',0.0,  'lim',[0 1]);    % activity of E population
                   struct('name','Ui',  'value',0.0,  'lim',[0 1]);    % activity of I population
                   struct('name','Ue2', 'value',0.0,  'lim',[0 1]) ];  % activity of E population
    
    % ODE parameters
    sys.pardef = [ struct('name','wee',   'value',12,    'lim',[0 20]);    % weight of e-to-e connection
                   struct('name','wei',   'value',10,    'lim',[0 20]);    % weight of i-to-e connection
                   struct('name','wie',   'value',10,    'lim',[0 20]);    % weight of e-to-i connection
                   struct('name','wii',   'value', 1,    'lim',[0 20]);    % weight of i-to-i connection
                   struct('name','be',    'value', 1.75, 'lim',[0 5]);     % threshold of excitation
                   struct('name','bi',    'value', 2.6,  'lim',[0 5]);     % threshold of inhibition 
                   struct('name','J1',    'value', 0,    'lim',[0 2]);     % current injected into Ue1
                   struct('name','J2',    'value', 0,    'lim',[0 2]);     % current injected into Ue2
                   struct('name','delta', 'value', 0,    'lim',[-1 1]);    % stimulus bias toward Ue1 versus Ue2
                   struct('name','taue',  'value', 5,    'lim',[0 20]);    % time constant of excitation
                   struct('name','taui',  'value',10,    'lim',[0 20]) ];  % time constant of inhibition

    % Default time span of the simulation
    sys.tspan = [0 200];

    % Default ODE options
    sys.odeoption.AbsTol = 1e-6;
    sys.odeoption.RelTol = 1e-6;

    % Latex Equations panel
    sys.panels.bdLatexPanel.title = 'Equations';
    sys.panels.bdLatexPanel.latex = {
        '\textbf{EIE1D}'
        ''
        'Point model of an E-I-E assembly,'
        '\quad $\tau_e \; \dot{U}_{e1} = -U_{e1} + F_e \big( w_{ee} U_{e1} - w_{ei} U_i - b_e + J_1 + \Delta \big)$'
        '\quad $\tau_i \; \dot{U}_i = -U_i + F_e \big( w_{ie} U_{e1} + w_{ie} U_{e2} - w_{ii} U_i - b_i \big)$'
        '\quad $\tau_e \; \dot{U}_{e2} = -U_{e2} + F_i(w_{ee} U_{e2} - w_{ei} U_i - b_e + J_2 - \Delta \big)$'
        'where'
        '\qquad $U_{e1}(t)$ and $U_{e2}(t)$ are the firing rates of the excitatory populations,'
        '\qquad $U_i(t)$ is the firing rate of the inhibitory population,'
        '\qquad $w_{ei}$ is the weight of the connection to $e$ from $i$,'
        '\qquad $J_1$ and $J_2$ are incoming signals from external stimuli,'
        '\qquad $\Delta$ is a bias applied to $J_{1}$ versus $J_{2}$,'
        '\qquad $b_{e}$ and $b_{i}$ are threshold constants,'
        '\qquad $\tau_{e}$ and $\tau_{i}$ are time constants,'
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoidal firing-rate function.'
        'The external stimulation is not applied for $t<0$.'
        ''
        '\textbf{Reference}'
        'Heitmann \& Ermentrout. Propagating Waves as a Cortical Mechanism of'
        'Direction-Selectivity in V1 Motion Cells. First International Workshop on'
        'Computational Models of the Visual Cortex (CMVC 2015), New York.'        
        };

    % Time portrait
    sys.panels.bdTimePortrait = [];
    
    % Phase portrait
    sys.panels.bdPhasePortrait = [];
    
    % Solver panel
    sys.panels.bdSolverPanel = [];
end

function dU = odefun(t,U,wee,wei,wie,wii,be,bi,J1,J2,delta,taue,taui)
    % extract incoming data
    Ue1 = U(1);      % excitatory cell
    Ui  = U(2);      % inhibitory cell
    Ue2 = U(3);      % excitatory cell
    
    % Injection currents are not applied for t<0
    if t<0
        J1=0;
        J2=0;
        delta=0;
    end
    
    % Wilson-Cowan dynamics
    dUe1 = (-Ue1 + F(wee*Ue1 - wei*Ui - be + J1 + delta) )./taue;
    dUi  = (-Ui + F(wie*(Ue1+Ue2) - wii*Ui - bi) )./taui;
    dUe2 = (-Ue2 + F(wee*Ue2 - wei*Ui - be + J2 - delta) )./taue;

    % concatenate results
    dU = [dUe1; dUi; dUe2];
end

function y = F(x)
    y = 1./(1+exp(-x));
end

