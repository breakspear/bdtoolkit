%sdeSH  Solve a Stratonovich SDE using the Stratonovich-Heun method.
%   SOL = sdeSH(ODEFUN,SDEFUN,TSPAN,Y0,OPTIONS,...)
%   uses the Stratonovich-Heun method to integrate a system of Stratonovich 
%   stochastic differential equations of the form 
%      dy = F(t,y,...)*dt + G(t,y,...)*dW(t)
%   where F(t,y,...)*dt is the deterministic part and G(t,y,...)*dW(t) is
%   the stochastic part. dW(t) is a vector of independent Wiener increments.
%   The differential equations are assumed to be in Stratonovich form.
% 
%   The method integrates the equations for time span TSPAN=[T0 TFINAL]
%   from initial conditions Y0. ODEFUN and SDEFUN are handles to the
%   user-defined F(t,y,...)and G(t,y,...) functions,  for example:
%
%   function f = odefun(t,Y,theta,mu,sigma)  
%       f = theta .* (mu - Y);          % returns an (nx1) column vector
%   end
%
%   function g = sdefun(t,Y,theta,mu,sigma)
%       g = sigma .* eye(numel(Y));     % returns an (nxn) matrix
%   end
%
%   Note that ODEFUN must return an (nx1) column vector whereas SDEFUN
%   must return an (nxm) matrix of noise coefficients. The solver
%   matrix-multiplies the noise coefficicents by the (mx1) noise terms
%   in dW(t) to obtain an (nx1) column vector.
%
%   Solver-specific options are passed via the OPTIONS struct, of which,
%   only the NOISESOURCES field is mandatory.
%
%   OPTIONS =
%      NoiseSources: [m]           number of noise processes in dW
%       InitialStep: [dt]          integrator time step (optional)
%             randn: [mxT]         pre-generated standard normal random values
%         OutputFcn: @(t,Y,flag)   handle to user-defined output function
%
%   The solution is returned in the SOL struct as per ode45, ode23, etc.
%   Interpolating the solution (using bdEval) is not recommended because
%   bdEval does not correctly interpolate stochastic processes.
%
%   SOL =
%       x: [1xT]  time points
%       y: [nxT]  y(t) values
%      yp: [nxT]  the change in y over the following time step, divided by dt
%      dW: [mxT]  Wiener increments 
%
%  The Wiener increments are computed as dW=sqrt(dt)*randn(m,T) where m is
%  the number of driving Wiener processes (NoiseSources) and T is the number
%  of time points in the solution. The time points [T0:dt:TFINAL]
%  are equi-spaced with time step dt defined by the INITIALSTEP option. If
%  INITIALSTEP is undefined then the solver defaults to 101 time steps
%  by setting dt=(TFINAL-T0)/100. 
%
%  Alternatvely, the user may supply pre-computed random values via the
%  RANDN field of the OPTIONS struct. Those values must be drawn from a normal
%  distribution with mean 0 and std 1 using the Matlab RANDN(m,T) function.
%  The INITIALSTEP option is ignored becasue the step size dt=(TFINAL-T0)/(T-1)
%  is determined by TSPAN=[T0 TFINAL] and the number of time points (T)
%  in RANDN.
%
%EXAMPLE
%  % anonymous versions of the F() and G() functions shown above.
%  odefun = @(t,Y,theta,mu,sigma) theta.*(mu - Y);
%  sdefun = @(t,Y,theta,mu,sigma) sigma .* eye(numel(Y));
%  tspan = [0 10];                  % time domain
%  n = 13;                          % number of equations
%  Y0 = ones(n,1);                  % initial conditions
%  options.NoiseSources = n;        % number of driving Wiener processes
%  options.InitialStep = 0.01;      % step size, dt
%  theta = 1;                       % model-specific parameter
%  mu = -1;                         % model-specific parameter
%  sigma = 0.5;                     % model-specific parameter
%  sol = sdeSH(odefun,sdefun,tspan,Y0,options,theta,mu,sigma);
%  T = sol.x;                       % solution time points
%  Y = sol.y;                       % solution values y(t)
%  plot(T,Y);                       % plot the results
%
%AUTHORS
%  Stewart Heitmann (2016a,2017a,2018a)
%  Matthew Aburn (2016a)

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
function sol = sdeSH(odefun,sdefun,tspan,y0,options,varargin)
    % Get the number of noise sources (driving Wiener processes).
    if isfield(options,'NoiseSources')
        m = options.NoiseSources;
    else
        error('options.NoiseSources is undefined');
    end
    
    % Get the time step from the InitialStep option (if it exists)
    if isfield(options,'InitialStep')
        dt = options.InitialStep;
    else
        % Default to 101 steps in tspan
        dt = (tspan(end) - tspan(1))/100;
    end
        
    % If random number sequences have been by supplied by the user then we
    % use the size of that sequence to determine the step size dt and 
    % the number of noise sources m.
    % This value of dt overrides that given by the InitialStep option.
    % However the value of m must match the NoiseSources option exactly.
    if isfield(options,'randn') && ~isempty(options.randn)
        % The rows of dW determine the number of noise sources (m).
        % The cols of dW determine the number of time steps (tcount).
        [mm,tcount] = size(options.randn);

        % The number of time steps in tspan determine the step size (dt)
        dt = (tspan(end) - tspan(1))/(tcount-1);
        
        % Assert that m matches the NoiseSources option
        assert(mm==m,'The number of rows in options.randn must equal options.NoiseSources');
    end
    
    % span the time domain in fixed steps
    sol.x = tspan(1):dt:tspan(end);
    tcount = numel(sol.x);
    
    % allocate space for the results
    sol.y = NaN(numel(y0),tcount);      % values of y(t)
    sol.yp = sol.y;                     % values of dy(t)/dt

    % compute the Wiener increments
    if isfield(options,'randn') && ~isempty(options.randn)
        % The user has supplied us with random samples,
        % we only need scale it by sqrt(dt)
        sol.dW = sqrt(dt) .* options.randn;
    else
        % Generate the Wiener increments (scaled by sqrt(dt))
        sol.dW = sqrt(dt) .* randn(m,tcount);
    end
    
    % miscellaneous output
    sol.solver = mfilename;
    sol.extdata.odefun = odefun;
    sol.extdata.sdefun = sdefun;
    sol.extdata.options = options;
    sol.ex21tdata.varargin = varargin;
    
    % Get the OutputFcn callback.
    OutputFcn = odeget(options,'OutputFcn');
    if ~isempty(OutputFcn)
        % initialize the OutputFcn
        OutputFcn(tspan,sol.y(:,1),'init');
    end
    
    % We call OutputFcn whenever the integration time exceeds a time
    % point listed in tspan. We assume that entries in tspan are 
    % monotonic so that we can simply iterate from the first entry of
    % tspan to the last.
    tspanidx = 1;           % Current index of tspan
        
    % Fixed-step Stratonovich-Heun method
    sol.y(:,1) = y0;
    for indx=1:tcount-1        
        % Execute the OutputFcn whenever the time step reaches the next
        % time point listed in tspan. Ordinarily, there would be multiple
        % Euler steps between calls to OutputFcn. Nonetheless, a single
        % Euler step might (perversely) span multiple time points in tspan.
        % Hence the while loop.
        while ~isempty(OutputFcn) && sol.x(indx)>=tspan(tspanidx)
            % call the output function
            status = OutputFcn(sol.x(indx),sol.y(:,indx),'');
            if status==1
                % User has cancelled the operation.
                sol.stats.nsteps = indx;
                sol.stats.nfailed = 0;
                sol.stats.nfevals = tcount;
                return
            end
            % Advance to the next entry in tspan
            tspanidx = tspanidx+1;
        end

        % Stratonovich-Heun step
        tn = sol.x(indx);
        tnp1 = sol.x(indx+1);
        yn = sol.y(:,indx);
        dWn = sol.dW(:,indx);
        fn = odefun(tn, yn, varargin{:});
        Gn = sdefun(tn, yn, varargin{:});
        ybar = yn + fn*dt + Gn*dWn;
        fnbar = odefun(tnp1, ybar, varargin{:});
        Gnbar = sdefun(tnp1, ybar, varargin{:});
        sol.yp(:,indx) = 0.5*(fn + fnbar)*dt + 0.5*(Gn + Gnbar)*dWn;
        sol.y(:,indx+1) = yn + sol.yp(:,indx);
        
        % Check the Stratonovish-Heun step for overflow
        if any(~isfinite(sol.y(:,indx+1)))
            msg = num2str(sol.x(indx),'Failure at t=%g. The numerical values are no longer finite.');
            warning('sdeSH:Overflow',msg);
            sol.stats.nsteps = indx;
            sol.stats.nfailed = 1;
            sol.stats.nfevals = tcount;
            return
        end

    end

    % Complete the final Stratonovich-Heun step
    tn = sol.x(end);
    tnp1 = tn+dt;
    yn = sol.y(:,end);
    dWn = sol.dW(:,end);
    fn = odefun(tn, yn, varargin{:});
    Gn = sdefun(tn, yn, varargin{:});
    ybar = yn + fn*dt + Gn*dWn;
    fnbar = odefun(tnp1, ybar, varargin{:});
    Gnbar = sdefun(tnp1, ybar, varargin{:});
    sol.yp(:,end) = 0.5*(fn + fnbar)*dt + 0.5*(Gn + Gnbar)*dWn;
    
    % Check the final Stratonovich-Heun step for overflow
    if any(~isfinite(sol.y(:,end)))
        msg = num2str(sol.x(end),'Failure at t=%g. The numerical values are no longer finite.');
        warning('sdeSH:Overflow',msg);
        sol.stats.nsteps = tcount;
        sol.stats.nfailed = 1;
        sol.stats.nfevals = tcount;
        return
    end

    % Execute the OutputFcn for the final entry in tspan.
    if ~isempty(OutputFcn)
        % call the output function
        status = OutputFcn(sol.x(end),sol.y(:,end),'');
        if status==1
            % User has cancelled the operation.
            sol.stats.nsteps = tcount;
            sol.stats.nfailed = 0;
            sol.stats.nfevals = tcount;
            return
        end        
        % cleanup the OutputFcn
        OutputFcn([],[],'done');
    end
        
    % Stats
    sol.stats.nsteps = tcount;
    sol.stats.nfailed = 0;
    sol.stats.nfevals = tcount;
end
