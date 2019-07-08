% Demonstration script showing how to use the command line tools to run
% the LinearODE example model without the graphical user interface. 
% This script corresponds to Listing 7.1 in the Handbook for the Brain
% Dynamics Toolbox (Version 2018a).

% Ensure that the toolbox scripts are in the MATLAB path
assert(exist('bdSolve.m','file')==2,'ERROR: Ensure the bdtoolkit installation directory is in your MATLAB PATH');
assert(exist('LinearODE.m','file')==2,'ERROR: Ensure the bdtoolkit/models directory is in your MATLAB PATH');

% Construct the sys struct for the LinearODE model.
disp('Constructing the LinearODE model');
sys = LinearODE();

% set ODE parameters a=1, b=-1, c=10, d=-2 
disp('Configuring the parameters');
sys = bdSetPar(sys,'a',1);
sys = bdSetPar(sys,'b',-1);
sys = bdSetPar(sys,'c',10);
sys = bdSetPar(sys,'d',-2);

% set ODE variables x and y to random initial conditions 
disp('Configuring the initial conditions');
sys = bdSetVar(sys,'x',rand);
sys = bdSetVar(sys,'y',rand);

% integrate from t=0 to t=10 using the ode45 solver
disp('Calling the solver');
tspan = [0 10];
sol = bdSolve(sys,tspan,@ode45);

% interpolate the results
disp('Interpolating the solution');
tplot = 0:0.1:10;              % time domain for plotting
Y = bdEval(sol,tplot);         % interpolate the solution

% plot the result
disp('Plotting the results');
plot(tplot,Y);
xlabel('time');
ylabel('x,y');
