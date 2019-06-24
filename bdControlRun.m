classdef bdControlRun < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        Enable
        Visible
    end
    
    properties (Access=private)
        jbutton
        hjbutton
        hcontainer
    end
    
    methods
        function this = bdControlRun(control,parent,position)
            disp('bdControlRun(control,parent,position)');
            fontname = parent.FontName;
            fontsize = 12;
            jfont = java.awt.Font(fontname,java.awt.Font.PLAIN,fontsize);
            this.jbutton = javax.swing.JButton('RUN');
            this.jbutton.setFont(jfont);
            
            % adjust the margin of the text inside the button
            jmargin = this.jbutton.getMargin();
            jmargin.left=0;
            jmargin.right=0;
            jmargin.top=0;
            jmargin.bottom=0;
            this.jbutton.setMargin(jmargin);
            
            [this.hjbutton,this.hcontainer] = javacomponent(this.jbutton, position, parent);
            set(this.hjbutton,'ToolTipText','Run (evolve) the simulation once more');
            %set(this.hjbutton,'ActionPerformedCallback', @(src,~) notify(control,'recompute'));
            set(this.hcontainer,'Visible','off');
        end
        
        % Get Enable property
        function val = get.Enable(this)
            %disp('bdControlRun.get.Enable');
            val = get(this.jbutton,'Enabled');
        end
        
        % Set Enable property
        function set.Enable(this,val)
            %disp('bdControlRun.set.Enable');
            switch val
                case 'on'
                    set(this.jbutton,'Enabled',1);
                case 'off'
                    set(this.jbutton,'Enabled',0);
            end
        end
        
        % Get Visible property
        function val = get.Visible(this)
            %disp('bdControlRun.get.Visible');
            val = get(this.hcontainer,'Visible');
        end
        
        % Set Visible property
        function set.Visible(this,val)
            %disp('bdControlRun.set.Visible');
            set(this.hcontainer,'Visible',val);
        end
        
        % Get Armed property
        function val = isArmed(this)
            %disp('bdControlRun.isArmed');
            val = this.jbutton.getModel().isArmed();
        end        
    end
end

