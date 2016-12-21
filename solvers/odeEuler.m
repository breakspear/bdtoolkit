%odeEuler  Solve differential equations using the fixed-step Euler method.
function sol = odeEuler(ode,tspan,y0,options,varargin)
    % The InitialStep option defines our time step
    dt = odeget(options,'InitialStep');
    if isempty(dt)
        % Default InitialStep
        dt = (tspan(end) - tspan(1))/100;
        %warning('Step size is undefined. Using InitialStep=%g',dt);
    end

    % span the time domain in fixed steps
    sol.x = tspan(1):dt:tspan(end);
    tcount = numel(sol.x);

    % allocate space for the results
    sol.y = NaN(numel(y0),tcount);      % values of y(t)
    sol.yp = sol.y;                     % values of dy(t)/dt

    % miscellaneous output
    sol.solver = mfilename;
    sol.extdata.odefun = ode;
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
        
        % Euler step
        sol.yp(:,indx) = ode(sol.x(indx), sol.y(:,indx), varargin{:});     % y'(t) = F(t,y(t))
        sol.y(:,indx+1) = sol.y(:,indx) + sol.yp(:,indx) * dt;             % y(t+1) = y(t) + y'(t)*dt       
    end
    
    % Complete the final Euler step
    sol.yp(:,end) = ode(sol.x(end), sol.y(:,end), varargin{:});            % y'(t) = F(t,y(t))
    
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
