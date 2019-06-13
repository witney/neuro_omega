%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evoked potentials using custom waveforms
% stimulation at random time points that averages out to 10 Hz
% random pulse times drawn from gaussian or uniform-log distribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% setup

clear

save_dir='C:\Users\StarrLab\Documents\MATLAB\intraop_scripts\Witney_scripts\Patient Evoked Potentials Parameters\';

InOp_connect_to_NeuroOmega;
AO_StartSave();
pause(5);

%% define stimulation parameters 

default_stim_freq       = 10; % avg stim frequency (Hz)
default_stim_time       = 30; % stim duration (sec)
default_pause_time      = 33; % pause duration (sec), pause time + default_stim_time
default_asymm_pulse     = 1; %set to 8 to use biphasic asymmetric pulse (positive phase has X smaller amplitude and X longer PW than negative phase) ; set to 1 to use biphasic symmetric pulse
                             %recharge phase cannot be longer than 0.5msec for NeuroOmega 
default_waveform_delay  = 0.07; %time delay between cathodic and anodic pulses, in msec (medtronic IPG is 0.07 msec, Boston Sci is 0.1 msec
start_stim_param        = 1; %which stim_param to start with 
stim_channel_SR         = 22000; % sampling rate in Hz; regular recording freq is 2750, but CHANGE TO 44000 for square pulses
distrib                 = 0; %1 for log-uniform, 0 for gaussian
coeff_variation         = .3; % set desired coefficient of variation to 0.1, 0.3 or 0.6 (set to 0 for regular stimulation)
                             % 0.6 --> geomean 135; pauses 0.5Hz; mean 118; real Cov 0.5 (because negative and short eliminated)
                             % 0.3 --> geomean 135; pauses none; mean 130; real Cov 0.3 (because negative and short eliminated)
min_freq                = 80;  % min freq for log-uniform distribution (geomean 130 (no pauses; mean 125; cov 0.3) --> 80-215) UNIFORM (See Birdno-Grill2012 )
max_freq                = 215; % max freq for log-uniform distribution 
% min_freq                = 45;  % min freq for log-uniform distribution (geomean 130 (pauses 5.5Hz; mean 108; cov 0.6) --> 45-390) UNIPEAK
% max_freq                = 390; % max freq for log-uniform distribution 
pattern_stim_time       = 0.1; % stim duration for waveform pattern creation (MUST BE IN SECONDS)


%% Define which channels to stimulate, short protocol with monopolar settings only

randomized_order = randperm(10);

stim_params(1,:) = {'ECOG 4 / 01 - Array 3 / 01', '-1', 3, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(2,:) = {'ECOG 4 / 01 - Array 3 / 01', '-1', -3, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(3,:) = {'ECOG 4 / 01 - Array 3 / 01', '-1', 6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(4,:) = {'ECOG 4 / 01 - Array 3 / 01', '-1', -6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(5,:) = {'ECOG 4 / 03 - Array 3 / 03', '-1', 3, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(6,:) = {'ECOG 4 / 03 - Array 3 / 03', '-1', -3, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(7,:) = {'ECOG 4 / 03 - Array 3 / 03', '-1', 6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(8,:) = {'ECOG 4 / 03 - Array 3 / 03', '-1', -6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(9,:) = {'ECOG 4 / 02 - Array 3 / 02', '-1', 6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(10,:) = {'ECOG 4 / 04 - Array 3 / 04', '-1', 6, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};

%% Cycle through channels/settings and stimulate

tic

for i = start_stim_param:size(stim_params,1)
    stim_channel_name{i}    = char(stim_params(randomized_order(i),1));
    return_channel_name{i}  = char(stim_params(randomized_order(i),2));
    stim_amp_mA(i)          = cell2mat(stim_params(randomized_order(i),3)); 
    stim_pw_us(i)           = cell2mat(stim_params(randomized_order(i),4)); 
    stim_freq(i)            = cell2mat(stim_params(randomized_order(i),5));
    total_stim_time(i)      = cell2mat(stim_params(randomized_order(i),6));
    asymm_pulse(i)          = cell2mat(stim_params(randomized_order(i),7));
    waveform_delay(i)       = cell2mat(stim_params(randomized_order(i),8));
    
    stim_channel = AO_TranslateNameToID( stim_channel_name{i} , length(stim_channel_name{i}) );  
    if (~strcmp(return_channel_name, '-1')) 
    	return_channel = AO_TranslateNameToID( return_channel_name{i} , length(return_channel_name{i})); 
    else
        return_channel = -1;   % set to -1 for global (ground) return
    end

    amp1(i) = -stim_amp_mA(i);
    pw1(i)  = stim_pw_us(i)/1000;
    amp2(i) = stim_amp_mA(i)/asymm_pulse(i);
    pw2(i)  = asymm_pulse(i)*stim_pw_us(i)/1000;
    del1(i) = 0; 
    del2(i) = waveform_delay(i); 
    if (pw2(i) >= 0.5) %this is max PW for NeuroOmega
        fprintf('Redefining pulse shape because recharge phase cannot be longer than 0.5 ms\n');
        pw2(i) = 0.48;
        asymm_pulse(i) = pw2(i)/pw1(i);
        amp2(i) = stim_amp_mA(i)/asymm_pulse(i);
    end

    pulse_duration(i) = (stim_pw_us(i) + asymm_pulse(i)*stim_pw_us(i))/1000000; %duration of both phases of a pulse in seconds
    dur_st(i) = 1.1*pulse_duration(i); %make stim duration little longer than one pulse to make sure it is fully delivered

    if (distrib == 0)
        %OPTION 1: draw IPIs from Gaussian distribution 
        mu(i) = 1/stim_freq(i) ;
        sigma(i) = mu(i)*coeff_variation;
        random_IPIs{i} = normrnd(mu(i),sigma(i),[1 2*round(stim_freq(i)*total_stim_time(i))]);
        random_IPIs{i}(random_IPIs{i} <= 1.1*pulse_duration(i)) = [];  %exclude negative IPIs and those shorter than little more than entire pulse duration
    elseif (distrib == 1)
        %OPTION 2: draw IPIs from log-uniform distribution 
        LA = log10(1/min_freq); LB = log10(1/max_freq);
        random_IPIs{i} = 10.^(LA + (LB-LA) * rand(1,2*round(stim_freq(i)*total_stim_time(i)))); 
        random_IPIs{i}(random_IPIs{i} <= 1.1*pulse_duration(i)) = [];  %should not need to exclude any since by definition they are not too short or negative
    end

    % create vector of stim times (in seconds) with total duration of total_stim_time (in seconds)
    stim_times_planned{i}(1) = [0.001]; %don't make it zero so that indices work out when creating custom waveform
    for abc = 2:length(random_IPIs{i})     
        stim_times_planned{i}(abc) = stim_times_planned{i}(abc-1) + random_IPIs{i}(abc);  
        if (stim_times_planned{i}(abc) >= total_stim_time(i))
            break
        end
    end

    % custom waveform
    [waveform{i}, num_pulses(i)] = wc_create_custom_waveform(stim_times_planned{i}, del1(i), amp1(i), pw1(i), del2(i), amp2(i), pw2(i), stim_channel_SR);
    pSource{i} = 1000*waveform{i};
    SamplesCount(i) = length(waveform{i}); 
    downSampleFactor(i) = 2; % must be 2^N = 1, 2, 4, 8, 18
    waveName = 'custom_wave';

    disp(sprintf('Stim settings #%d... STIM_CH = %s, RETURN_CH = %s, %0.2f mA, %d uS, %d Hz \n', i, stim_channel_name{i}, return_channel_name{i}, stim_amp_mA(i), stim_pw_us(i), stim_freq(i)))
    [Result1] = AO_LoadWaveToEmbedded(pSource{i}, SamplesCount(i), downSampleFactor(i), waveName);

    waveId = 0;
    Freq_HZ = 10; % wc edit
    Duration_sec = total_stim_time;

    [Result2] = AO_StartAnalogStimulation(stim_channel, 0, Freq_HZ, Duration_sec, return_channel);
    pause(default_pause_time)
        
    fprintf('Success: LoadWave %d, StartAnalog %d\n', Result1, Result2);
    
end

toc

pause(5);
AO_StopSave();


filename=input('Enter File Name: ','s');
cd('C:\Users\StarrLab\Documents\MATLAB\intraop_scripts\Witney_scripts\Patient Evoked Potential Parameters\');
save(filename);



