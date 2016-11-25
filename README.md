# Brain Dynamics Toolbox
The Brain Dynamics Toolbox is a graphical user interface to the matlab ODE and DDE solvers as well as its own built-in SDE solvers. The toolbox provides a convenient user interface for exploring dynamical systems by forward simulation. Users implement their own dynamical equations (as matlab scripts) and use toolbox GUI application to view interactive phase portraits, time plots, space-time plots, and so on. The plotting tools are modular so that users can create their own custom plots if they wish. The user interface is designed for dynamical systems with large numbers of variables and parameters, as is often the case in dynamical models of the brain. Hence the name, Brain Dynamics Toolbox.
 
The toolbox scripts are located in the `bdtoolkit` directory. The plotting models (panels) are kept separately in the `panels` directory. A selection of pre-defined models can be found in the `models` directory. All of these directories should be in your matlab PATH variable. 

```matlab
    >> addpath bdtoolkit
    >> addpath bdtoolkit/panels
    >> addpath bdtoolkit/models
```

The `bdtoolkit/testcode` directory contains test code for developers. It can be ignored.

## How it works
The brain dynamics toolkit uses the Matlab ODE and DDE solvers to integrate (solve) a set of dynamical equations provided by the user. The user supplies the right hand side of the dynamical equation as a function in the same way they do for `ode45`. The difference is that the user-supplied function, as well as additional information about the dynamical system (parameter names, variable names, etc), are encapsulated within a special structure known as the *system struct*. It contains everything that the graphic user interface needs to know about the dynamical system. 

A typical system struct has the following fields:

```matlab
    sys.odefun = @odefun;      % Handle to our ODE function
    sys.pardef = {'a',1;       % ODE parameters {'name', value}
                  'b',2};
    sys.vardef = {'y',0};      % ODE variables {'name',value}
    sys.solver = {'ode45',     % matlab solvers
                  'ode23'};
    sys.odeopt = odeset();     % ODE solver options
    sys.tspan = [0 5];         % default time span 
```

The `sys.odefun` field is a function handle to a user-defined function of the form:

```matlab
    % A simple ODE function
    function dYdt = odefun(t,Y,a,b)  
       dYdt = a*Y + b*t;
    end
```


## Models
The Brain Dynamics Toolkit ships with a collection of pre-defined models in the `bdtoolkit/models` directory. Each model is constructed using a matlab script that returns a system struct (sys) which can then be passed to the graphical user interface (bdGUI). Different scripts have different input parameters, so use the matlab HELP function to see how each script should be used. 

```matlab
    >> help ODEdemo1             % get help on using the model
    >> sys = ODEdemo1();         % construct the model as a sys struct
    >> gui = bdGUI(sys);         % pass the model to the toolkit GUI application
```
Pre-defined system structs can also be loaded as 'mat' files from within the bdGUI application using the File-Load menu.

## Panels

Specific plotting tools (panels) are loaded by the GUI in accordance with the contents of the `sys.gui` field in the model's system structure. The field names correspond to the classes defined in the `bdtoolkit/panels` directory. For example, the following snippet tells the bdGUI application to load the `bdTimePortrait`, `bdPhasePortrait` and `bdSolver` panels:

```matlab
	sys.gui.bdTimePortrait = [];
	sys.gui.bdPhasePortrait = [];
	sys.gui.bdSolverPanel = [];
```
Different panel classes expect different field names. Refer to the docmentation for each class. Nonetheless al panel classes typically accept an optional `title` string. 

```matlab
    sys.gui.bdTimePortrait.title = 'Time Portrait';
    sys.gui.bdPhasePortrait.title = 'Phase Portrait';
    sys.gui.bdSolverPanel.title = 'Solver';
```
The `bdLatexPanel` is typically the first panel loaded by each model. It uses latex tp display the relevant mathematical equations. Each line of latex code is defined separately in a cell array that is stored in the `sys.gui.bdLatexPanel.latex` field.   

```matlab
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{ODEdemo1}';
        '';
        'An Ordinary Differential Equation (ODE)';
        '\qquad $\dot Y(t) = a\,Y(t) + b\,t$';
        'where $a$ and $b$ are scalar constants.'};
```

## Useful utilities
The `bdLint` function is a helpful tool for validating the system structure of a new model. It checks that the various fields of the sys struct are properly defined. It also calls the user-defined function handle(s) to verify that they return data in the proper format.
  
The `bdLoadMatrix` function is useful for loading matrix data from a matlab file or importing it from a data file of another format.

The `bdEditVector` and `bdEditMatrix` functions are useful for interactively editing vector and matrix data.

##Author
Stewart Heitmann <heitmann@ego.id.au>

25th Nov 2016
