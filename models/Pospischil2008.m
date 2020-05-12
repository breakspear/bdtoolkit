% Pospischil2008 Minimal Hodgkin-Huxley type neurons for different classes
% of cortical and thalamic neurons by Pospischil et al (2008).
%
% A conductance-based model of the four most prominent classes of neurons
% in the cerebral cortex and thalamus. Namely the "fast spiking", "regular
% spiking", "intrinisically bursting" and "low-threshold spike" cells.
%
% Authors
% The original equations were published by Martin Pospischil, Maria Toledo-
% Rodriguez, Cyril Monier, Zuzanna Piwkowska, Thierry Bal, Yves Fregnac,
% Henry Markram and Alain Destexhe in 2008. This implementation of the model
% for the Brain Dynamics Toolbox was written by Stewart Heitmann in 2020. 
%
% Example
%    addpath <your bdtoolbox installation directory>
%    sys = Pospischil2008();        % construct the model
%    gui = bdGUI(sys);              % run the model in the GUI
%
% References:
% Pospischil, Toledo-Rodriguez, Monier, Piwkowska, Bal, Fregnac, Markram,
%    Destexhe (2008) Minimal Hodgkin-Huxley type models for different
%    classes of cortical and thalamic neurons. Biological Cybernetics.
% Heitmann, Breakspear (2019) Handbook for the Brain Dynamics Toolbox:
%    Version 2019a. QIMR Berghofer Medical Research Institute. 
%    https://bdtoolbox.org

% Copyright (C) 2020 Stewart Heitmann <heitmann@bdtoolbox.org>
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
function sys = Pospischil2008(flag)
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    switch flag
        case 'RS'
            Cm = 1;
            Iamp = 1;
            Idur = 2000;
            gleak = 0.0205;
            gNa = 56;
            gKd = 6;
            gM = 0.075;
            gL = 0;
            gT = 0;
            Eleak = -70.3;
            ENa = 50;
            EK = -90;
            ECa = 120;
            VT = -56.2;
            Vx = 2;
            tau = 608;
            tspan = [-500 2500];
            V0 = -71.9;
            m0 = 0;
            h0 = 1;
            n0 = 0;
            p0 = 0;
            q0 = 0;
            r0 = 0.7;
            u0 = 0;
        case 'FS'
            Cm = 2;
            Iamp = 1.8;
            Idur = 500;
            gleak = 0.15;
            gNa = 56;
            gKd = 10;
            gM = 0;
            gL = 0;
            gT = 0;
            Eleak = -70.3;
            ENa = 50;
            EK = -90;
            ECa = 120;
            VT = -67.9;
            Vx = 2;
            tau = 608;
            tspan = [-200 700];
            V0 = -70.3;
            m0 = 0;
            h0 = 1;
            n0 = 0;
            p0 = 0;
            q0 = 0;
            r0 = 0.7;
            u0 = 0;
        case 'IB'
            Cm = 1;
            Iamp = 0.7;
            Idur = 2000;
            gleak = 0.01;
            gNa = 50;
            gKd = 5;
            gM = 0.03;
            gL = 0.1;
            gT = 0;
            Eleak = -70;
            ENa = 50;
            EK = -90;
            ECa = 120;
            VT = -40;
            Vx = 2;
            tau = 600;
            tspan = [-500 2500];
            V0 = -70.3;
            m0 = 0;
            h0 = 1;
            n0 = 0;
            p0 = 0;
            q0 = 0;
            r0 = 0.7;
            u0 = 0;
        otherwise
            error('flag must be ''RS'', ''FS'' or ''IB''');
    end
    
    % Our ODE parameters
    sys.pardef = [
        struct('name','Cm',    'value',Cm,    'lim',[0.01 2]); 
        struct('name','Iamp',  'value',Iamp,  'lim',[0 10]);
        struct('name','Idur',  'value',Idur,  'lim',[0 1000]);
        struct('name','gleak', 'value',gleak, 'lim',[0 0.0001]);
        struct('name','gNa',   'value',gNa,   'lim',[0 1]);
        struct('name','gKd',   'value',gKd,   'lim',[0 1]);
        struct('name','gM',    'value',gM,    'lim',[0 0.001]);
        struct('name','gL',    'value',gL,    'lim',[0 0.001]);
        struct('name','gT',    'value',gT,    'lim',[0 0.001]);
        struct('name','Eleak', 'value',Eleak, 'lim',[-100 100]);
        struct('name','ENa',   'value',ENa,   'lim',[-100 100]);
        struct('name','EK',    'value',EK,    'lim',[-100 100]);
        struct('name','ECa',   'value',ECa,   'lim',[0 200]);
        struct('name','VT',    'value',VT,    'lim',[-100 100]);
        struct('name','Vx',    'value',Vx,    'lim',[0 10]);
        struct('name','tau',   'value',tau,   'lim',[1 10000]);        
        ];
               
    % Our ODE variables        
    sys.vardef = [ 
        struct('name','V', 'value',V0,   'lim',[-80 80]);
        struct('name','m', 'value',m0,   'lim',[-0.1 1.1]);
        struct('name','h', 'value',h0,   'lim',[-0.1 1.1])
        struct('name','n', 'value',n0,   'lim',[-0.1 1.1]);
        struct('name','p', 'value',p0,   'lim',[-0.1 1.1]);
        struct('name','q', 'value',q0,   'lim',[-0.1 1.1]);
        struct('name','r', 'value',r0,   'lim',[-0.1 1.1]);
        struct('name','u', 'value',u0,   'lim',[-0.1 1.1]);
        ];
    
    % Default time span
    sys.tspan = tspan;
    
    % Default solver options
    sys.odeoption = odeset('RelTol',1e-6, 'InitialStep',0.01);
    sys.odesolver = {@ode15s @ode45 @ode23 @ode113 @ode23s};
    
    % Latex (Equations) panel
    sys.panels.bdLatexPanel.latex = {
        '\textbf{Pospischil2008}'
        ''
        'A conductance-based model of the four most prominent classes of'
        'neurons in the cerebral cortex and thalamus by Pospischil et al (2008).'
        'It demonstrates fast-spiking, regular-spiking and intrinisically-bursting'
        'cell dynamics.'
        ''
        'The membrane equations are,'
        '\qquad $C_m \; \frac{dV}{dt} = -I_{leak} - I_{Na} - I_{Kd} - I_M - I_T - I_L + I_{stim}$'
        'where'
        '\qquad $V(t)$ is the electrical potential across the membrane,'
        '\qquad $C_m$ is the membrane capacitance,'
        '\qquad $I_{stim}$ is an external current that is applied to the membrane.'
        ''
        'The leak current is'
        '\qquad $I_{leak} = g_{leak} (V - E_{leak})$'
        ''
        'The sodium current is'
        '\qquad $I_{Na} = g_{Na} m^3 h (V - E_{Na})$'
        'where the kinetics of the activation variable $m(t)$ are'
        '\qquad $\frac{dm}{dt} = \alpha_m (1-m) - \beta_m m$'
        '\qquad $\alpha_m = \frac{-0.32 (V-V_T-13)}{\exp(-(V-V_T-13)/4) - 1}$'
        '\qquad $\beta_m =  \frac{0.28 (V-V_T-40)}{\exp( (V-V_T-40)/5) - 1}$'
        'and the kinetics of the inactivation variable $h(t)$ are'
        '\qquad $\frac{dh}{dt} = \alpha_h (1-h) - \beta_h h$'
        '\qquad $\alpha_h = 0.128 \exp(-(V-V_T-17)/18)$'
        '\qquad $\beta_h = \frac{4}{1 + \exp(-(V-V_T-40)/5)}$'
        ''
        'The delayed-rectifier potassium current is'
        '\qquad $I_{Kd} = g_{Kd} \, n^4 \, (V - E_{K})$'
        'where the kinetics of the activation variable $n(t)$ are'
        '\qquad $\frac{dn}{dt} = \alpha_n (1-n) - \beta_n n$'
        '\qquad $\alpha_n = \frac{-0.032 (V-V_T-15)}{\exp(-(V-V_T-15)/5) - 1}$'
        '\qquad $\beta_n = 0.5 \exp(-(V-V_T-10)/40)$'
        ''
        'The slow potassium current for spike-frequency adaptation is'
        '\qquad $I_{M} = g_{M} \, p \, (V - E_{K})$'
        'where the kinetics of the activation variable $p(t)$ are'
        '\qquad $\tau_p \frac{dp}{dt} = p_\infty - p$'
        '\qquad $p_\infty = \frac{1}{1 + \exp(-(V+35)/10)}$'
        '\qquad $\tau_p = \frac{\tau}{3.3 \exp((V+35)/20) + \exp(-(V+35)/20)}$'
        ''
        'The high-threshold calcium current for burst generation is'
        '\qquad $I_L = g_L \, q^2 \, r \, (V-E_{Ca})$'
        'where the kinetics of the activation variable $q(t)$ are'
        '\qquad $\frac{dq}{dt} = \alpha_q (1-q) - \beta_q q$'
        '\qquad $\alpha_q = \frac{0.055 (-27-V)}{\exp((-27-V)/3.8) - 1}$'
        '\qquad $\beta_q = 0.94 \exp((-75-V)/17)$'
        'and the kinetics of the inactivation variable $r(t)$ are'
        '\qquad $\frac{dr}{dt} = \alpha_r (1-r) - \beta_r r$'
        '\qquad $\alpha_r = 0.000457 \exp((-13-V)/50)$'
        '\qquad $\beta_r = \frac{0.0065}{\exp((-15-V)/28) + 1}$'
        ''
        'The low-threshold calcium current for burst generation is'
        '\qquad $I_T = g_T \, s_\infty^2 \, u \, (V-E_{Ca})$'
        'where the activation variable $s$ is only considered at steady-state'
        '\qquad $s_\infty = 1 / (1 + \exp(-(V+V_x+57)/6.2))$'
        'and the kinetics of the inactivation variable $u(t)$ are'
        '\qquad $\tau_u \frac{du}{dt} = u_\infty - u$'
        '\qquad $u_\infty = 1 / (1 + \exp((V+V_x+81)/4))$'
        '\qquad $\tau_u = \frac{30.8 + (211.4 + \exp((V+V_x+113.2)/5))}{(3.7 (1 + \exp((V+V_x+84)/3.2))}$'
        ''
        'The external stimulation current is'
        '\qquad $I_{stim} = I_{amp}$ when $0\leq t \leq I_{dur}$'
        'and zero otherwise.'
        ''
        '\textbf{Reference}'
        'Pospischil, Toledo-Rodriguez, Monier, Piwkowska, Bal, Fregnac,'
        'Markram, Destexhe (2008) Minimal Hodgkin-Huxley type models'
        'for different classes of cortical and thalamic neurons. Biological'
        'Cybernetics 99:427--441.'
        };
    
    % Time-Portrait panel
    sys.panels.bdTimePortrait = [];
    
    % Phase-Portrait panel
    sys.panels.bdPhasePortrait = [];
    
    % Solver panel
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function
function [dY,INa,IKd] = odefun(t,Y,Cm,Iamp,Idur,gleak,gNa,gKd,gM,gL,gT,Eleak,ENa,EK,ECa,VT,Vx,tau)
    % extract incoming variables from Y
    V = Y(1);       % membrane voltage
    m = Y(2);       % Na activation variable
    h = Y(3);       % Na inactivation variable
    n = Y(4);       % Kd activation variable
    p = Y(5);       % slow K non-inactivation variable
    q = Y(6);       % high-threshold Ca activation variable
    r = Y(7);       % high-threshold Ca inactivation variable
    u = Y(8);       % low-threshold Ca activation variable
    
    % Sodium (Na) current, following Traub & Miles (1991)
    INa = gNa * m^3 * h * (V-ENa);
    
    % Na activation kinetics
    Am = -0.32*(V-VT-13) ./ (exp(-(V-VT-13)/4) - 1);
    Bm =  0.28*(V-VT-40) ./ (exp( (V-VT-40)/5) - 1);
    dm = Am*(1-m) - Bm*m;
    
    % Na inactivation kinetics
    Ah = 0.128*exp(-(V-VT-17)/18);
    Bh = 4 ./ (1 + exp(-(V-VT-40)/5));
    dh = Ah*(1-h) - Bh*h;
    
    % Delayed-Rectifier Potassium (Kd) current, following Traub & Miles (1991)
    IKd = gKd * n^4 * (V-EK);
    
    % Kd activation kinetics
    An = -0.032*(V-VT-15) ./ (exp(-(V-VT-15)/5) - 1);
    Bn = 0.5*exp(-(V-VT-10)/40);
    dn = An*(1-n) - Bn*n;
    
    % Slow Potassium current (IM) for spike-frequency adaptation, following Yamada et al (1989)
    IM = gM * p * (V-EK);
    pinf = 1 ./ (1 + exp(-(V+35)/10));
    taup = tau ./ ( 3.3*exp((V+35)/20) + exp(-(V+35)/20) );
    dp = (pinf-p)./taup;
    
    % High-threshold Calcium current (IL) to generate bursting, following Reuveni et al (1993)
    IL = gL * q^2 * r * (V-ECa);
    
    % IL activation kinetics
    Aq = 0.055*(-27-V) ./ (exp((-27-V)/3.8) - 1);
    Bq = 0.94*exp((-75-V)/17);
    dq = Aq*(1-q) - Bq*q;
    
    % IL inactivation kinetics
    Ar = 0.000457*exp((-13-V)/50);
    Br = 0.0065 ./ (exp((-15-V)/28) + 1);
    dr = Ar*(1-r) - Br*r;
    
    % Low-threshold Calcium current (IT) to generate bursting, following Destexhe et al (1996)
    sinf = 1 ./ (1 + exp(-(V+Vx+57)/6.2));
    uinf = 1 ./ (1 + exp((V+Vx+81)/4));
    tauu = (30.8 + (211.4 + exp((V+Vx+113.2)/5))) ./ (3.7*(1 + exp((V+Vx+84)/3.2)));
    IT = gT * sinf^2 * u * (V-ECa);    
    du = (uinf-u)./tauu;
    
    % External stimulus
    if t>=0 && t<= Idur
        Istim = Iamp;
    else
        Istim = 0;
    end
    
    % membrane equation
    dV = (-gleak*(V-Eleak) - INa - IKd - IM - IT - IL + Istim)./Cm;
    
    % return result
    dY = [dV; dm; dh; dn; dp; dq; dr; du];
end

