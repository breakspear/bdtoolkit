# Brain Dynamics Toolbox

##Version 2017c

The [Brain Dynamics Toolbox](http://bdtoolbox.blogspot.com) provides a convenient graphical user interface for exploring dynamical systems in MATLAB.  Users implement their own dynamical equations (as matlab scripts) and use the toolbox graphical interface to view phase portraits and other plots in real-time. The same models can also be run as MATLAB scripts without the graphics interface. The toolbox includes solvers for Ordinary Differential Equations (ODE), Delay Differential Equations (DDE) and Stochastic Differential Equations (SDE). The plotting tools are modular so that users can create custom plots according to their needs. Custom solver routines can also be included. The user interface is designed for dynamical systems with large numbers of variables and parameters, as is often the case in dynamical models of the brain. Hence the name, *Brain Dynamics Toolbox*.

## Download
Dowload the [bdtoolkit-2017c.zip](https://github.com/breakspear/bdtoolkit/releases/download/2017c/bdtoolkit-2017c.zip) file from the *bdtoolkit* repository on GitHub

## Getting Started
The toolbox requires MATLAB 2014b or newer. Unzip the toolbox files into a directory of your choosing. The main toolbox scripts are located in the *bdtoolkit* directory which must be in your matlab PATH variable. The *bdtoolkit/models* directory contains example scripts that are advisable to have in your PATH too.

```matlab
    $ unzip bdtoolkit-2017c.zip
    $ matlab
    >> addpath bdtoolkit-2017c
    >> addpath bdtoolkit-2017c/models
```
Refer to the *Getting Started* section in the *Handbook for the Brain Dynamics Toolbox* for details.

## Documentation
Heitmann & Breakspear (2017) *Handbook for the Brain Dynamics Toolbox: Version 2017c.* QIMR Berghofer Medical Research Institute. ISBN 9781549720703.

![Handbook Cover Art](CoverArt.png)

##Example Models
* *BrownianMotion* : Geometric Brownian motion.
* *BTF2003* : Neural mass networks with delays and noise (Breakspear, Terry, Friston, 2003)
* *FitzhughNagumo* : FitzHugh-Nagumo neural oscillator.
* *FRRB2012* : Multistable neural oscillators with noise (Freyer, Roberts, Ritter, Breakspear, 2012)
* *DFCL2009* : Neural mass model with chaos (Dafilis, Frascoli, Cadusch, Liley, 2009)
* *HindmarshRose* : Network of Hindmarsh-Rose neurons.
* *HopfieldNet* : Generalised Hopfield Associative Memory Network.
* *KloedenPlaten446* : Ito Stochastic Differential Equation (4.46) from Kloeden and Platen (1992).
* *KuramotoNet* : Network of Kuramoto phase oscillators.
* *LinearODE* : Example of a simple Ordinary Differential Equation.
* *Ornstein Uhlenbeck* : Independent Ornstein-Uhlenbeck stochastic processes.
* *RFB2017* : Neural mass with multiplicative noise (Roberts, Friston,  Breakspear, 2017).
* *SwiftHohenberg1D* : Swift-Hohenberg PDE in one spatial dimension.
* *VanDerPolOscillators* : Network of Van der Pol oscillators.
* *WaveEquation1D* : Wave equation PDE in one spatial dimension.
* *WilleBaker* : Example of a simple Delay Differential Equation.



## BSD License
This software is freely available under the [2-clause BSD license](https://opensource.org/licenses/BSD-2-Clause).

Copyright (C) 2016-2017 QIMR Berghofer Medical Reserach Institute.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Contributors
* Michael Breakspear, Project Leader
* Stewart Heitmann, Project Leader & Lead Developer
* Matthew Aburn

