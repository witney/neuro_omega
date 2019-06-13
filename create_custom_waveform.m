% create custom analog waveform, sends pulses at specified times (in seconds)
% inputs: parameters for biphasic pulse shape (amp in mA, pulse width in mS, delay in mS, for both phases), and
% sampling rate for stimulation channel (Fs)

function [waveform, num_pulses] = create_custom_waveform(stim_times_planned, del1, amp1, pw1, del2, amp2, pw2, Fs)

single_pulse_duration = (del1+pw1+del2+pw2); % in mS
delta_t = 1000/Fs; % in mS
T = [0:delta_t:1000*stim_times_planned(end)+2*single_pulse_duration];  %total time vector in milliseconds

% create waveform for a single pulse
waveform_single_pulse = [];
cathode_counter = 0;
anode_counter = 0; 
for i = 1:round(single_pulse_duration/delta_t)+1 % leave 1 here so that symmetric pulse is balanced
    my_t = (i-1)*delta_t;
    if (my_t < del1)
        my_p = 0;
    elseif (my_t < del1+pw1)
        my_p = amp1;
        cathode_counter = cathode_counter+1; 
    elseif (my_t < del1+pw1+del2)
        my_p = 0;
    else
        my_p = amp2;   
        anode_counter = anode_counter+1; 
    end     
    waveform_single_pulse(i) = my_p; 
end

% Make sure negative and positive phase of the waveform are charge balanced


x = abs(amp1)*delta_t/(abs(amp1)+abs(amp2)); % part of delta_t that current is in cathodic phase (as it goes from cathodic to anodic)
cathodic_phase_charge = (cathode_counter-1)*delta_t*abs(amp1) + delta_t*abs(amp1)/2 + x*abs(amp1)/2; %last two components are for triangular rise/fall
anodic_phase_charge = (anode_counter-1)*delta_t*abs(amp2) + (delta_t-x)*abs(amp2)/2 + delta_t*abs(amp2)/2; %last two components are for triangular rise/fall
if (cathodic_phase_charge > anodic_phase_charge)
    fprintf('Phases unbalanced (cathodic larger), cathodic phase %f mC, anodic phase %f mC...', cathodic_phase_charge/1000, anodic_phase_charge/1000) %in millicoulombs
    missing_anode = round((cathodic_phase_charge - anodic_phase_charge)/(delta_t*abs(amp2)));
    if missing_anode > 0
        fprintf('CORRECTING adding time points to anodic phase %d\n', missing_anode);
        waveform_single_pulse = [waveform_single_pulse amp2*ones(1,missing_anode)];
        anode_counter = anode_counter + missing_anode;
    else
        fprintf('No correction necessary %d\n', missing_anode);
    end    
elseif (cathodic_phase_charge < anodic_phase_charge)
    fprintf('Phases unbalanced (cathodic smaller), cathodic phase %f mC, anodic phase %f mC...', cathodic_phase_charge/1000, anodic_phase_charge/1000)
    extra_anode = round((anodic_phase_charge - cathodic_phase_charge)/(delta_t*abs(amp2)));
    if extra_anode > 0
        fprintf('CORRECTING removing time steps from anodic phase %d\n', extra_anode);
        waveform_single_pulse = waveform_single_pulse(1:end-extra_anode);
        anode_counter = anode_counter - extra_anode;
    else
        fprintf('No correction necessary %d\n', extra_anode);
    end    
else
    fprintf('Waveform is charge balanced\n')
end
fprintf('Integral for charge, AFTER correction %.8f\n', trapz(T(1:length(waveform_single_pulse)+2), [0 waveform_single_pulse 0]))

% put together single pulse waveforms at desired times
waveform = zeros(1,length(T)); 
num_pulses = 0; 
for i = 1:length(stim_times_planned)
    my_ind = round(stim_times_planned(i)*Fs);
    waveform(my_ind:my_ind+length(waveform_single_pulse)-1) = waveform_single_pulse;
    num_pulses = num_pulses+1; 
end    

% fprintf('Integral for charge, entire waveform %.8f\n', trapz(T, waveform))

end