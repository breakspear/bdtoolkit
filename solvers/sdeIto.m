%sdeIto  Solve Ito stochastic differential equation, Euler-Maruyama method.
%   SOL = sdeIto(ODEFUN,SDEFUN,TSPAN,Y0,OPTIONS,...)
%   uses the Euler-Marayuma method to integrate a system of stochastic
%   differential equations of the form 
%      dy = F(t,y,...)*dt + G(t,y,...)*dW(t)
%   where F(t,y,...)*dt is the deterministic part and G(t,y,...)*dW(t) is
%   the stochastic part. dW(t) is a Weiner (Brownian) noise process.
%   The differential equations are assumed to be derived with Ito calculus.
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
%   matrix multiplies the noise coefficicents by the (mx1) noise terms
%   in dW(t) to obtain an (nx1) column vector.
%
%   Solver-specific options are passed via the OPTIONS struct, of which,
%   only the NOISESOURCES field is mandatory.
%
%   OPTIONS =
%      NoiseSources: [m]           number of noise processes in dW
%       InitialStep: [dt]          integrator time step (optional)
%             randn: [mxt]         pre-generated random noise (optional)
%         OutputFcn: @(t,Y,flag)   handle to user-defined output function
%
%   The solution is returned in the SOL struct as per ode45, ode23, etc.
%   Interpolating the solution is possible (using bdEval) but it is not
%   recommended because interpolation of a stochastic process is meaning-
%   less. The values of y(t) and y'(t) can instead be read directly from
%   the struct.
%
%   SOL =
%       x: [1xt]  time points
%       y: [nxt]  y(t) values
%      yp: [nxt]  y'(t) values
%      dW: [mxt]  Weiner noise samples
%
%  The Weiner noise is computed as dW=sqrt(dt)*randn(m,t) where m is
%  the number of Weiner processes (NoiseSources) and t is the number
%  of time points in the solution. The time points [T0:dt:TFINAL]
%  are equi-spaced with dt defined by the INITIALSTEP option. If 
%  INITIALSTEP is undefined then the solver defaults to 101 time steps
%  by setting dt=(TFINAL-T0)/100. 
%
%  Alternatvely, the user may supply pre-computed random samples via the
%  RANDN field of the OPTIONS struct. Those random samples must be drawn
%  from a Normal distribution using the Matlab RANDN(m,t) function. The
%  INITIALSTEP option is ignored becasue the step size dt=(TFINAL-T0)/(t-1)
%  is determined by TSPAN=[T0 TFINAL] and the number of time points (t)
%  in RANDN.
%
%EXAMPLE:
%  % anonymous versions of the F() and G() functions shown above.
%  odefun = @(t,Y,theta,mu,sigma) theta.*(mu - Y);
%  sdefun = @(t,Y,theta,mu,sigma) sigma .* eye(numel(Y));
%  tspan = [0 10];                  % time domain
%  n = 13;                          % number of equations
%  Y0 = ones(n,1);                  % initial conditions
%  options.NoiseSources = n;        % number of noise sources
%  options.InitialStep = 0.01;      % step size, dt
%  theta = 1;                       % model-specific parameter
%  mu = -1;                         % model-specific parameter
%  sigma = 0.5;                     % model-specific parameter
%  sol = sdeIto(odefun,sdefun,tspan,Y0,options,theta,mu,sigma);
%  T = sol.x;                       % solution time points
%  Y = sol.y;                       % solution values y(t)
%  plot(T,Y);                       % plot the results
%
%SEE ALSO
%  SDEdemo1, SDEdemo2 and SDEdemo3 in the Brain Dynamics Toolkit
%
%AUTHORS
%  Matthew Aburn, Stewart Heitmann (2016)
function sol = sdeIto(odefun,sdefun,tspan,y0,options,varargin)
    % Get the number of noise sources (Weiner processes).
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

    % compute the Weiner processes
    if isfield(options,'randn') && ~isempty(options.randn)
        % The user has supplied us with random samples,
        % we only need scale it by sqrt(dt)
        sol.dW = sqrt(dt) .* options.randn;
    else
        % Generate the Weiner noise (scaled by sqrt(dt))
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
        
    % Fixed-step Euler method
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

        % Call the user-supplied functions
        F = odefun(sol.x(indx), sol.y(:,indx), varargin{:});
        G = sdefun(sol.x(indx), sol.y(:,indx), varargin{:});

        % Euler step
        sol.yp(:,indx) = F*dt + G*sol.dW(:,indx);            % dy(t) = F(t,y(t))*dt + G(t,y(t))*dW(t)
        sol.y(:,indx+1) = sol.y(:,indx) + sol.yp(:,indx);    % y(t+1) = y(t) + dy(t)       
    end
    
    % Complete the final Euler step
    F = odefun(sol.x(end), sol.y(:,end), varargin{:});
    G = sdefun(sol.x(end), sol.y(:,end), varargin{:});
    sol.yp(:,end) = F*dt + G*sol.dW(:,end);

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
