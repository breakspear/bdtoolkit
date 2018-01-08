classdef (Abstract) bdPanel < handle
    % Base class for display panels in bdGUI.
    
    properties (Access=protected)
        menu                                % handle to the panel's toolbar uimenu
        tab                                 % handle to the panel's uitab
    end

    methods
        
        function this = bdPanel(tabgroup)
            % Constructs a new display panel in the given tabgroup.
            
            % handle to the parent figure
            fig = ancestor(tabgroup,'figure');
            
            % construct an empty menu and make it invisible. 
            this.menu = uimenu('Parent',fig, 'Label','noname', 'Visible','off');
            
            % construct an empty tab
            this.tab = uitab(tabgroup,'title','noname','Unit','pixels');
            
            % associated the menu with this tab
            this.tab.UserData.menu = this.menu;
            
            % ensure the menu for the selected tab (possibly this tab) is visible
            tabgroup.SelectedTab.UserData.menu.Visible = 'on';
        end
               
        % Close the panel
        function close(this)
            disp('bdPanel.close()');
            % Get the tabgroup handle
            tabgroup = this.tab.Parent;
            
            % Delete the toolbar menu and the panel tab
            delete(this.menu);
            delete(this.tab);            
    
            % Reveal the menu of the newly selected tab (if it exists)
            if ~isempty(tabgroup.SelectedTab)
                tabgroup.SelectedTab.UserData.menu.Visible = 'on';
            end
            
            % Delete the panel object itself
            delete(this);
        end    
        
    end
    
    methods (Static)
        % Construct a subpanel where the position is given in normal coordinates
        function [ax,cmenu,spanel] = Subpanel(parent,panelpos,axespos)
            % handle to the parent figure
            fig = ancestor(parent,'figure');

            % Construct the uipanel container
            spanel = uipanel(parent, ...
                        'Units','normal', ...
                        'Position',panelpos, ...
                        'BorderType','beveledout');

            % Construct the axes
            ax = axes('Parent',spanel, ...
                'Units','normal', ...
                'OuterPosition',axespos, ...
                'NextPlot','add', ...
                'Box','on');

            % Define the icon for the menu button
            cdata = ones(10,10,3);
            cdata([1 2 5 6 9 10],:,:) = 0;

            % Construct an empty context menu
            cmenu = uicontextmenu();
            
            % Construct the menu button and attach the context menu to it
            mb = uicontrol(spanel, ...
                'Style','PushButton', ...
                'Position',[5 5 20 20], ...
                'CData',cdata, ...
                'UIContextMenu',cmenu, ...
                'Callback', @ButtonCallback, ...
                'DeleteFcn', @(~,~) DeleteFcn(cmenu), ...
                'ToolTipString', 'Plot menu');

            % Assign the callback function responsible for resizing the subpanel
            spanel.SizeChangedFcn = @SizeChanged;

            % Callback function for resizing the subpanel 
            function SizeChanged(~,~)
                parentpos = getpixelposition(spanel);
                mb.Position(2) = parentpos(4) - mb.Position(4) - 6;
            end
            
            % Callback function for the subpanel menu button
            function ButtonCallback(src,~)
                pos = getpixelposition(src,true);
                mb.UIContextMenu.Position = pos([1 2]);
                mb.UIContextMenu.Visible='on';
            end
            
            % Callback function for cleaning up the context menu
            function DeleteFcn(cmenu)
                % Delete the context menu
                delete(cmenu);
            end
        end

        % Construct menu items for each entry in xxxdef.
        % All menu items are assigned the same tag and callback.
        % The separator only applies to the first menu item.
        % The menu for the checkindx'th entry is checked 'on'.
        % Returns a handle to the checked menu item
        function menuitem = SelectorMenu(menu,xxxdef,callback,separator,tag,checkindx)
            n = numel(xxxdef);
            for xxxindx=1:n
                UserData.xxxname = xxxdef(xxxindx).name;
                UserData.xxxindx = xxxindx;
                UserData.valindx = 1:numel(xxxdef(xxxindx).value);
                UserData.label = xxxdef(xxxindx).name;
                UserData.rootmenu = menu;
                if xxxindx==checkindx
                    % this menu item is checked 'on'
                    menuitem = uimenu('Parent',menu, ...
                        'Text',UserData.xxxname, ...
                        'Separator',separator, ...
                        'Checked','on', ...
                        'Tag',tag, ...
                        'UserData',UserData, ...
                        'Callback',callback);
                else
                    % this menu item is checked 'off'
                    uimenu('Parent',menu, ...
                        'Text',UserData.xxxname, ...
                        'Separator',separator, ...
                        'Checked','off', ...
                        'Tag',tag, ...
                        'UserData',UserData, ...
                        'Callback',callback);
                end
                separator='off';
            end
        end
        
        % generate a nested menu
        function menuitem = SelectorMenuFull(menu,xxxdef,callback,separator,tag,checkindx,checkvalindx)
            n = numel(xxxdef);
            for xxxindx=1:n
                xxxname = xxxdef(xxxindx).name;
                [nr nc] = size(xxxdef(xxxindx).value);                
                
                % Test whether the xxxdef.value is a scalar, vector or matrix
                if nr*nc==1
                    % The xxxdef value is a scalar.
                    % No nested menu items are required.
                    UserData.xxxname = xxxname;
                    UserData.xxxindx = xxxindx;
                    UserData.valindx = 1;
                    UserData.label = xxxname;
                    UserData.rootmenu = menu;
                    if xxxindx==checkindx
                        % this menu item is checked 'on'
                        menuitem = uimenu('Parent',menu, ...
                            'Text',xxxname, ...
                            'Separator',separator, ...
                            'Tag',tag, ...
                            'Checked','on', ...
                            'UserData',UserData, ...
                            'Callback',callback);
                    else
                        % this menu item is checked 'off'
                        uimenu('Parent',menu, ...
                            'Text',xxxname, ...
                            'Separator',separator, ...
                            'Tag',tag, ...
                            'Checked','off', ...
                            'UserData',UserData, ...
                            'Callback',callback);
                    end
                elseif nr==1 || nc==1
                    % The xxxdef value is a vector (1 x nc) or (nr x 1).
                    % Construct a nested menu with one item per entry in the vector.
                    submenu = uimenu('Parent',menu, ...
                        'Text',xxxname, ...
                        'Separator',separator);
                    for valindx=1:(nr*nc)
                        % break up large menu lists into nested submenus
                        if mod(valindx,26)==0
                            submenu = uimenu('Parent',submenu, 'Text','more');
                        end
                        % gather the menuitem details
                        label = num2str(valindx,[xxxname,'(%d)']);
                        UserData.xxxname = xxxname;
                        UserData.xxxindx = xxxindx;
                        UserData.valindx = valindx;
                        UserData.label = num2str(valindx,[xxxname,'_{%d}']);
                        UserData.rootmenu = menu;
                        if xxxindx==checkindx && valindx==checkvalindx
                            % this menu item is checked 'on'
                            menuitem = uimenu('Parent',submenu,...
                                'Text',label, ...
                                'Tag',tag, ...
                                'Checked','on', ...
                                'UserData',UserData, ...
                                'Callback',callback);
                        else
                            % this menu item is checked 'off'
                            uimenu('Parent',submenu,...
                                'Text',label, ...
                                'Tag',tag, ...
                                'Checked','off', ...
                                'UserData',UserData, ...
                                'Callback',callback);
                        end
                    end
                else
                    % The xxxdef value is a matrix (nr x nc)
                    % Construct a doubly-nested menu with one submenu for each row
                    % and one item per entry in that row.
                    submenu = uimenu('Parent',menu, ...
                        'Text',xxxname, ...
                        'Separator',separator);
                    valindx = 1;
                    for r=1:nr
                        % break up large menu lists into nested submenus
                        if mod(r,26)==0
                            submenu = uimenu('Parent',submenu, 'Text','more');
                        end
                        % construct a subsubmenu for the column values 
                        subsubmenu = uimenu('Parent',submenu, 'Text',num2str(r,[xxxname,'(%d,-)']));
                        for c=1:nc
                            % break up large menu lists into nested submenus
                            if mod(c,26)==0
                                subsubmenu = uimenu('Parent',subsubmenu, 'Text','more');
                            end
                            % gather menuitem details
                            label = num2str([r,c],[xxxname,'(%d,%d)']);
                            UserData.xxxname = xxxname;
                            UserData.xxxindx = xxxindx;
                            UserData.valindx = valindx;
                            UserData.label = num2str([r,c],[xxxname,'_{%d,%d}']);
                            UserData.rootmenu = menu;
                            if xxxindx==checkindx && valindx==checkvalindx
                                % this menu item is checked 'on'
                                menuitem = uimenu('Parent',subsubmenu,...
                                    'Text',label, ...
                                    'Tag',tag, ...
                                    'Checked','on', ...
                                    'UserData',UserData, ...
                                    'Callback',callback);
                            else
                                % this menu item is checked 'off'
                                uimenu('Parent',subsubmenu,...
                                    'Text',label, ...
                                    'Tag',tag, ...
                                    'Checked','off', ...
                                    'UserData',UserData, ...
                                    'Callback',callback);
                            end
                            valindx = valindx + 1;
                        end
                    end
                end

                % The separator only applies to the first menu item
                separator='off';
            end
        end
        
        function SelectorCheckItem(menuitem)
            % check 'off' all menu items with the same tag
            objs = findobj(menuitem.UserData.rootmenu,'Tag',menuitem.Tag);
            for indx=1:numel(objs)
                objs(indx).Checked='off';
            end            
            % now check 'on' the selected menu item
            menuitem.Checked='on';
        end
        
        % Utility function that returns a [lo hi] limit which is
        % rounded to 2 significant digits.
        function lim = RoundLim(lo,hi)
            d = hi-lo;
            lim = round([lo-0.1*d, hi+0.1*d],2,'significant');
        end

        % Callback executed by the tabgroup whenever the selected tab changes
        function PanelSelectionChangedFcn(~,evnt)
            disp('bdPanel.PanelSelectionChangedFcn');
            % Hide the panel menu associated with the old tab
            evnt.OldValue.UserData.menu.Visible = 'off';
            % Reveal the panel menu associated with the new tab
            evnt.NewValue.UserData.menu.Visible = 'on';
        end

    end
end

