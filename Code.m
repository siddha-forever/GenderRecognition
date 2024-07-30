classdef gender_recognition_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MaleFemaleVoiceRecognitionUIFigure  matlab.ui.Figure
        RemoveNoiseButton        matlab.ui.control.Button
        ResetButton              matlab.ui.control.Button
        MadebySiddhabrataMohapatraLabel  matlab.ui.control.Label
        Lamp                     matlab.ui.control.Lamp
        record_msg               matlab.ui.control.EditField
        RealTimeGenderIdentificationUsingMATLABLabel  matlab.ui.control.Label
        RecordButton             matlab.ui.control.Button
        StopButton               matlab.ui.control.Button
        ListenAudioButton        matlab.ui.control.Button
        GenerateGraphButton      matlab.ui.control.Button
        ExecuteButton            matlab.ui.control.Button
        freq                     matlab.ui.control.NumericEditField
        FrequencyEditFieldLabel  matlab.ui.control.Label
        CalculateButton          matlab.ui.control.Button
        gender                   matlab.ui.control.EditField
        GenderLabel              matlab.ui.control.Label
        UIAxes                   matlab.ui.control.UIAxes
    end


    properties (Access = public)
        file_ % Description
        flag=0;
        path
        aud_file
        aud_fs=0;
    end

    % methods (Access = public)



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: CalculateButton
        function CalculateButtonPushed(app, event)


            if app.flag==1
                [y ,Fs]=audioread(app.file_);
                F0 = pitch(y, Fs);


                app.freq.Value=mean(F0);
                if app.freq.Value>190
                    app.gender.Value='Female';
                    app.Lamp.Color = 'red';

                else
                    app.gender.Value='Male';
                    app.Lamp.Color = 'Black';
                end

                plot(app.UIAxes,fftshift(abs(fft(app.aud_file))));
                title(app.UIAxes,"FFT of Audio");
                xlabel(app.UIAxes,"Frequency")
                ylabel(app.UIAxes,"Amplitude")

            else
                app.record_msg.Value='Record First';
            end
        end

        % Button pushed function: GenerateGraphButton
        function GenerateGraphButtonPushed(app, event)
            plot(app.UIAxes,app.aud_file);
            title(app.UIAxes,"Audio");
            xlabel(app.UIAxes,"Time")
            ylabel(app.UIAxes,"Amplitude")
        end

        % Button pushed function: ListenAudioButton
        function ListenAudioButtonPushed(app, event)
            sound(app.aud_file,app.aud_fs);
        end

        % Button pushed function: ExecuteButton
        function ExecuteButtonPushed(app, event)
            file = 'audio.wav';
            p = '/Users/siddha-book/Downloads/Gender-Recognition/';
            
            if strcmp(file(length(file)-3:length(file)), '.wav')
                app.flag = 1;
                app.path = p;
                s = strcat(p, file);
                app.file_ = s;
                [app.aud_file, app.aud_fs] = audioread(app.file_);
            end

        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            clear sound;
        end

        % Button pushed function: RecordButton
        function RecordButtonPushed(app, event)
            Fs = 8000; %sampling freq
            ch=1; %channel , 1 --> mono , 2--> stereo
            dataType = 'uint8';
            nbits = 16 ; %8--> low resolution, 16--> med , 24--> high resolution
            Nsec = 5; %duration of recording

            %using microphone to record :
            recorder = audiorecorder(Fs,nbits,ch);
            app.record_msg.Value = 'Recording Started !!';
            recordblocking(recorder,Nsec);
            app.record_msg.Value = 'Recording Ended !!';

            %storing the audio
            x = getaudiodata(recorder, dataType);

            %writing the audio file
            audiowrite('audio.wav',x,Fs);

        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            cla(app.UIAxes);
            app.record_msg.Value = 'Reset Success!';
            app.freq.Value = 0;
            app.gender.Value = '0';
            app.Lamp.Color = 'white'
        end

        % Button pushed function: RemoveNoiseButton
        function RemoveNoiseButtonPushed(app, event)
            %noise reduction using spectral subtraction method
            noisyFilePath = '/Users/siddha-book/Downloads/Gender-Recognition/audio.wav';
            [noisySignal, fs] = audioread(noisyFilePath);
            % Parameters for Spectral Subtraction
            frameSize = 512; % Frame size in samples
            overlap = 0.75; % Overlap percentage between frames (0 to 1)
            alpha = 5; % Over-subtraction factor
            beta = 0.02; % Spectral floor (controls the amount of residual noise)

            % Apply Spectral Subtraction
            noisySignal = noisySignal(:, 1); % Consider only the first channel if it's a stereo audio

            % Calculate the number of frames
            frameShift = round(frameSize * (1 - overlap));
            numFrames = floor((length(noisySignal) - frameSize) / frameShift) + 1;

            % Initialize the processed signal
            processedSignal = zeros((numFrames - 1) * frameShift + frameSize, 1);

            for i = 1:numFrames
                % Extract the current frame
                startIndex = (i - 1) * frameShift + 1;
                endIndex = startIndex + frameSize - 1;
                frame = noisySignal(startIndex:endIndex);

                % Perform FFT on the frame
                frameFFT = fft(frame);

                % Calculate the magnitude spectrum and phase
                magSpectrum = abs(frameFFT);
                phase = angle(frameFFT);

                % Estimate the noise spectrum (assumed to be the first frame)
                if i == 1
                    noiseMagSpectrum = magSpectrum;
                end

                % Perform Spectral Subtraction
                processedMagSpectrum = magSpectrum - alpha * noiseMagSpectrum;
                processedMagSpectrum = max(processedMagSpectrum, beta * noiseMagSpectrum);

                % Reconstruct the processed frame using the modified magnitude spectrum and the original phase
                processedFrame = real(ifft(processedMagSpectrum .* exp(1i * phase)));

                % Overlap and add the processed frame to the output signal
                processedSignal(startIndex:endIndex) = processedSignal(startIndex:endIndex) + processedFrame;
            end

            % Normalize the processed signal
            processedSignal = processedSignal / max(abs(processedSignal));

            % Save the processed audio to a file
            outputFilePath = '/Users/siddha-book/Downloads/Gender-Recognition/audio.wav';
            audiowrite(outputFilePath, processedSignal, fs);
            app.record_msg.Value = 'Noise Removed !!';
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MaleFemaleVoiceRecognitionUIFigure and hide until all components are created
            app.MaleFemaleVoiceRecognitionUIFigure = uifigure('Visible', 'off');
            app.MaleFemaleVoiceRecognitionUIFigure.Position = [100 100 650 402];
            app.MaleFemaleVoiceRecognitionUIFigure.Name = 'Male Female Voice Recognition';

            % Create UIAxes
            app.UIAxes = uiaxes(app.MaleFemaleVoiceRecognitionUIFigure);
            title(app.UIAxes, 'Audio')
            xlabel(app.UIAxes, 'Time')
            ylabel(app.UIAxes, 'Amplitude')
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.XTickLabelRotation = 0;
            app.UIAxes.YTickLabelRotation = 0;
            app.UIAxes.GridAlpha = 0.15;
            app.UIAxes.MinorGridAlpha = 0.25;
            app.UIAxes.FontSize = 8;
            app.UIAxes.Position = [254 125 374 219];

            % Create GenderLabel
            app.GenderLabel = uilabel(app.MaleFemaleVoiceRecognitionUIFigure);
            app.GenderLabel.HorizontalAlignment = 'right';
            app.GenderLabel.VerticalAlignment = 'top';
            app.GenderLabel.Position = [313 36 46 15];
            app.GenderLabel.Text = 'Gender';

            % Create gender
            app.gender = uieditfield(app.MaleFemaleVoiceRecognitionUIFigure, 'text');
            app.gender.Editable = 'off';
            app.gender.HorizontalAlignment = 'right';
            app.gender.Position = [383 32 100 22];

            % Create CalculateButton
            app.CalculateButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.CalculateButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateButtonPushed, true);
            app.CalculateButton.BackgroundColor = [0.0745 0.6235 1];
            app.CalculateButton.FontColor = [1 1 1];
            app.CalculateButton.Position = [84 95 100 22];
            app.CalculateButton.Text = 'Calculate';

            % Create FrequencyEditFieldLabel
            app.FrequencyEditFieldLabel = uilabel(app.MaleFemaleVoiceRecognitionUIFigure);
            app.FrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.FrequencyEditFieldLabel.VerticalAlignment = 'top';
            app.FrequencyEditFieldLabel.Position = [49 36 63 15];
            app.FrequencyEditFieldLabel.Text = 'Frequency';

            % Create freq
            app.freq = uieditfield(app.MaleFemaleVoiceRecognitionUIFigure, 'numeric');
            app.freq.Editable = 'off';
            app.freq.Position = [127 32 100 22];

            % Create ExecuteButton
            app.ExecuteButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.ExecuteButton.ButtonPushedFcn = createCallbackFcn(app, @ExecuteButtonPushed, true);
            app.ExecuteButton.BackgroundColor = [0.0745 0.6235 1];
            app.ExecuteButton.FontColor = [1 1 1];
            app.ExecuteButton.Position = [151 239 76 23];
            app.ExecuteButton.Text = 'Execute';

            % Create GenerateGraphButton
            app.GenerateGraphButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.GenerateGraphButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateGraphButtonPushed, true);
            app.GenerateGraphButton.BackgroundColor = [0.0745 0.6235 1];
            app.GenerateGraphButton.FontColor = [1 1 1];
            app.GenerateGraphButton.Position = [313 95 103 22];
            app.GenerateGraphButton.Text = 'Generate Graph';

            % Create ListenAudioButton
            app.ListenAudioButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.ListenAudioButton.ButtonPushedFcn = createCallbackFcn(app, @ListenAudioButtonPushed, true);
            app.ListenAudioButton.Position = [18 191 111 22];
            app.ListenAudioButton.Text = 'Listen Audio';

            % Create StopButton
            app.StopButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [1 0 0];
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Position = [162 191 56 22];
            app.StopButton.Text = 'Stop';

            % Create RecordButton
            app.RecordButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.RecordButton.ButtonPushedFcn = createCallbackFcn(app, @RecordButtonPushed, true);
            app.RecordButton.Position = [18 281 100 23];
            app.RecordButton.Text = 'Record';

            % Create RealTimeGenderIdentificationUsingMATLABLabel
            app.RealTimeGenderIdentificationUsingMATLABLabel = uilabel(app.MaleFemaleVoiceRecognitionUIFigure);
            app.RealTimeGenderIdentificationUsingMATLABLabel.HorizontalAlignment = 'center';
            app.RealTimeGenderIdentificationUsingMATLABLabel.FontSize = 18;
            app.RealTimeGenderIdentificationUsingMATLABLabel.FontWeight = 'bold';
            app.RealTimeGenderIdentificationUsingMATLABLabel.Position = [98 358 430 24];
            app.RealTimeGenderIdentificationUsingMATLABLabel.Text = 'Real - Time Gender Identification Using MATLAB';

            % Create record_msg
            app.record_msg = uieditfield(app.MaleFemaleVoiceRecognitionUIFigure, 'text');
            app.record_msg.Position = [124 281 131 22];

            % Create Lamp
            app.Lamp = uilamp(app.MaleFemaleVoiceRecognitionUIFigure);
            app.Lamp.Position = [502 33 20 20];
            app.Lamp.Color = [1 1 1];

            % Create MadebySiddhabrataMohapatraLabel
            app.MadebySiddhabrataMohapatraLabel = uilabel(app.MaleFemaleVoiceRecognitionUIFigure);
            app.MadebySiddhabrataMohapatraLabel.Position = [570 22 71 44];
            app.MadebySiddhabrataMohapatraLabel.Text = {'Made by'; 'Siddhabrata'; 'Mohapatra'};

            % Create ResetButton
            app.ResetButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.BackgroundColor = [1 0 0];
            app.ResetButton.FontColor = [1 1 1];
            app.ResetButton.Position = [482 95 100 23];
            app.ResetButton.Text = 'Reset';

            % Create RemoveNoiseButton
            app.RemoveNoiseButton = uibutton(app.MaleFemaleVoiceRecognitionUIFigure, 'push');
            app.RemoveNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveNoiseButtonPushed, true);
            app.RemoveNoiseButton.Position = [18 239 100 23];
            app.RemoveNoiseButton.Text = 'Remove Noise';

            % Show the figure after all components are created
            app.MaleFemaleVoiceRecognitionUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = gender_recognition_app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MaleFemaleVoiceRecognitionUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MaleFemaleVoiceRecognitionUIFigure)
        end
    end
end
