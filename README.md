# Brain Dynamics Toolbox
The Brain Dynamics Toolbox is a graphical user interface to the matlab ODE and DDE solvers. It also has an in-built SDE solver. The toolbox provides a convenient user interface for exploring dynamical systems by forward simulation. Users implement their own dynamical equations (as matlab scripts) and use toolbox GUI application to view interactive phase portraits, time plots, space-time plots, and so on. The plotting tools are modular so that users can create their own custom plots if they wish. The user interface is designed for dynamical systems with large numbers of variables and parameters, as is often the case in dynamical models of the brain. Hence the name, Brain Dynamics Toolbox.
 
The toolbox scripts are located in the bdtoolkit directory. Various mathematical models (ODEs, DDEs, SDEs) are located in the models directory. Both of these directories should be in your matlab PATH variable. 

```matlab
    >> addpath bdtoolkit
    >> addpath bdtoolkit/models
```

The testcode directory contains test code for developers only and can be ignored.

## How it works
The brain dynamics toolkit uses the Matlab ODE and DDE solvers to integrate (solve) a set of dynamical equations provided by the user. The user supplies the right hand side of the dynamical equation as a function in the same way as for ode45, ode23, dde23, etc. A handle to that function, as well as additional information about the dynamical system (parameter names, variable names, etc) are passed to the toolkit GUI application within a special struct known as the ‘system’ struct. It encapsulates everything that the GUI application needs to know about the dynamical system. 

A typical system struct has the following fields

```matlab
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'a',1;                % ODE parameters {'name', value}
                  'b',2};
    sys.vardef = {'y',0};               % ODE variables {'name',value}
    sys.solver = {'ode45','ode23'};     % pertinent matlab ODE solvers
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 5];                  % default time span  
```

where the ODE function is defined as

```matlab
    function dYdt = odefun(t,Y,a,b)  
       dYdt = a*Y + b*t;
    end
```
  
See the `ODEdemo1` function for more about this particular example. You can run it as follows:

```matlab
    >> help ODEdemo1             % get help on using the model
    >> sys = ODEdemo1();         % construct the model as a sys struct
    >> gui = bdGUI(sys);         % pass the model to the toolkit GUI application
```


## Models
A collection of pre-defined models are supplied in the models directory. Each is a function that returns a `sys` struct that the caller must pass to the `bdGUI` function. Different models have different input parameters, so use the matlab HELP function to see how to use each one.


## Useful utilities
The `bdLint(sys)` function is a helpful tool for validating a new model. It checks that the various fields of the sys struct are properly defined. It also calls the user-defined function handle(s) to verify that they return data in the proper format.
  
The `bdLoadMatrix` function is useful for loading matrix data from a matlab file or importing it from a data file of another format.

The `bdEditVector` and `bdEditMatrix` functions are useful for interactively editing vector and matrix data.


## User-defined plots
Users can implement their own plot classes but this is an advanced topic that is beyond the scope of this readme. See the bdTimePortrait class for an example.

 
## Disclaimer
This is a work in progress, so some functionality is still missing.


Stewart Heitmann heitmann@ego.id.au
2nd Nov 2016
