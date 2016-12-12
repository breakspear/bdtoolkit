%sde00  Solve stochastic differential equations using the fixed-step Euler method.
function sol = sde00(odefun,sdefun,tspan,y0,options,varargin)
    % The InitialStep option defines our time step
    dt = odeget(options,'InitialStep');
    if isempty(dt)
        % Default InitialStep
        dt = (tspan(end) - tspan(1))/100;
        %warning('Step size is undefined. Using InitialStep=%g',dt);
    end
    
    % precompute srqt(dt)
    sqrtdt = sqrt(dt);

    % span the time domain in fixed steps
    sol.x = tspan(1):dt:tspan(end);
    tcount = numel(sol.x);

    % allocate space for the results
    sol.y = NaN(numel(y0),tcount);      % values of y(t)
    sol.yp = sol.y;                     % values of dy(t)/dt

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
    sol.yp(:,1) = odefun(sol.x(1), y0, varargin{:})*dt + sdefun(sol.x(1), y0, varargin{:})*sqrtdt;
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
        sol.yp(:,indx) = F*dt + sqrtdt*G;                         % y'(t) = F()*dt + G*sqrt(dt)
        sol.y(:,indx) = sol.y(:,indx-1) + sol.yp(:,indx);         % y(t) = y(t-1) + y'(t)       
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
