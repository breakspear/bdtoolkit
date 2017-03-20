# Release Notes
# Brain Dynamics Toolbox

## Version 2017a
Released ??? March 2017.

Requires Matlab 2014b or newer.

Major new features:
(1) Dynamic loading of GUI plot panels.
(2) Enhanced GUI class properties allow the solver output and panel objects to be accessed directly. 
(3) New *sys* struct has a more flexible syntax for defining system parameters and variables.
(4) Improved validation of *sys* structs.
(6) Time and Phase portraits now support graphic hold.
(7) All example models have been revised.
 
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
(11) The *gui.control* property was replaced by *gui.sys, gui.sol* and *gui.sox*.
(12) The *sys* fields *tspan*, *odesolver*, *odeoption*, *ddesolver* and *ddeoption* are no longer mandatory.

**Important message to users migrating from 2016a to 2017a.** Scripts written for 2016a will need to be modified to accommodate the changes above. We recommend using *bdSysCheck* when migrating old code. It will quickly detect obsolete and invalid fields in existing *sys* structures. 

## Version 2016a
Released 24 Dec 2016.

Requires Matlab 2014b or newer.

First public release of The Brain Dynamics Toolbox.

