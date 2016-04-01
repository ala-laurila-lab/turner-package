classdef FrameTimingFigure < symphonyui.core.FigureHandler
    
    properties (SetAccess = private)
        stageDevice
        frameMonitor
    end
    
    properties (Access = private)
        axesHandle
        flipTimingSweep
        frameMonitorSweep
    end
    
    methods
        
        function obj = FrameTimingFigure(stage,frameMonitor)
            obj.stageDevice = stage;
            obj.frameMonitor = frameMonitor;
            obj.createUi();
        end
        
        function createUi(obj)
            obj.axesHandle(1) = subplot(3,1,3,...
                'Parent',obj.figureHandle,...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'),...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'XTickMode', 'auto');
            xlabel(obj.axesHandle(1), 'flip');
            ylabel(obj.axesHandle(1), 'msec');

            obj.axesHandle(2) = subplot(3,1,1:2,...
                'Parent',obj.figureHandle,...
                'FontName', get(obj.figureHandle, 'DefaultUicontrolFontName'),...
                'FontSize', get(obj.figureHandle, 'DefaultUicontrolFontSize'), ...
                'XTickMode', 'auto');
            xlabel(obj.axesHandle(2), 'sec');
            ylabel(obj.axesHandle(2), '');
        end

        
        function handleEpoch(obj, epoch)
            info = obj.stageDevice.getPlayInfo();
            if isa(info, 'MException')
                error(['Stage encountered an error during the presentation: ' info.message]);
            end
            %software timing
            durations = info.flipDurations;
            if numel(durations) > 0
                x = 1:numel(durations);
                y = durations;
            else
                x = [];
                y = [];
            end
            if isempty(obj.flipTimingSweep)
                obj.flipTimingSweep = line(x, y .* 1e3, 'Parent', obj.axesHandle(1));
            else
                set(obj.flipTimingSweep, 'XData', x, 'YData', y .* 1e3);
            end
            
            if isa(obj.stageDevice,'edu.washington.rieke.devices.LightCrafterDevice')
                lightCrafterFlag = 1;
                ideal = 1/obj.stageDevice.getPatternRate();
            else %OLED stage device
                lightCrafterFlag = 0;
                ideal = 1/obj.stageDevice.getMonitorRefreshRate();
            end
            
            %load frame monitor data
            FMresponse = epoch.getResponse(obj.frameMonitor);
            FMdata = FMresponse.getData();
            sampleRate = FMresponse.sampleRate.quantityInBaseUnits;
            tVec = (0:length(FMdata)-1) ./ sampleRate;

            %check frame timing
            times = getFrameTiming(FMdata,lightCrafterFlag);

            durations = diff(times(:));
            if isa(obj.stageDevice,'edu.washington.rieke.devices.LightCrafterDevice')
                durations(1) = []; %first frame duration is tricky at the highest frame rates
            end
            minDuration = min(durations) / sampleRate;
            maxDuration = max(durations) / sampleRate;

            if abs(ideal-minDuration)/ideal > 0.2 || abs(ideal-maxDuration)/ideal > 0.2
                lineColor = 'r';
                epoch.addKeyword('badFrameTiming');
            else
                lineColor = 'b';
            end
            
            if isempty(obj.frameMonitorSweep)
                obj.frameMonitorSweep = line(tVec, FMdata, 'Parent', obj.axesHandle(2));
            else
                set(obj.frameMonitorSweep, 'XData', tVec, 'YData', FMdata);
            end
            set(obj.frameMonitorSweep, 'Color',lineColor)

        end
        
    end
    
end

