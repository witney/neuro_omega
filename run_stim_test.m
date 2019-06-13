% test of stimulation function in Neuro Omega
% cycles through all channels in 1 module, delivers stimulation

%% setup

clear

save_dir='C:\Users\StarrLab\Documents\MATLAB\intraop_scripts\Witney_scripts\Patient Evoked Potentials Parameters\';

InOp_connect_to_NeuroOmega % connect computer to Neuro Omega
AO_StartSave() % start saving file on Neuro Omega
pause(3)

%% define stimulation parameters

default_stim_freq       = 10; % stim frequency (Hz)
default_stim_time       = 5; % stim duration (sec)
default_pause_time      = 8; % pause duration (sec) = pause time + default_stim_time
default_asymm_pulse     = 1; % set to 8 to use biphasic asymmetric pulse (positive phase has X smaller amplitude and X longer PW than negative phase) ; set to 1 to use biphasic symmetric pulse
                             % recharge phase cannot be longer than 0.5msec for NeuroOmega 
default_waveform_delay  = 0.07; % time delay between cathodic and anodic pulses, in msec (medtronic IPG is 0.07 msec, Boston Sci is 0.1 msec)
start_stim_param        = 1; % which stim_param to start with 
randomized_order        = randperm(16); % pseudorandomize order that stim params are applied


% parameters: (stim contact, return contact (-1 if global return), amplitude (mA), pulse width (uS), frequency (Hz), stim time (sec), waveform asymmetry ratio, stim waveform delay)
% note: array 1 contains module 1 and 2
stim_params(1,:)  = {'ECOG 1 / 01 - Array 1 / 01', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(2,:)  = {'ECOG 1 / 02 - Array 1 / 02', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(3,:)  = {'ECOG 1 / 03 - Array 1 / 03', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(4,:)  = {'ECOG 1 / 04 - Array 1 / 04', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(5,:)  = {'ECOG 1 / 05 - Array 1 / 05', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(6,:)  = {'ECOG 1 / 06 - Array 1 / 06', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(7,:)  = {'ECOG 1 / 07 - Array 1 / 07', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(8,:)  = {'ECOG 1 / 08 - Array 1 / 08', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(9,:)  = {'ECOG 1 / 09 - Array 1 / 09', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(10,:) = {'ECOG 1 / 10 - Array 1 / 10', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(11,:) = {'ECOG 1 / 11 - Array 1 / 11', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(12,:) = {'ECOG 1 / 12 - Array 1 / 12', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(13,:) = {'ECOG 1 / 13 - Array 1 / 13', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(14,:) = {'ECOG 1 / 14 - Array 1 / 14', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(15,:) = {'ECOG 1 / 15 - Array 1 / 15', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};
stim_params(16,:) = {'ECOG 1 / 16 - Array 1 / 16', '-1', 5, 100, default_stim_freq, default_stim_time, default_asymm_pulse, default_waveform_delay};

%% deliver stimulation

tic
for i = start_stim_param:size(stim_params,1)
    
    stim_channel_name   = char(stim_params(randomized_order(i),1));
    return_channel_name = char(stim_params(randomized_order(i),2));
    stim_amp_mA         = cell2mat(stim_params(randomized_order(i),3)); 
    stim_pw_us          = cell2mat(stim_params(randomized_order(i),4)); 
    stim_freq           = cell2mat(stim_params(randomized_order(i),5));
    stim_time           = cell2mat(stim_params(randomized_order(i),6));
    asymm_pulse         = cell2mat(stim_params(randomized_order(i),7));
    waveform_delay      = cell2mat(stim_params(randomized_order(i),8));
    
    stim_channel = AO_TranslateNameToID( stim_channel_name , length(stim_channel_name) );  
    if (~strcmp(return_channel_name, '-1')) 
    	return_channel=AO_TranslateNameToID( return_channel_name , length(return_channel_name)); 
    else
        return_channel = -1;   % set to -1 for global (ground) return
    end

    % pre calculate to avoid repeat calculations
    amp1 = -stim_amp_mA;
    pw1  = stim_pw_us/1000;
    amp2 = stim_amp_mA/asymm_pulse;
    pw2  = asymm_pulse*stim_pw_us/1000;
    del1 = 0; 
    del2 = waveform_delay; 
    if (pw2 >= 0.5) %this is max PW for NeuroOmega
        fprintf('Redefining pulse shape because recharge phase cannot be longer than 0.5 ms\n');
        pw2 = 0.48;
        asymm_pulse = pw2/pw1;
        amp2 = stim_amp_mA/asymm_pulse;
    end

    % input vars: StimChannel, FirstPhaseDelay_mS, FirstPhaseAmpl_mA, FirstPhaseWidth_mS, SecondPhaseDelay_mS, SecondPhaseAmpl_mA, SecondPhaseWidth_mS, Freq_hZ, Duration_sec, ReturnChannel
    fprintf('Stim settings #%d... STIM_CH = %s, RETURN_CH = %s, %0.2f mA, %d uS, %d Hz \n', i, stim_channel_name, return_channel_name, stim_amp_mA, stim_pw_us, stim_freq);
    
    % deliver stimulation and pause before next block begins
    [Result] = AO_StartDigitalStimulation(stim_channel, del1, amp1, pw1, del2, amp2, pw2, stim_freq, stim_time, return_channel);
    pause(default_pause_time)
   
end
toc

pause(3)
AO_StopSave() % stop saving file on Neuro Omega

filename = input('Enter Patient Initials and Date (filename): ','s');
save([savedir filename]);

