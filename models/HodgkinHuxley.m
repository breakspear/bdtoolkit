% HodgkinHuxley Classic Hodgkin-Huxley model of squid axon potential
%    Cm V' = Im - Ik - Ina - Il
% where
%    V is the membrane potential
%    Cm is the membrane capacitance
%    Im is the current injected into the membrane
%    Il = gl * (V-El) is the leak current
%    Ik = gk * n^4 * (V-Ek) is the potassium current
%    Ina = gna * m^3 * h * (V-Ena) is the sodium current
%
% The gating variables m, n and h satisfy the kinetics equations 
%    m' = alpha_m * (1 - m) - beta_m * m
%    n' = alpha_n * (1 - n) - beta_n * n
%    h' = alpha_h * (1 - h) - beta_h * h
% where
%    alpha_m = 0.1 * (-V+25)/(exp((-V+25)/10)-1)  
%    alpha_n = 0.01 * (-V+10)/(exp((-V+10)/10)-1)  
%    alpha_h = 0.07 * exp(-V/20)
%    beta_m = 4 * exp(-V/18)
%    beta_n = 0.125 * exp(-V/80)
%    beta_h = 1/*exp((-V+30)/10)+1))
%
% Example
%    sys = HodgkinHuxley;
%    gui = bdGUI(sys);
%
% Authors
%   Stewart Heitmann (2018)
%
% References:
% Hodgkin and Huxley (1952) A quantitative description of membrane current
%   and its application to conduction and excitation in a nerve. J Physiol
%   117:165-181
% Hansel, Mato, Meunier (1993) Phase Dynamics for Weakly Coupled Hodgkin-
%   Huxley Neurons. Europhys Lett 23(5)

function sys = HodgkinHuxley()
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','C',     'value',1,      'lim',[0.1 2]); 
        struct('name','I',     'value',0,      'lim',[0 15]);
        struct('name','gNa',   'value',120,    'lim',[0 200]);
        struct('name','gK',    'value',36,     'lim',[0 50]);
        struct('name','gL',    'value',0.3,    'lim',[0 1]);
        struct('name','ENa',   'value',50,     'lim',[-100 100]);
        struct('name','EK',    'value',-77,    'lim',[-100 100]);
        struct('name','EL',    'value',-54.4,  'lim',[-100 100]);
        ];
               
    % Our ODE variables        
    sys.vardef = [ 
        struct('name','V', 'value',-65,      'lim',[-90 50]);
        struct('name','m', 'value',0.0527,   'lim',[0 1]);
        struct('name','h', 'value',0.597,    'lim',[0 1])
        struct('name','n', 'value',0.317,    'lim',[0 1]);
        ];
    
    % Default time span
    sys.tspan = [0 100];
              
    % Default solver options
    sys.odeoption = odeset('RelTol',1e-6, 'InitialStep',0.01);

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Hodgkin Huxley Equations}';
        '';
        'Describe the membrane potential of squid giant axon';
        '\qquad $C \; \dot V = I - g_{Na}\; m^3 \; h \; (V-E_{Na}) - g_K \; n^4 \; (V-E_K) - g_L \; (V-E_L)$';
        '\qquad $\dot m = \big(m_{\infty}(V) - m \big) \; / \; \tau_m(V)$';
        '\qquad $\dot h = \big(h_{\infty}(V) - h \big) \; / \; \tau_h(V)$';
        '\qquad $\dot n = \big(n_{\infty}(V) - n \big) \; / \; \tau_n(V)$';
        'where';
        '\qquad $V(t)$ is the membrane potential,';
        '\qquad $m(t)$ is the activation variable of the sodium current,';
        '\qquad $h(t)$ is the inactivation variable of the sodium current,';
        '\qquad $n(t)$ is the activation variable of the potassium current,';
        '\qquad $C$ is the membrane capacitance,';
        '\qquad $I$ is the injected current,';
        '\qquad $g_{Na}, g_K, g_L$ are the maximum conductances of the Na, K and leak currents,';
        '\qquad $E_{Na}, E_K, E_L$ are the reversal potentials of the Na, K and leak currents.';
        '';
        'The steady-state voltage-dependent channel activations are given by';
        '\qquad $m_{\infty}(V) = a_m / (a_m + b_m)$,';
        '\qquad $n_{\infty}(V) = a_n / (a_n + b_n)$.';
        '\qquad $h_{\infty}(V) = a_h / (a_h + b_h)$,';
        '';
        'Their characteristic times are given by';
        '\qquad $\tau_m(V) = 1 / (a_m + b_m)$,';
        '\qquad $\tau_n(V) = 1 / (a_n + b_n)$.';
        '\qquad $\tau_h(V) = 1 / (a_h + b_h)$,';
        '';
        'The voltage-dependent relations';
        '\qquad $a_m = 0.1*(V+40)/(1-\exp((-V-40)/10))$';
        '\qquad $a_n = 0.01*(V+55)/(1-\exp((-V-55)/10))$';
        '\qquad $a_h = 0.07*\exp((-V-65)/20)$';
        '\qquad $b_m = 4*\exp((-V-65)/18)$';
        '\qquad $b_n = 0.125*\exp((-V-65)/80)$';
        '\qquad $b_h = 1/(1+\exp((-V-35)/10))$';
        'were established by empirical observation.';
        '';
        '';
        '\textbf{References}';
        'Hodgkin, Huxley (1952) A quantitative description of membrane current and';
        '\quad its application to conduction and excitation in a nerve. J Physiol 117';
        'Hansel, Mato, Meunier (1993) Phase Dynamics for Weakly Coupled Hodgkin-';
        '\quad Huxley Neurons. Europhys Lett 23 (5)';
        };
    
    % Time-Portrait panel
    sys.panels.bdTimePortrait = [];
    
    % Phase-Portrait panel
    sys.panels.bdPhasePortrait = [];
    
    % Auxiliary Plot panel
    sys.panels.bdAuxiliary.auxfun = {@sodium,@potassium,@combined,@VoltageGates};

    sys.panels.bdSolverPanel = [];                 
end

% The ODE function
function dY = odefun(~,Y,C,I,gNa,gK,gL,ENa,EK,EL)  
    % extract incoming variables from Y
    V = Y(1);
    m = Y(2);
    n = Y(3);
    h = Y(4);
    
    IL = gL * (V-EL);
    IK = gK * n^4 * (V-EK);
    INa = gNa * m^3 * h * (V-ENa);

    am = 0.1*(V+40)/(1-exp((-V-40)/10));
    an = 0.01*(V+55)/(1-exp((-V-55)/10));
    ah = 0.07*exp((-V-65)/20);
    
    bm = 4*exp((-V-65)/18);
    bn = 0.125*exp((-V-65)/80);
    bh = 1/(1+exp((-V-35)/10));
    
    minf = am / (am + bm); 
    ninf = an / (an + bn); 
    hinf = ah / (ah + bh); 
    
    taum = 1 / (am + bm);
    taun = 1 / (an + bn);
    tauh = 1 / (ah + bh);
    
    dV = (I - IK - INa - IL)./C;
    dm = (minf - m)/taum;
    dn = (ninf - n)/taun;
    dh = (hinf - h)/tauh;

    % return result
    dY = [dV; dm; dn; dh];
end

% Auxiliary function that plots the time course of activation and inactivation of the sodium ion channel
function sodium(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, m.^3, 'b-');
    plot(ax, t, h, 'b--');
    plot(ax, t, m.^3 .* h , 'k-', 'Linewidth',1.5);
    ylim(ax,[-0.1 1.1]);
    xlim(ax,[t(1) t(end)]);
    legend(ax,'activation, m^3','inactivation, h','combined, m^3h');
    title(ax,'sodium channel activation and inactivation'); 
    xlabel(ax,'time');
end

% Auxiliary function that plots the time course of activation of the potassium ion channel
function potassium(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, n.^4 , 'r-', 'Linewidth',1.5);
    ylim(ax,[-0.1 1.1]);
    xlim(ax,[t(1) t(end)]);
    legend(ax,'activation, n^4');
    title(ax,'potassium channel activation'); 
    xlabel(ax,'time');
end

% Auxiliary function that plots the time course of sodium and postassium activation combined
function combined(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    % extract the solution data
    t = sol.x;
    V = sol.y(1,:);
    m = sol.y(2,:);
    n = sol.y(3,:);
    h = sol.y(4,:);

    % Plot the conductances.
    plot(ax, t, m.^3 .* h , 'k-', 'Linewidth',1.5);
    plot(ax, t, n.^4 , 'r-', 'Linewidth',1.5);
    ylim(ax,[-0.1 1.1]);
    xlim(ax,[t(1) t(end)]);
    legend(ax,'sodium','potassium');
    title(ax,'sodium and potassium channel activation'); 
    xlabel(ax,'time');
end

% Auxiliary function that plots steady-state voltage-dependent channel activations
function VoltageGates(ax,tt,sol,C,I,gNa,gK,gL,ENa,EK,EL)
    V = linspace(-90,50,201);
    
    am = 0.1*(V+40)./(1-exp((-V-40)./10));
    an = 0.01*(V+55)./(1-exp((-V-55)./10));
    ah = 0.07*exp((-V-65)./20);
    
    bm = 4*exp((-V-65)./18);
    bn = 0.125*exp((-V-65)./80);
    bh = 1./(1+exp((-V-35)./10));
    
    minf = am ./ (am + bm); 
    ninf = an ./ (an + bn); 
    hinf = ah ./ (ah + bh); 

    % Plot minf.
    plot(ax, V, minf , 'b-', 'Linewidth',1.5);
    plot(ax, V, hinf , 'b--', 'Linewidth',1.5);
    plot(ax, V, ninf , 'r-', 'Linewidth',1.5);
    ylim(ax,[-0.1 1.1]);
    xlim(ax,[-90 50]);
    legend(ax,'minf','hinf','ninf');
    title(ax,'Steady-state Voltage-dependent Channel Activations'); 
    xlabel(ax,'V');
end
