function sol = dde23a(ddefun,lags,history,tspan,options,varargin) 
%DDE23a  A faster version of dde23.
%   This is a pre-release version of dde23 from Mathworks Inc. It includes
%   bug fixes that improve the computational cost of computing time delays.
%   It will be likely be included in MATLAB R2017a (or later).
%
%   SOL = DDE23(DDEFUN,LAGS,HISTORY,TSPAN) integrates a system of DDEs 
%   y'(t) = f(t,y(t),y(t - tau_1),...,y(t - tau_k)). The constant, positive 
%   delays tau_1,...,tau_k are input as the vector LAGS. DDEFUN is a function 
%   handle. DDEFUN(T,Y,Z) must return a column vector corresponding to 
%   f(t,y(t),y(t - tau_1),...,y(t - tau_k)). In the call to DDEFUN, a scalar T 
%   is the current t, a column vector Y approximates y(t), and a column Z(:,j) 
%   approximates y(t - tau_j) for delay tau_j = LAGS(J).  The DDEs are 
%   integrated from T0=TSPAN(1) to TF=TSPAN(end) where T0 < TF. The solution 
%   at t <= T0 is specified by HISTORY in one of three ways: HISTORY can be 
%   a function handle, where for a scalar T, HISTORY(T) returns a column 
%   vector y(t). If y(t) is constant, HISTORY can be this column vector. 
%   If this call to DDE23 continues a previous integration to T0, HISTORY 
%   can be the solution SOL from that call.
%
%   DDE23 produces a solution that is continuous on [T0,TF]. The solution is
%   evaluated at points TINT using the output SOL of DDE23 and the function
%   DEVAL: YINT = DEVAL(SOL,TINT). The output SOL is a structure with 
%       SOL.x  -- mesh selected by DDE23
%       SOL.y  -- approximation to y(t) at the mesh points of SOL.x
%       SOL.yp -- approximation to y'(t) at the mesh points of SOL.x
%       SOL.solver -- 'dde23'
%
%   SOL = DDE23(DDEFUN,LAGS,HISTORY,TSPAN,OPTIONS) solves as above with default
%   parameters replaced by values in OPTIONS, a structure created with the
%   DDESET function. See DDESET for details. Commonly used options are
%   scalar relative error tolerance 'RelTol' (1e-3 by default) and vector of
%   absolute error tolerances 'AbsTol' (all components 1e-6 by default).
%
%   DDE23 can solve problems with discontinuities in the solution prior to T0
%   (the history) or discontinuities in coefficients of the equations at known
%   values of t after T0 if the locations of these discontinuities are
%   provided in a vector as the value of the 'Jumps' option.
%
%   By default the initial value of the solution is the value returned by
%   HISTORY at T0. A different initial value can be supplied as the value of
%   the 'InitialY' property. 
%
%   With the 'Events' property in OPTIONS set to a function handle EVENTS, 
%   DDE23 solves as above while also finding where event functions 
%   g(t,y(t),y(t - tau_1),...,y(t - tau_k)) are zero. For each function 
%   you specify whether the integration is to terminate at a zero and whether 
%   the direction of the zero crossing matters. These are the three column 
%   vectors returned by EVENTS: [VALUE,ISTERMINAL,DIRECTION] = EVENTS(T,Y,Z). 
%   For the I-th event function: VALUE(I) is the value of the function, 
%   ISTERMINAL(I) = 1 if the integration is to terminate at a zero of this 
%   event function and 0 otherwise. DIRECTION(I) = 0 if all zeros are to
%   be computed (the default), +1 if only zeros where the event function is
%   increasing, and -1 if only zeros where the event function is decreasing. 
%   The field SOL.xe is a row vector of times at which events occur. Columns
%   of SOL.ye are the corresponding solutions, and indices in vector SOL.ie
%   specify which event occurred.   
%   
%   Example    
%         sol = dde23(@ddex1de,[1, 0.2],@ddex1hist,[0, 5]);
%     solves a DDE on the interval [0, 5] with lags 1 and 0.2 and delay
%     differential equations computed by the function ddex1de. The history 
%     is evaluated for t <= 0 by the function ddex1hist. The solution is
%     evaluated at 100 equally spaced points in [0 5]  
%         tint = linspace(0,5);
%         yint = deval(sol,tint);
%     and plotted with 
%         plot(tint,yint);
%     DDEX1 shows how this problem can be coded using subfunctions. For
%     another example see DDEX2.  
%
%   Class support for inputs TSPAN, LAGS, HISTORY, and the result of DDEFUN(T,Y,Z):
%     float: double, single
%
%   See also DDESET, DDEGET, DEVAL.

%   DDE23 tracks discontinuities and integrates with the explicit Runge-Kutta
%   (2,3) pair and interpolant of ODE23. It uses iteration to take steps
%   longer than the lags.

%   Details are to be found in Solving DDEs in MATLAB, L.F. Shampine and
%   S. Thompson, Applied Numerical Mathematics, 37 (2001). 

%   Jacek Kierzenka, Lawrence F. Shampine and Skip Thompson
%   Copyright 1984-2010 The MathWorks, Inc.


solver_name = 'dde23';

% Check inputs
if nargin < 5
  options = [];
  if nargin < 4
    error(message('MATLAB:dde23:NotEnoughInputs'));    
  end
end

% Stats
nsteps   = 0;
nfailed  = 0;
nfevals  = 0; 

t0 = tspan(1);
tfinal = tspan(end);   % Ignore all entries of tspan except first and last.
if tfinal <= t0
  error(message('MATLAB:dde23:TspandEndLTtspan1'))
end

sol.solver = solver_name;
if isnumeric(history)
  temp = history;
  sol.history = history;
elseif isstruct(history)
  if history.x(end) ~= t0
    error(message('MATLAB:dde23:NotContinueFromHistoryEnd'))
  end
  temp = history.y(:,end);
  sol.history = history.history;  
else
  temp = feval(history,t0,varargin{:});
  sol.history = history;
end 
y0 = temp(:);
maxlevel = 4;
initialy = ddeget(options,'InitialY',[],'fast');
if ~isempty(initialy)
  y0 = initialy(:);
  maxlevel = 5;
end   

neq = length(y0);

% If solving a DDE, locate potential discontinuities. We need to step to each of
% the points of potential lack of smoothness. Because we start at t0, we can
% remove it from discont.  The solver always steps to tfinal, so it is
% convenient to add it to discont.
if isempty(lags)
  discont = tfinal;
  minlag = Inf;
else
  lags = lags(:)';
  minlag = min(lags);
  if minlag <= 0
    error(message('MATLAB:dde23:NotPosLags'))
  end
  vl = t0;
  maxlag = max(lags);
  if isstruct(history)
    indices = find( history.discont < (t0 - maxlag) );
    if ~isempty(indices)
      ndex = indices(end);
      sol.discont = history.discont(1:ndex);   
      vl = [history.discont(ndex+1:end) t0];
    end
  end
  jumps = ddeget(options,'Jumps',[],'fast');
  if ~isempty(jumps)
    indices = find( ((t0 - maxlag) <= jumps) & (jumps <= tfinal) );
    if ~isempty(indices)
      jumps = jumps(indices);
      vl = sort([vl jumps(:)']);
      maxlevel = 5;
    end
  end
  discont = vl;
  for level = 2:maxlevel
    vlp1 = vl(1) + lags;
    for i = 2:length(vl)
      vlp1 = [vlp1 (vl(i)+lags)];
    end % Restrict to tspan.
    indices = vlp1 <= tfinal;
    vl = vlp1(indices);
    if isempty(vl)
      break;
    end
    nvl = length(vl);
    if nvl > 1 % Purge duplicates in vl.
      vl = sort(vl);
      indices = find(abs(diff(vl)) <= 10*eps(vl(1:nvl-1))) + 1;
      vl(indices) = [];
    end
    discont = [discont vl];
  end
  if length(discont) > 1
    discont = sort(discont); % Purge duplicates.
    indices = find(abs(diff(discont)) <= 10*eps(discont(1:end-1))) + 1;
    discont(indices) = [];
  end
end
if isstruct(history)
  sol.discont = [history.discont discont];
else
  sol.discont = discont;
end

% Add tfinal to the list of discontinuities if it is not already included.  This
% is a programming convenience and is not added to sol.discont.
if abs(tfinal - discont(end)) <= 10*eps(tfinal)
  discont(end) = tfinal;
else
  discont = [discont tfinal];
end

% Discard t0 and discontinuities in the history.
indices = discont <= t0;
discont(indices) = [];
nextdsc = 1;

% Initialize method parameters.
pow = 1/3;
B = [
    1/2         0               2/9
    0           3/4             1/3
    0           0               4/9
    0           0               0
    ]; 
E = [-5/72; 1/12; 1/9; -1/8];

% Evaluate initial history at t0 - lags.
Z0 = lagvals(t0,lags,history,t0,y0,[],varargin{:});

f0 = feval(ddefun,t0,y0,Z0,varargin{:});
nfevals = nfevals + 1;                  
[m,n] = size(f0);
if n > 1
  error(message('MATLAB:dde23:DDEOutputNotCol'))
elseif m ~= neq
  error(message('MATLAB:dde23:DDELengthMismatchHistory'));
end

% Determine the dominant data type
classT0 = class(t0);
classY0 = class(y0);
classZ0 = class(Z0);   % class y(t0-lags)
classF0 = class(f0);
dataType = superiorfloat(t0,y0,Z0,f0);
if ~( strcmp(classT0,dataType) && strcmp(classY0,dataType) && ...
      strcmp(classZ0,dataType) && strcmp(classF0,dataType))
  warning(message('MATLAB:dde23:InconsistentDataType'));
end    


% Get options, and set defaults.
rtol = ddeget(options,'RelTol',1e-3,'fast');
if (length(rtol) ~= 1) || (rtol <= 0)
  error(message('MATLAB:dde23:OptRelTolNotPosScalar'));
end
if rtol < 100 * eps(dataType) 
  rtol = 100 * eps(dataType);
  warning(message('MATLAB:dde23:RelTolIncrease', sprintf( '%g', rtol )))
end

atol = ddeget(options,'AbsTol',1e-6,'fast');
if any(atol <= 0)
  error(message('MATLAB:dde23:OptAbsTolNotPos'));
end

normcontrol = strcmp(ddeget(options,'NormControl','off','fast'),'on');   

if normcontrol
  if length(atol) ~= 1
    error(message('MATLAB:dde23:NonScalarAbstolNormControl'));
  end
  normy = norm(y0);
else
  if (length(atol) ~= 1) && (length(atol) ~= neq)
    error(message('MATLAB:dde23:AbsTolSize', funstring( ddefun ), neq)); 
  end
  atol = atol(:);
end
threshold = atol / rtol;

% By default, hmax is 1/10 of the interval of integration.
hmax = min(tfinal-t0, ddeget(options,'MaxStep',0.1*(tfinal-t0),'fast'));
if hmax <= 0
  error(message('MATLAB:dde23:OptMaxStepNotPos'));
end

htry = ddeget(options,'InitialStep',[],'fast');
if htry <= 0
  error(message('MATLAB:dde23:OptInitialStepNotPos'));
end

% Allocate storage for output arrays and initialize them.
chunk = min(100,floor((2^13)/neq));

tout = zeros(1,chunk,dataType);
yout = zeros(neq,chunk,dataType);
ypout = zeros(neq,chunk,dataType);

f = zeros(neq,4,dataType);

nout = 1;
tout(nout) = t0;
yout(:,nout) = y0;
ypout(:,nout) = f0;

events = ddeget(options,'Events',[],'fast');
haveeventfun = ~isempty(events);
if haveeventfun
  valt = feval(events,t0,y0,Z0,varargin{:});
end
teout = [];
yeout = [];
ieout = [];

% Handle the output
if nargout > 0
  outputFcn = ddeget(options,'OutputFcn',[],'fast');
else
  outputFcn = ddeget(options,'OutputFcn',@odeplot,'fast');
end
outputArgs = {};  
if isempty(outputFcn)
  haveOutputFcn = false;
else
  haveOutputFcn = true;
  outputs = ddeget(options,'OutputSel',1:neq,'fast');
  outputArgs = varargin;  
end
refine = max(1,ddeget(options,'Refine',1,'fast'));
ntspan = numel(tspan);
if ntspan > 2
  outputAt = 'RequestedPoints';         % output only at tspan points
elseif refine <= 1
  outputAt = 'SolverSteps';             % computed points, no refinement
else
  outputAt = 'RefinedSteps';            % computed points, with refinement
  S = (1:refine-1) / refine;
end
printstats = strcmp(ddeget(options,'Stats','off','fast'),'on');

hmin = 16*eps(t0);
if isempty(htry)
  % Compute an initial step size h using y'(t).
  h = min(hmax, tfinal - t0);
  if normcontrol
    rh = (norm(f0) / max(normy,threshold)) / (0.8 * rtol^pow);
  else
    rh = norm(f0 ./ max(abs(y0),threshold),inf) / (0.8 * rtol^pow);
  end
  if h * rh > 1
    h = 1 / rh;
  end
  h = max(h, hmin);
else
  h = min(hmax, max(hmin, htry));
end
% Make sure that the first step is explicit so that the code can
% properly initialize the interpolant.
h = min(h,0.5*minlag);

% Initialize the output function.
if haveOutputFcn
  feval(outputFcn,[t0 tfinal],y0(outputs),'init',outputArgs{:});
  next = 2;
end

% THE MAIN LOOP
t = t0;
y = y0;
f(:,1) = f0;

done = false;
while ~done
  
  % By default, hmin is a small number such that t+hmin is only slightly
  % different than t.  It might be 0 if t is 0.
  hmin = 16*eps(t);
  h = min(hmax, max(hmin, h));    % couldn't limit h until new hmin
  
  % Adjust step size to hit discontinuity. tfinal = discont(end).
  hitdsc = false;  
  distance = discont(nextdsc) - t;
  if min(1.1*h,hmax) >= distance          % stretch
    h = distance;
    hitdsc = true;
  elseif 2*h >= distance                  % look-ahead
    h = distance/2; 
  end
  if ~hitdsc && (minlag < h) && (h < 2*minlag)
    h = minlag;
  end
  
  % LOOP FOR ADVANCING ONE STEP.
  nofailed = true;                      % no failed attempts
  while true
    hB = h * B;
    t1 = t + 0.5*h;
    t2 = t + 0.75*h;
    tnew = t + h;
    if hitdsc
      tnew = discont(nextdsc);          % hit discontinuity exactly
    end
    h = tnew - t;                       % purify h
          
    % If a lagged argument falls in the current step, we evaluate the
    % formula by iteration. Extrapolation is used for the evaluation 
    % of the history terms in the first iteration and the tnew,ynew,
    % ypnew of the current iteration are used in the evaluation of 
    % these terms in the next iteration.
    if minlag < h
      maxit = 5;
    else
      maxit = 1;
    end
    
%    X =  tout(1:nout);
%    Y =  yout(:,1:nout);   
%    YP = ypout(:,1:nout);
    lagind=find(tout(1:nout)>=tnew-lags(end)-hmax);
    X =  tout(lagind);
    Y =  yout(:,lagind);   
    YP = ypout(:,lagind);
    
    itfail = false;
    for iter = 1:maxit      
      Z = lagvals(t1,lags,history,X,Y,YP,varargin{:});
      f(:,2) = feval(ddefun,t1,y+f*hB(:,1),Z,varargin{:});
      Z = lagvals(t2,lags,history,X,Y,YP,varargin{:});
      f(:,3) = feval(ddefun,t2,y+f*hB(:,2),Z,varargin{:});
      ynew = y + f*hB(:,3);
      Z = lagvals(tnew,lags,history,X,Y,YP,varargin{:});
      f(:,4) = feval(ddefun,tnew,ynew,Z,varargin{:});
      nfevals = nfevals + 3;              
      if maxit > 1 
        if iter > 1
          if normcontrol
            errit = norm(ynew - last_y) /  max(max(normy,norm(ynew)),threshold);
          else
            errit = norm((ynew - last_y) ./  max(max(abs(y),abs(ynew)),threshold),inf);
          end
          if errit <= 0.1*rtol
            break;
          end
        end
        % Use the tentative solution at tnew in the evaluation of the
        % history terms of the next iteration.
        X =  [tout(1:nout) tnew];
        Y =  [yout(:,1:nout) ynew];
        YP = [ypout(:,1:nout) f(:,4)];
        last_y = ynew;
        itfail = (iter == maxit);
      end
    end

    if itfail
      nfailed = nfailed + 1;            
      if h <= hmin
        warning(message('MATLAB:dde23:IntegrationTolNotMet', sprintf( '%e', t ), sprintf( '%e', hmin )));        

        sol = odefinalize(solver_name, sol,...
                          outputFcn, outputArgs,...
                          printstats, [nsteps, nfailed, nfevals],...
                          nout, tout, yout,...
                          haveeventfun, teout, yeout, ieout,...
                          {history,ypout});
        return;        
      else
        h = 0.5*h;
        if h < 2*minlag
          h = minlag;
        end        
        hitdsc = false;
      end
    else   
      % Estimate the error.
      if normcontrol
        normynew = norm(ynew);
        err = h * (norm(f * E) / max(max(normy,normynew),threshold));
      else
        err = h * norm((f * E) ./ max(max(abs(y),abs(ynew)),threshold),inf);
      end

      % Accept the solution only if the weighted error is no more than the
      % tolerance rtol.  Estimate an h that will yield an error of rtol on
      % the next step or the next try at taking this step, as the case may be,
      % and use 0.8 of this value to avoid failures.
      if err > rtol   % Failed step               
        nfailed = nfailed + 1;            
        if h <= hmin
          warning(message('MATLAB:dde23:IntegrationTolNotMet', sprintf( '%e', t ), sprintf( '%e', hmin )));        

          sol = odefinalize(solver_name, sol,...
                            outputFcn, outputArgs,...
                            printstats, [nsteps, nfailed, nfevals],...
                            nout, tout, yout,...
                            haveeventfun, teout, yeout, ieout,...
                            {history,ypout});
          return;
        else 
          if nofailed
            nofailed = false;
            h = max(hmin, h * max(0.5, 0.8*(rtol/err)^pow));
          else
            h = max(hmin, 0.5*h);
          end 
          hitdsc = false;  
        end        
      else      % Successful step
        break  
      end  
    end
  end
  nsteps = nsteps + 1;              

  if haveeventfun
    X =  [tout(1:nout) tnew];
    Y =  [yout(:,1:nout) ynew];
    YP = [ypout(:,1:nout) f(:,4)]; 
    eventargs = [{events,lags,history,X,Y,YP},varargin];
    [te,ye,ie,valt,stop] = odezero(@ntrp3h,@events_aux,eventargs,valt,...
         X(end-1),Y(:,end-1),X(end),Y(:,end),X(1),YP(:,end-1),YP(:,end));

    if ~isempty(te)
      teout = [teout, te];
      yeout = [yeout, ye];
      ieout = [ieout, ie];
      if stop 
        % Stop on a terminal event after the initial point.
        % Make the output arrays end there.  Must compute
        % the slope to obtain the same interpolant for the
        % shorter step.
        [~,f(:,4)] = ntrp3h(te(end),X(end-1),Y(:,end-1),X(:,end),Y(:,end),...
               	                 YP(:,end-1),YP(:,end));
                      
        tnew = te(end);
        ynew = ye(:,end);
        done = true;
      end
    end
  end
  
  % Store the output
  nout = nout + 1;
  if nout > length(tout)
    tout  = [tout zeros(1,chunk,dataType)];
    yout  = [yout zeros(neq,chunk,dataType)];
    ypout = [ypout zeros(neq,chunk,dataType)];
  end
  tout(nout) = tnew;
  yout(:,nout) = ynew;
  ypout(:,nout) = f(:,4); 

  if haveOutputFcn
    switch outputAt
     case 'SolverSteps'        % computed points, no refinement
      nout_new = 1;
      tout_new = tnew;
      yout_new = ynew;
     case 'RefinedSteps'       % computed points, with refinement
      tref = t + (tnew-t)*S;
      nout_new = refine;
      tout_new = [tref, tnew];
      yout_new = [ntrp3h(tref,t,y,tnew,ynew,f(:,1),f(:,4)), ynew];
     case 'RequestedPoints'    % output only at tspan points
      nout_new =  0;
      tout_new = [];
      yout_new = [];
      while next <= ntspan  
        if tnew < tspan(next)
          if haveeventfun && stop     % output tstop,ystop
            nout_new = nout_new + 1;
            tout_new = [tout_new, tnew];
            yout_new = [yout_new, ynew];            
          end
          break;
        end
        nout_new = nout_new + 1;              
        tout_new = [tout_new, tspan(next)];
        if tspan(next) == tnew
          yout_new = [yout_new, ynew];            
        else 
          yout_new = [yout_new, ntrp3h(tspan(next),t,y,tnew,ynew,f(:,1),f(:,4))];
        end
        next = next + 1;
      end
    end
    if nout_new > 0
      stop = feval(outputFcn,tout_new,yout_new(outputs,:),'',outputArgs{:});
      if stop  % Stop per user request.
        done = true;
      end
    end
  end
    
  if ~done
    % Have we hit tfinal = discont(end)?
    if hitdsc
      nextdsc = nextdsc + 1;
      done = nextdsc > length(discont);
    end
    if ~done
      % Advance the integration one step.
      t = tnew;
      y = ynew;
      if normcontrol
        normy = normynew;
      end
      f(:,1) = f(:,4);                      % BS(2,3) is FSAL.
      
      % If there were no failures, compute a new h.
      if nofailed && ~itfail
        % Note that h may shrink by 0.8, and that err may be 0.
        temp = 1.25*(err/rtol)^pow;
        if temp > 0.2
          h = h / temp;
        else
          h = 5*h;
        end
        h = min(max(hmin,h),hmax);
      end
      
    end
    
  end
  
end

% Successful integration
sol = odefinalize(solver_name, sol,...
                  outputFcn, outputArgs,...
                  printstats, [nsteps, nfailed, nfevals],...
                  nout, tout, yout,...
                  haveeventfun, teout, yeout, ieout,...
                  {history,ypout});

% --------------------------------------------------------------------------

function Z = lagvals(tnow,lags,history,X,Y,YP,varargin)
% For each I, Z(:,I) is the solution corresponding to TNOW - LAGS(I).
% This solution can be computed in several ways: the initial history,
% interpolation of the computed solution, extrapolation of the computed
% solution, interpolation of the computed solution plus the tentative
% solution at the end of the current step.  The various ways are set
% in the calling program when X,Y,YP are formed.

% No lags corresponds to an ODE.
if isempty(lags)
  Z = [];
  return;
end

% Typically there are few lags, so it is reasonable to process 
% them one at a time.  NOTE that the lags may not be ordered and 
% that it is necessary to preserve their order in Z.
xint = tnow - lags;
Nxint = length(xint);
if isstruct(history)
  given_history = history.history;
  tstart = history.x(1);
  neq = length(history.y(:,1));
else
  neq = length(Y(:,1));
end

if isnumeric(history)
  Z = zeros(neq,Nxint,class(history));
else
  Z = zeros(neq,Nxint,class(Y));
end

for j = 1:Nxint
  if xint(j) < X(1)
    if isnumeric(history)
      temp = history;
    elseif isstruct(history)
      % Is xint(j) in the given history?          
      if xint(j) < tstart
        if isnumeric(given_history)
          temp = given_history;
        else
          temp = feval(given_history,xint(j),varargin{:});
        end
      else    
        % Evaluate computed history by interpolation. Mute unwanted warning.
        ws = warning('off','MATLAB:deval:NonuniqueSolution');
        temp = deval(history,xint(j));
        warning(ws);
      end
    else
      temp = feval(history,xint(j),varargin{:});
    end
    Z(:,j) = temp(:); 
  else
    % Find n for which X(n) <= xint(j) <= X(n+1).  xint(j) bigger
    % than X(end) are evaluated by extrapolation, so n = end-1 then.
    indices = find(xint(j) >= X(1:end-1));
    n = indices(end);
    Z(:,j) = ntrp3h(xint(j),X(n),Y(:,n),X(n+1),Y(:,n+1),YP(:,n),YP(:,n+1));
  end 
end

%---------------------------------------------------------------------------

function [vtry,isterminal,direction] = events_aux(ttry,ytry,eventfun,...
                                         lags,history,X,Y,YP,varargin)
% Auxiliary function used by ODEZERO to detect events.
Z = lagvals(ttry,lags,history,X,Y,YP,varargin{:});
[vtry,isterminal,direction] = feval(eventfun,ttry,ytry,Z,varargin{:});


function [yint,ypint] = ntrp3h(tint,t,y,tnew,ynew,yp,ypnew)
%NTRP3H  Interpolation helper function for BVP4C, DDE23, DDESD, and DDENSD.
%   YINT = NTRP3H(TINT,T,Y,TNEW,YNEW,YP,YPNEW) evaluates the Hermite cubic
%   interpolant at time TINT. TINT may be a scalar or a row vector.   
%   [YINT,YPINT] = NTRP3H(TINT,T,Y,TNEW,YNEW,YP,YPNEW) returns also the
%   derivative of the interpolating polynomial. 
%   
%   See also BVP4C, DDE23, DDESD, DDENSD, DEVAL.

%   Jacek Kierzenka and Lawrence F. Shampine
%   Copyright 1984-2005 The MathWorks, Inc.

h = tnew - t;
s = (tint - t)/h;
s2 = s .* s;
s3 = s .* s2;
slope = (ynew - y)/h;
c = 3*slope - 2*yp - ypnew;
d = yp + ypnew - 2*slope;
yint = y(:,ones(size(tint))) + (h*d*s3 + h*c*s2 + h*yp*s);        
if nargout > 1
  ypint = yp(:,ones(size(tint))) + (3*d*s2 + 2*c*s);  
end


function solver_output = odefinalize(solver, sol,...
                                     outfun, outargs,...
                                     printstats, statvect,...
                                     nout, tout, yout,...
                                     haveeventfun, teout, yeout, ieout,...
                                     interp_data)
%ODEFINALIZE Helper function called by ODE solvers at the end of integration.
%
%   See also ODE113, ODE15I, ODE15S, ODE23, ODE23S, 
%            ODE23T, ODE23TB, ODE45, DDE23, DDESD.

%   Jacek Kierzenka
%   Copyright 1984-2005 The MathWorks, Inc.

if ~isempty(outfun)
  feval(outfun,[],[],'done',outargs{:});
end

% Return more stats for implicit solvers: ODE15i, ODE15s, ODE23s, ODE23t, ODE23tb
fullstats = (length(statvect) > 3);  % faster than 'switch' or 'ismember'

stats = struct('nsteps',statvect(1),'nfailed',statvect(2),'nfevals',statvect(3)); 
if fullstats
  stats.npds     = statvect(4);
  stats.ndecomps = statvect(5);
  stats.nsolves  = statvect(6);  
else 
  statvect(4:6) = 0;   % Backwards compatibility
end  

if printstats
  fprintf(getString(message('MATLAB:odefinalize:LogSuccessfulSteps', sprintf('%g',stats.nsteps))));
  fprintf(getString(message('MATLAB:odefinalize:LogFailedAttempts', sprintf('%g',stats.nfailed))));
  fprintf(getString(message('MATLAB:odefinalize:LogFunctionEvaluations', sprintf('%g',stats.nfevals))));
  if fullstats
    fprintf(getString(message('MATLAB:odefinalize:LogPartialDerivatives', sprintf('%g',stats.npds))));
    fprintf(getString(message('MATLAB:odefinalize:LogLUDecompositions', sprintf('%g',stats.ndecomps))));
    fprintf(getString(message('MATLAB:odefinalize:LogSolutionsOfLinearSystems', sprintf('%g',stats.nsolves))));
  end
end

solver_output = {};

if (nout > 0) % produce output
  if isempty(sol) % output [t,y,...]
    solver_output{1} = tout(1:nout).';
    solver_output{2} = yout(:,1:nout).';
    if haveeventfun
      solver_output{3} = teout.';
      solver_output{4} = yeout.';
      solver_output{5} = ieout.';
    end
    solver_output{end+1} = statvect(:);  % Column vector
  else % output sol  
    % Add remaining fields
    sol.x = tout(1:nout);
    sol.y = yout(:,1:nout);
    if haveeventfun
      sol.xe = teout;
      sol.ye = yeout;
      sol.ie = ieout;
    end
    sol.stats = stats;
    switch solver
     case {'dde23','ddesd'}
      [history,ypout] = deal(interp_data{:});
      sol.yp = ypout(:,1:nout);
      if isstruct(history)
        sol.x = [history.x sol.x];
        sol.y = [history.y sol.y];
        sol.yp = [history.yp sol.yp];
        if isfield(history,'xe')
          if isfield(sol,'xe')
            sol.xe = [history.xe sol.xe];
            sol.ye = [history.ye sol.ye];
            sol.ie = [history.ie sol.ie];
          else
            sol.xe = history.xe;
            sol.ye = history.ye;
            sol.ie = history.ie;
          end
        end
      end
     case 'ode45'
      [f3d,idxNonNegative] = deal(interp_data{:});
      sol.idata.f3d = f3d(:,:,1:nout);      
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode15s'      
      [kvec,dif3d,idxNonNegative] = deal(interp_data{:});
      sol.idata.kvec = kvec(1:nout);
      maxkvec = max(sol.idata.kvec);
      sol.idata.dif3d = dif3d(:,1:maxkvec+2,1:nout);
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode113'
      [klastvec,phi3d,psi2d,idxNonNegative] = deal(interp_data{:});
      sol.idata.klastvec = klastvec(1:nout);
      kmax = max(sol.idata.klastvec);
      sol.idata.phi3d = phi3d(:,1:kmax+1,1:nout);
      sol.idata.psi2d = psi2d(1:kmax,1:nout);
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode23'
      [f3d,idxNonNegative] = deal(interp_data{:});
      sol.idata.f3d = f3d(:,:,1:nout);      
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode23s'
      [k1data,k2data] = deal(interp_data{:});
      sol.idata.k1 = k1data(:,1:nout);
      sol.idata.k2 = k2data(:,1:nout);
     case 'ode23t'
      [zdata,znewdata,idxNonNegative] = deal(interp_data{:});
      sol.idata.z = zdata(:,1:nout);
      sol.idata.znew = znewdata(:,1:nout);      
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode23tb'
      [t2data,y2data,idxNonNegative] = deal(interp_data{:});
      sol.idata.t2 = t2data(1:nout);
      sol.idata.y2 = y2data(:,1:nout);           
      sol.idata.idxNonNegative = idxNonNegative;
     case 'ode15i'      
      [kvec,ypfinal] = deal(interp_data{:});
      sol.idata.kvec = kvec(1:nout);
      sol.extdata.ypfinal = ypfinal;
     otherwise
      error(message('MATLAB:odefinalize:UnrecognizedSolver', solver));
    end  
    if strcmp(solver,'dde23') || strcmp(solver,'ddesd')
      solver_output = sol;
    else  
      solver_output{1} = sol;
    end  
  end
end    


