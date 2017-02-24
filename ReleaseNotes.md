# Release Notes for the Brain Dynamics Toolbox.

#### Version 2017a (?? March 2017)
Released in conjuction with the following paper:
*Heitmann, Aburn, Breakspear (2017) The Brain Dynamics Toolbox: An open-source software package for simulating dynamical systems in MATLAB.*

New features include:
(1) More flexible syntax for defining system parameters and variables.
(2) Automatic validation of *sys* structs at load-time.
(3) System fields *tspan*, *odesolver*, *odeoption*, *ddesolver*, *ddeoption*, *sdesolver*, *sdeoption* may now be omitted if the default settings are acceptable.
(4) Revised set of example models.
 
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
(9) *bdVerify* was renamed *bdSysCheck*.

**Important message to users migrating from 2016a to 2017a.** Sys structs created for 2016a will need to be modified to accommodate the changes above. It is recommended that *bdSysCheck* be used to assist the migration prcocess. It will detect obsolete fields in sys structs.


#### Version 2016a (24 Dec 2016)
The first public release of the Brain Dynamics Toolbox on GitHub. Requires MATLAB 2014b or newer.

