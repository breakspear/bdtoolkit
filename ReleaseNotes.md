# Release Notes
# Brain Dynamics Toolbox

## Version 2018a
Released 20 Mar 2018.

This release is a major overhaul of the graphical user interface and the design of the display panel classes. Notable additions are slider controls and the capability to evolve the initial conditions to follow a solution in paramater space. Bifurcation plots and Auxiliary panels have also been added. The auxiliary panel replaces the old auxiliary variables.

## Version 2017c
Released 16 Nov 2017.

This release coincides with the first edition of the Handbook of the Brain Dynamics Toolbox.
New features of the toolbox include:
(i) Improved dialog boxes for editing vector and matrix parameters.
(ii) The ability to load previously computed solutions into the GUI at startup.
(iii) Improved error handling for systems with missing functions.
(iv) The inclusion of the Liley neural-mass model (DFCL2009) from Dafilis, Frascoli Cadusch & Liley (2009).
(v)  Improved license checking in the Hilbert and Correlation panels.
(vi) Improved scrolling in the System-Save dialog box.
(vii) Replacement of the BTF2003ODE model (Breakspear, Terry & Friston, 2003) with BTF2003.
(viii) Bug fixes to the existing BTF2003SDE and BTF2003DDE models.
(iix) Renaming of the MultiplicativeNoise model to KloedenPlaten446.

Requires Matlab 2014b or newer.

## Version 2017b
Released 21 June 2017. 

Major new features include:
(i) Equation parameters and variables can now be directly manipulated from the workspace via the new bdGUI class properties (par, var0, var, lag, t).
(ii) The System-Save menu now includes solution variables and display panel outputs.
(iii) Three new display panels were added (bdHilbert, bdSurrogate, bdTrapPanel).
(iv) Six new models were added (BTF2003ODE, BTF2003DDE, BTF2003SDE, FRRB2012, FRRB2012b, RFB2017).
(v) Scrollbars were added to the Equations panel. (vi) All panels were refined to make their outputs more accessible to the workspace.

Requires Matlab 2014b or newer.

## Version 2017a
Released 21 March 2017.

Major new features include:
(i) Dynamic loading of GUI plot panels.
(ii) Enhanced GUI class properties allow the solver output and panel objects to be accessed directly. 
(iii) New *sys* struct fromat with more flexible syntax for defining system parameters and variables.
(iv) Improved validation of *sys* structs.
(v) Time and Phase portraits now support graphic hold.
(vi) All example models have been revised.
 
**This version is not backwards compatible with version 2016a.** In particular: 
(i) *sys.pardef, sys.vardef, sys.auxdef, sys.lagdef* were changed from cell arrays to struct arrays; 
(ii) *sys.gui* was renamed *sys.panels*;
(iii) SDE function handles were renamed *sys.sdeF* and *sys.sdeG*;
(iv) *bdCorrelationPanel* was renamed *bdCorrPanel*;
(v) *bdSpaceTimePortrait* was renamed *bdSpaceTime*;
(vi) *odeEuler* was renamed *odeEul*;
(vii) *sdeIto* was renamed *sdeEM*;
(viii) *sdeStratonovich* was renamed *sdeSH*;
(ix) *bdVerify* was renamed *bdSysCheck*;
(x) *bdUtils* was renamed *bd*;
(xi) The *gui.control* property was replaced by *gui.sys, gui.sol* and *gui.sox*;
(xii) The *sys* fields *tspan*, *odesolver*, *odeoption*, *ddesolver* and *ddeoption* are no longer mandatory.

**Important message to users migrating from 2016a to 2017a.** Scripts written for 2016a will need to be modified to accommodate the changes above. We recommend using *bdSysCheck* when migrating old code. It detects obsolete and invalid *sys* fields. 

Requires Matlab 2014b or newer.


## Version 2016a
Released 24 Dec 2016.

The first public release of the Brain Dynamics Toolbox.

Requires Matlab 2014b or newer.

