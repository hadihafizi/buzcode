function MClust

% MClust main window
% 
% Each uicontrol is given a Tag that is descriptive of its
% role.  All callbacks are sent to MClustCallbacks.  There
% a switch statement will case on the Tag to run each routine.
%
% ADR 1998
%
% Status: PROMOTED (Release version) 
% See documentation for copyright (owned by original authors) and warranties (none!).
% This code released as part of MClust 3.5.
% Version control M3.5 Jan/2007.
%----------------------------------
% -- constant globals

global MClust_Directory     % directory where the MClust main function and features reside
global MClust_FeatureData  % feature data
global MClust_TTfn         % file name for tt file
global MClust_NeuralLoadingFunction % Loading Engine 

global MCLUST_VERSION

MClustResetGlobals('initialize');

%%%%%% ------ modified batta 5/7/01 -----------------------

% read defaults if available
fp = fopen('defaults.mclust');
if fp == -1
   pushdir(MClust_Directory);
   fp = fopen('defaults.mclust');
else 
   pushdir;
end
if fp ~= -1
   fclose(fp);
   load defaults.mclust -mat
end
popdir;

% resize windows if necessary
ScSize = get(0, 'ScreenSize');
maxX = ScSize(3);
maxY = ScSize(4);
WindowList = {};
WindowList{end+1} = 'MClust_ClusterCutWindow_Pos';
WindowList{end+1} = 'MClust_CHDrawingAxisWindow_Pos';
WindowList{end+1} = 'MClust_KKDecisionWindow_Pos';
WindowList{end+1} = 'MClust_KK2D_Pos';
WindowList{end+1} = 'MClust_KK3D_Pos';
WindowList{end+1} = 'MClust_KKContour_Pos';

for iW = 1:length(WindowList)
	if eval(['sum(' WindowList{iW} '([1 3])) > maxX'])
		eval([WindowList{iW} '([1 3]) = [maxX - 500 400];']);
	end
	if eval(['sum(' WindowList{iW} '([2 4])) > maxY'])
		eval([WindowList{iW} '([2 4]) = [maxY - 500 400];']);
	end
end
%----------------------------------
% main window

MClustMainFigureHandle = figure(...
   'Name','MClust', ...
   'NumberTitle','off', ...   
   'Tag','MClustMainWindow', ...,
   'Resize', 'Off', ...
   'Units', 'Normalized', ...
   'HandleVisibility', 'Callback');
% resize
X = get(MClustMainFigureHandle, 'Position');
set(MClustMainFigureHandle, 'Position', [X(1) X(2)-.25 X(3) X(4)+.25]); 

%-------------------------------
% Alignment variables

uicHeight = 0.04;
uicWidth  = 0.25;
dX = 0.3;
XLocs = 0.1:dX:0.9;
dY = 0.04;
YLocs = 0.9:-dY:0.1;
FrameBorder = 0.01;


% Buttons and status

uicontrol('Parent', MClustMainFigureHandle, ... 
   'Units', 'Normalized', 'Position', [XLocs(1)-FrameBorder YLocs(end)-FrameBorder dX 0.85+2*FrameBorder], ...
   'Style', 'frame');

% loading engine

LoadingEngineDirectory = fullfile(MClust_Directory, 'LoadingEngines');
LoadingEnginesM = FindFiles('*.m', 'StartingDirectory', LoadingEngineDirectory);
LoadingEnginesDLL = FindFiles('*.dll', 'StartingDirectory', LoadingEngineDirectory);
LoadingEnginesMexw32 = FindFiles('*.mexw32', 'StartingDirectory', LoadingEngineDirectory); % added JCJ Oct 2007
LoadingEnginesMexw64 = FindFiles('*.mexw64', 'StartingDirectory', LoadingEngineDirectory); % added JCJ Oct 2007
LoadingEngines = sort(cat(1, LoadingEnginesM, LoadingEnginesDLL,LoadingEnginesMexw32,LoadingEnginesMexw64)); % added new mex file formats JCJ Oct 2007
for iV = 1:length(LoadingEngines)
    [d f] = fileparts(LoadingEngines{iV});
    LoadingEngines{iV} = f;
end
if isempty(LoadingEngines)
    close(MClustManFigureHandle)
    error('No Loading Engines found.');
end
if ~isempty(MClust_NeuralLoadingFunction) 
    LoadingEngineValue = strmatch(MClust_NeuralLoadingFunction,LoadingEngines);
else
    LoadingEngineValue = [];
end 
if isempty(LoadingEngineValue) 
    MClust_NeuralLoadingFunction = LoadingEngines{1};
    LoadingEngineValue = 1;
end

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(1) uicWidth uicHeight], ...
   'Style', 'Popupmenu', 'Tag', 'SelectLoadingEngine', 'Callback', 'MClustCallbacks', ...
   'String', LoadingEngines, 'Value', LoadingEngineValue, ...
   'TooltipString', 'Select loading engine to use for input to MClust');

DefaultProfiles = FindFiles('*.mclust', 'StartingDirectory', MClust_Directory);

for iD = 1:length(DefaultProfiles)
	[p DefaultProfiles{iD} e] = fileparts(DefaultProfiles{iD});
end

DefaultValue = strmatch('defaults',DefaultProfiles);

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(2) uicWidth uicHeight], ...
   'Style', 'Popupmenu', 'Tag', 'SelectProfile', 'Callback', 'MClustCallbacks', ...
   'String', DefaultProfiles, 'Value', DefaultValue, ...
   'TooltipString', 'Select a profile to load');

% onward
if ~isempty(MClust_TTfn)
   [curdn, curfn] = fileparts(MClust_TTfn);
else
   curfn = [];
end
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(3) uicWidth uicHeight], ...
   'Style', 'Text', 'String', curfn, 'Tag', 'TTFileName','BackGroundColor',[0.7 0.7 0.7])

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(4) uicWidth uicHeight], ...
   'Style', 'CheckBox', 'String', 'Create/Load FD files (*.fd)', 'Tag', 'LoadFeaturesButton', ...
   'Callback', 'MClustCallbacks','Value', ~isempty(MClust_FeatureData), ...
   'TooltipString', 'Choose tetrode .dat or feature data file to use as input to MClust');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1)+0.02 YLocs(8) uicWidth-0.04 uicHeight], ...
   'Style', 'PushButton', 'String', 'KlustaKwik Selection', 'Tag', 'KlustaKwikSelection', ...
   'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Select clusters from KlustaKwik .clu files');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(10) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Manual Cut', 'Tag', 'CutPreClusters', ...
   'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Edit pre-clusters by adding convex hulls selected pairs of dimensions');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(19) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Write Files', 'Tag', 'WriteFiles', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Write clusters to disk.  Writes t-files, cluster-files, and cut-files.');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(1) YLocs(20) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Exit', 'Tag', 'ExitOnlyButton', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Exit MClust');

% Create Feature Listboxes
uicontrol('Parent', MClustMainFigureHandle,...
   'Style', 'text', 'String', 'FEATURES', 'Units', 'Normalized', 'Position', [XLocs(2) YLocs(1) 2*uicWidth uicHeight]);
uicontrol('Parent', MClustMainFigureHandle,...
   'Style', 'text', 'String', 'available', 'Units', 'Normalized', 'Position', [XLocs(2) YLocs(2) uicWidth uicHeight]);
ui_featuresIgnoreLB =  uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(8) uicWidth 6*uicHeight],...
   'Style', 'listbox', 'Tag', 'FeaturesIgnoreListbox',...
   'Callback', 'MClustCallbacks',...
   'HorizontalAlignment', 'right', ...
   'Enable','on', ...
   'TooltipString', 'These are features which are not included but are also available.');
uicontrol('Parent', MClustMainFigureHandle,...
   'Style', 'text', 'String', 'used', 'Units', 'Normalized', 'Position', [XLocs(2)+uicWidth YLocs(2) uicWidth uicHeight]);
ui_featuresUseLB = uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2)+uicWidth YLocs(8) uicWidth 6*uicHeight],...
   'Style', 'listbox', 'Tag', 'FeaturesUseListbox',...
   'Callback', 'MClustCallbacks',...
   'HorizontalAlignment', 'right', ...
   'Enable','on', ...
   'TooltipString', 'These features will be used.');
set(ui_featuresIgnoreLB, 'UserData', ui_featuresUseLB);
set(ui_featuresUseLB,    'UserData', ui_featuresIgnoreLB);

% Locate and load the names of feature files
featureFiles =  sortcell(FindFiles('feature_*.m', ...
    'StartingDirectory', fullfile(MClust_Directory, 'Features') ,'CheckSubdirs', 0));
featureIgnoreString = {};
featureUseString = {};
for iF = 1:length(featureFiles)
   [dummy, featureFiles{iF}] = fileparts(featureFiles{iF});
   featureFiles{iF} = featureFiles{iF}(9:end); % cut "feature_" off front for display
   if any(strcmp(featureFiles{iF}, featuresToUse))
      featureUseString = cat(1, featureUseString, featureFiles(iF));
   else
      featureIgnoreString = cat(1, featureIgnoreString, featureFiles(iF));
   end
end
set(ui_featuresIgnoreLB, 'String', featureIgnoreString);
set(ui_featuresUseLB, 'String', featureUseString);
%if ~isempty(ui_featuresUseLB)
  % set(ui_ChooseFeaturesButton, 'Value', 1);
   %end



% tetrode validity
uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(9) 2*uicWidth uicHeight],...
   'Style', 'text', 'String', 'CHANNEL VALIDITY');
uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2)+0*uicWidth/2 YLocs(10) uicWidth/2 uicHeight],...   
   'Style', 'checkbox', 'String', 'Ch 1', 'Tag', 'TTValidity1', 'Value', 1, 'HorizontalAlignment', 'left', ...
    'Enable','on', 'TooltipString', 'Include channel 1 in feature calculation.', 'Callback', 'MClustCallbacks');
uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2)+1*uicWidth/2 YLocs(10) uicWidth/2 uicHeight],...   
   'Style', 'checkbox', 'String', 'Ch 2', 'Tag', 'TTValidity2', 'Value', 1, 'HorizontalAlignment', 'left', ...
    'Enable','on', 'TooltipString', 'Include channel 2 in feature calculation.', 'Callback', 'MClustCallbacks');
uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2)+2*uicWidth/2 YLocs(10) uicWidth/2 uicHeight],...   
   'Style', 'checkbox', 'String', 'Ch 3', 'Tag', 'TTValidity3', 'Value', 1, 'HorizontalAlignment', 'left', ...
    'Enable','on', 'TooltipString', 'Include channel 3 in feature calculation.', 'Callback', 'MClustCallbacks');
uicontrol('Parent', MClustMainFigureHandle,...
   'Units', 'Normalized', 'Position', [XLocs(2)+3*uicWidth/2 YLocs(10) uicWidth/2 uicHeight],...   
   'Style', 'checkbox', 'String', 'Ch 4', 'Tag', 'TTValidity4', 'Value', 1, 'HorizontalAlignment', 'left', ...
    'Enable','on', 'TooltipString', 'Include channel 4 in feature calculation.', 'Callback', 'MClustCallbacks');




% Loading and saving components
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2)-FrameBorder YLocs(end)-FrameBorder 2*(uicWidth+FrameBorder) uicHeight*11], ...
   'Style', 'frame');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(12) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Load clusters', 'Tag', 'LoadClusters', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Load already cut clusters. Features and channel validity MUST BE identical to previous session.');
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(13) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Apply convex hulls', 'Tag', 'ApplyConvexHulls', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Apply convex hulls from .clusters file to this data set.');
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(14) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Save clusters', 'Tag', 'SaveClusters', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Save clusters but do not write t-files.');
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(16) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Clear Clusters', 'Tag', 'ClearClusters', ...
   'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Clear clusters.  No undo available.');
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) 0.5*(YLocs(17)+YLocs(18)) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Clear Workspace', 'Tag', 'ClearWorkspaceOnly', ...
   'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Remove all clusters and feature data files currently in memory');


uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(20) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Load defaults', 'Tag', 'LoadDefaults', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Load defaults.  Defaults include color scheme, features, and channel validity.');
uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2) YLocs(21) uicWidth uicHeight], ...
   'Style', 'PushButton', 'String', 'Save defaults', 'Tag', 'SaveDefaults', 'Callback', 'MClustCallbacks', ...
   'TooltipString', 'Save defaults.  Defaults include color scheme, features, and channel validity.');

uicontrol('Parent', MClustMainFigureHandle, ...
   'Units', 'Normalized', 'Position', [XLocs(2)+uicWidth YLocs(21) uicWidth uicHeight * 10], ...
   'Style', 'text', ...
   'String', { ['MClust ' MCLUST_VERSION], 'By AD Redish', ' ', ...
       ' including code by ', 'F Battaglia',  'S Cowen', 'JC Jackson', 'P Lipa','NC Schmitzer-Torbert',  ...
       ' ', ' KlustaKwik by K. Harris'});