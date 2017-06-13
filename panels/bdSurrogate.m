classdef bdSurrogate < handle
    %bdSurrogate  Brain Dynamics Toolbox panel for Surrogate data transform.
    %   This class constructs phase-randomized surrogate data from
    %   simulated data by adding random numbers to the phase component of
    %   the data using an amplitude-adjusted algorithm. 
    %   
    %SYS OPTIONS
    %   sys.panels.bdSurrogate.title = 'Surrogate'
    %   sys.panels.bdSurrogate.grid = false
    %   sys.panels.bdSurrogate.hold = false
    %
    %AUTHORS
    %  Stewart Heitmann (2017b)
    %  Michael Breakspear (2017b)

    % Copyright (C) 2017 QIMR Berghofer Medical Research Institute
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions
    % are met:
    %
    % 1. Redistributions of source code must retain the above copyright
    %    notice, this list of conditions and the following disclaimer.
    % 
    % 2. Redistributions in binary form must reproduce the above copyright
    %    notice, this list of conditions and the following disclaimer in
    %    the documentation and/or other materials provided with the
    %    distribution.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    % "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    % LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    % FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    % INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    % BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    % LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    % CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    % ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.
    properties (Access=public)
        t               % time scale of phase plot
        y               % time series of selected variable(s)
        ysurr           % surrogate version of y
    end
    
    properties (Access=private) 
        fig             % handle to parent figure
        tab             % handle to uitab object
        ax1             % handle to plot 1 axes
        ax2             % handle to plot 2 axes
        popup1          % handle to popup selector 1
        varMap          % maps entries in vardef to rows in sol.y
        auxMap          % maps entries in auxdef to rows in sal
        solMap          % maps rows in sol.y to entries in vardef
        soxMap          % maps rows in sox.y to entries in auxdef
        listener        % handle to listener
        gridflag        % grid menu flag
        holdflag        % hold menu flag
        autolimflag     % auto limits menu flag        
    end
    
    methods
        function this = bdSurrogate(tabgroup,control)
            % Construct a new tab panel in the parent tabgroup.
            % Usage:
            %    bdSurrogate(tabgroup,control)
            % where 
            %    tabgroup is a handle to the parent uitabgroup object.
            %    control is a handle to the GUI control panel.

            % apply default settings to sys.panels.bdSurrogate
            control.sys.panels.bdSurrogate = bdSurrogate.syscheck(control.sys);
            
            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');
            
            % map vardef entries to rows in sol
            this.varMap = bd.varMap(control.sys.vardef);
            this.solMap = bd.solMap(control.sys.vardef);
            if isfield(control.sys,'auxdef')
                % map auxdef entries to rows in sal
                this.auxMap = bd.varMap(control.sys.auxdef);
                this.soxMap = bd.solMap(control.sys.auxdef);
            else
                % construct empty maps
                this.auxMap = bd.varMap([]);
                this.soxMap = bd.solMap([]);
            end
            
            % number of entries in vardef
            nvardef = numel(control.sys.vardef);
                        
            % construct the uitab
            this.tab = uitab(tabgroup, ...
                'title',control.sys.panels.bdSurrogate.title, ...
                'Tag','bdSurrogateTab', ...
                'Units','pixels', ...
                'TooltipString','Right click for menu');
            
            % get tab geometry
            parentw = this.tab.Position(3);
            parenth = this.tab.Position(4);

            % plot axes 1
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 100 + posh;
            this.ax1 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            hold(this.ax1,'on');
      
            % plot axes 2
            posw = parentw-65;
            posh = (parenth-120)/2;
            posx = 50;
            posy = 80;
            this.ax2 = axes('Parent',this.tab, 'Units','pixels', 'Position',[posx posy posw posh]);           
            hold(this.ax2,'on');
            
            % plot var selector 1
            posx = 10;
            posy = 10;
            posw = 100;
            posh = 20;
            popupval = 1;  
            popuplist = {this.solMap.name, this.soxMap.name};
            this.popup1 = uicontrol('Style','popup', ...
                'String', popuplist, ...
                'Value', popupval, ...
                'Callback', @(~,~) this.selectorCallback(control), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.tab, ...
                'Position',[posx posy posw posh]);
            
            % construct the tab context menu
            this.contextMenu(control);
            
            % register a callback for resizing the panel
            set(this.tab,'SizeChangedFcn', @(~,~) SizeChanged(this,this.tab));
            
            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.render(control));    
        end
        
        % Destructor
        function delete(this)
            delete(this.listener);
            delete(this.tab);          
        end
        
        function render(this,control)
            %disp('bdSurrogate.render()')
            
            % number of entries in sol
            nvardef = numel(this.solMap);
                
            % read the main popup variable selector
            popindx1 = this.popup1.Value;
            
            % if the user selected a variable from vardef then ...
            if popindx1 <= nvardef
                % the popup index corresponds to the row index of sol
                solindx = popindx1; 

                % get detail of the selected variable
                name    = this.solMap(solindx).name;        % name string
                varindx = this.solMap(solindx).varindx;     % index in vardef{}

                % find all rows of sol.y that are related to this vardef entry
                solrows = this.varMap(varindx).solindx;

                % extract the values needed for analysis
                this.t = control.sol.x;
                this.y = control.sol.y(solrows,:);
                
                % index of the variable of interest
                yrow = solindx - solrows(1) + 1;
            else
                % the popup index refers to an entry of sox
                solindx = popindx1 - nvardef;

                % get detail of the selected variable
                name    = this.soxMap(solindx).name;        % name string
                auxindx = this.soxMap(solindx).varindx;     % auxdef index

                % find all rows of aux that are related to this auxdef entry
                solrows = this.auxMap(auxindx).solindx;

                % extract the values needed for analysis
                this.t = control.sox.x;
                this.y = control.sox.y(solrows,:);

                % index of the variable of interest
                yrow = solindx - solrows(1) + 1;
            end
 
            % compute the surrogate data
            this.ysurr = bdSurrogate.ampsurr(this.y);
                        
            % isolate the non-negative time entries
            tindx = find(this.t>=0);
            tt = this.t(tindx);
            yy = this.y(:,tindx);
            ys = this.ysurr(:,tindx);

            % if 'hold' menu is checked then ...
            if this.holdflag
                % Change existing plots on ax1 to thin lines 
                objs = findobj(this.ax1);
                set(objs,'LineWidth',0.5);               
                % Change existing plots on ax2 to thin lines 
                objs = findobj(this.ax2);
                set(objs,'LineWidth',0.5);               
            else
                % Clear the plot axis
                cla(this.ax1);
                cla(this.ax2);
            end
            
            % show gridlines (or not)
            if this.gridflag
                grid(this.ax1,'on');
                grid(this.ax2,'on');
            else
                grid(this.ax1,'off')
                grid(this.ax2,'off')
            end
            
            % Plot the original signal in ax1
            % ... with the background traces in grey
            plot(this.ax1, tt, yy, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax1, tt, yy(yrow,:), 'color','k', 'Linewidth',1.5);
            ylabel(this.ax1,name, 'FontSize',16,'FontWeight','normal');

            % Plot the surrogate signal in ax2
            % ... with the background traces in grey
            plot(this.ax2, tt, ys, 'color',[0.75 0.75 0.75], 'HitTest','off');              
            % ... and variable of interest in black
            plot(this.ax2, tt, ys(yrow,:), 'color','k', 'Linewidth',1.5);
            ylabel(this.ax2,['Surrogate ' name], 'FontSize',16,'FontWeight','normal');
        end        
    end
    
    
    methods (Access=private)

        function contextMenu(this,control)            
            % init the menu flags from the sys.panels options     
            this.gridflag = control.sys.panels.bdSurrogate.grid;
            this.holdflag = control.sys.panels.bdSurrogate.hold;
            
            % grid menu check string
            if this.gridflag
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end
            
            % hold menu check string
            if this.holdflag
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the tab context menu
            this.tab.UIContextMenu = uicontextmenu;

            % construct menu items
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Grid', ...
                   'Checked',gridcheck, ...
                   'Callback', @(menuitem,~) ContextCallback(menuitem) );
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Hold', ...
                   'Checked',holdcheck, ...
                   'Callback', @(menuitem,~) ContextCallback(menuitem) );
            uimenu(this.tab.UIContextMenu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.delete());
        
            % Context Menu Item Callback
            function ContextCallback(menuitem)
                switch menuitem.Label
                    case 'Grid'
                        switch menuitem.Checked
                            case 'on'
                                this.gridflag = false;
                                menuitem.Checked='off';
                            case 'off'
                                this.gridflag = true;
                                menuitem.Checked='on';
                        end
                    case 'Hold'
                        switch menuitem.Checked
                            case 'on'
                                this.holdflag = false;
                                menuitem.Checked='off';
                            case 'off'
                                this.holdflag = true;
                                menuitem.Checked='on';
                        end
                end 
                % redraw this panel
                this.render(control);
            end
        end
        
        % Callback for the "relative phase" checkbox
        function checkboxCallback(this,control)
            if this.checkbox.Value
                set(this.popup2,'Enable','on');
            else
                set(this.popup2,'Enable','off');
            end
            this.render(control);           
        end
                
        % Callback for panel resizing. 
        function SizeChanged(this,parent)
            % get new parent geometry
            parentw = parent.Position(3);
            parenth = parent.Position(4);
            
            % new width, height of each axis
            w = parentw - 65;
            h = (parenth - 110)/2;
            
            % adjust position of ax1
            this.ax1.Position = [50, 100+h, w-15, h];

            % adjust position of ax2
            this.ax2.Position = [50, 50, w-15, h];
        end
        
        % Callback for the plot variable selectors
        function selectorCallback(this,control)
            this.render(control);
        end
        
    end
    
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Surrogate';
            syspanel.grid = false;
            syspanel.hold = false;
            syspanel.autolim = true;
            
            % Nothing more to do if sys.panels.bdSurrogate is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdHilbert')
                return;
            end
            
            % sys.panels.bdSurrogate.title
            if isfield(sys.panels.bdSurrogate,'title')
                syspanel.title = sys.panels.bdSurrogate.title;
            end
            
            % sys.panels.bdSurrogate.grid
            if isfield(sys.panels.bdSurrogate,'grid')
                syspanel.grid = sys.panels.bdSurrogate.grid;
            end
            
            % sys.panels.bdSurrogate.hold
            if isfield(sys.panels.bdSurrogate,'hold')
                syspanel.hold = sys.panels.bdSurrogate.hold;
            end
        end
        
        
        % Creates surrogate multichannel data, by adding random numbers
        % to phase component of all channel data, using amplitude adjusted algorithm
        function y = ampsurr(x)
            [r,c] = size(x);
            if r < c
                x = x.';   % make each column a timeseries
            end;
            [n,cc] = size(x);
            m = 2^nextpow2(n);
            yy=zeros(n,cc);
            for i=1:cc    %create a gaussian timeseries with the same rank-order of x
               z=zeros(n,3); gs=sortrows(randn(n,1),1);
               z(:,1)=x(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=gs; z=sortrows(z,2); yy(:,i)=z(:,3);
            end
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            m = 2^nextpow2(n);
            xx = fft(real(yy),m);
            phsrnd=zeros(m,cc);
            phsrnd(2:m/2,1)=rand(m/2-1,1)*2*pi; phsrnd(m/2+2:m,1)=-phsrnd(m/2:-1:2,1);
            for i=2:cc 
                phsrnd(:,i)=phsrnd(:,1);
            end
            xx = xx.*exp(phsrnd*sqrt(-1));
            xx = ifft(xx,m);
            xx = real(xx(1:n,:));
            y=zeros(n,cc);
            for i=1:cc    %reorder original timeseries to have the same rank-order of xx
               z=zeros(n,3); yst=sortrows(x(:,i));
               z(:,1)=xx(:,i); z(:,2)=[1:n]'; z=sortrows(z,1);
               z(:,3)=yst; z=sortrows(z,2); y(:,i)=z(:,3);
            end
            if r < c
               y = y.';
            end
            y=real(y);    %small imag. component created by rounding error
        end
        
    end
    
end
