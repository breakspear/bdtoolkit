% construct figure
fig = figure('Units','pixels','Position',[randi(100,1,1),randi(100,1,1),600,400]);

scrollpane = bdScroll(fig,300,300);
ax = axes('Parent',scrollpane.panel);
imagesc(rand(100,100),'Parent',ax);
