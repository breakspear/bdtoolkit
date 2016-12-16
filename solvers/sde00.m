%sde00  Solve stochastic differential equations using the fixed-step Euler method.
%   odefun is a function handle to the determinsitic part of the SDE
%   sdefun is a function handle to the noise coeeficients of the SDE
%   tspan=[t0 t1] is the time span of the integration.
%   dW is an (mxt) vector of preomputed Weiner noise processes (optional)
%   y0 in an (nx1) vector of initial conditions
%   options is a structure of SDE solver options (see sdeset)
%   vargargin represents the additional parameters passed to odefun and sdefun.
function sol = sde00(odefun,sdefun,tspan,y0,options,varargin)
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
    sol.yp(:,1) = odefun(sol.x(1), y0, varargin{:})*dt + sdefun(sol.x(1), y0, varargin{:})*sol.dW(:,1);
    for indx=2:tcount        
        % Execute the OutputFcn whenever the time step reaches the next
        % time point listed in tspan. Ordinarily, there would be multiple
        % Euler steps between calls to OutputFcn. Nonetheless, a single
        % Euler step might (perversely) span multiple time points in tspan.
        % Hence the while loop.
        while ~isempty(OutputFcn) && sol.x(indx-1)>=tspan(tspanidx)
            % call the output function
            status = OutputFcn(sol.x(indx-1),sol.y(:,indx-1),'');
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
        F = odefun(sol.x(indx), sol.y(:,indx-1), varargin{:});
        G = sdefun(sol.x(indx), sol.y(:,indx-1), varargin{:});

        % Euler step
        sol.yp(:,indx) = F*dt + G*sol.dW(:,indx);            % y'(t) = F(t)*dt + G*dW(t)
        sol.y(:,indx) = sol.y(:,indx-1) + sol.yp(:,indx);    % y(t) = y(t-1) + y'(t)       
    end
    
    % Execute the OutputFcn for the last entry in tspan.
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
