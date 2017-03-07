# Release Notes for the Brain Dynamics Toolbox.

#### Version 2017a (?? March 2017)
Released in conjuction with the following paper:
*Heitmann, Aburn, Breakspear (2017) The Brain Dynamics Toolbox: An open-source software package for simulating dynamical systems in MATLAB.*

New features include:
(1) The GUI now supports multiple instances of plot panels that can be loaded at run-time via pull-down menus.
(2) Time and Phase portraits now support plot 'hold on/off'.
(3) More flexible syntax for defining system parameters and variables in the *sys* struct.
(4) Automatic validation of *sys* structs at load-time.
(5) System fields *tspan*, *odesolver*, *odeoption*, *ddesolver* and *ddeoption* may now be omitted if the default settings are acceptable.
(6) The set of example models has been substantially revised.
 
Bug fixes include:
(1) interpolation of time in space-time plots.

**This version is not backwards compatible with version 2016a.** In particular: 
(1) *sys.pardef, sys.vardef, sys.auxdef, sys.lagdef* were changed from cell arrays to struct arrays; 
(2) *sys.gui* was renamed *sys.panels*;
(3) SDE function handles were renamed *sys.sdeF* and *sys.sdeG*;
(4) *bdCorrelationPanel* was renamed *bdCorrPanel*;
(5) *bdSpaceTimePortrait* was renamed *bdSpaceTime*;
(6) *odeEuler* was renamed *odeEul*;
(7) *sdeIto* was renamed *sdeEM*;
(8) *sdeStratonovich* was renamed *sdeSH*;
(9) *bdVerify* was renamed *bdSysCheck*;
(10) *bdUtils* was renamed *bd*;
(11) The *gui.control* property was replaced by *gui.sys, gui.sol* and *gui.aux*.

**Important message to users migrating from 2016a to 2017a.** Scripts and sys structures written for 2016a will need to be modified to accommodate the changes above. We highly recommend running *bdSysCheck* on existing system definitions when migrating old code. It will detect obsolete and invalid sys fields and issue helpful warnings. 


#### Version 2016a (24 Dec 2016)
The first public release of the Brain Dynamics Toolbox on GitHub. Requires MATLAB 2014b or newer.

