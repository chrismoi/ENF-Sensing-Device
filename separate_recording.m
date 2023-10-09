clc;clear;

% information about the input and output audio devices on the system.
info = audiodevinfo
% - Connect the TRRS jack in the audio port and configure it as a headset
% with microphone.
% - Connect the USB sound card.
% - Search for input devices named 'Jack Mic' and 'USB audio device'.
% If you cant find them try restarting matlab.
info.input(3)

% Create an audiorecorder object for each device with a sampling rate of
% 1000Hz, 16 bits.
% The third argument corresponds to the number of channels. In our case
% it is 1 for a mono recording.
% The fourth argument is the input device ID corresponding to the device
% name.
% Place mains signal device ID in recObj1 and photodiode signal device ID
% in recObj2.
recObj1 = audiorecorder(1000,16,1,1);
recObj2 = audiorecorder(1000,16,1,2);

disp('Start of recording')

% Get a timestamp with a resolution of milliseconds and record for the
% specified amount of time
formatOut = 'yyyy/MM/dd HH:mm:ss.SSS';
rec_dur = 120;

% In order to compensate for difference in the start time of the recordings
% we record the first object for 1 sec longer and try to synchronize them
% after the recordings are finished.
record(recObj1, rec_dur+1);
timestamp_mid = datetime('now', 'Format', formatOut)
record(recObj2, rec_dur);
timestamp = datetime('now', 'Format', formatOut)

while (isrecording(recObj1) || isrecording(recObj2))
    pause(1);
end

disp('End of Recording.');

myRec1 = getaudiodata(recObj1);
myRec2 = getaudiodata(recObj2);

% Discard the ms_diff amount from Rec1 in order to be as much as possible
% in sync with Rec2
ms_diff = floor(milliseconds(timestamp - timestamp_mid))
myRec1 = myRec1(ms_diff:end-(1000-ms_diff+1));

% Plot the first 10 seconds of the recording
plot(myRec1);
hold on
plot(myRec2);
axis([0 10000 -1 1])

% Extract the ENF with a resolution of 1s.
ENF_mains = ENF_Hilbert_Adaptive(myRec1,1000,1000,0.1);
ENF_pd = ENF_Hilbert_Adaptive(myRec2,1000,1000,0.2);

% Plot the extracted ENF
figure();
plot(ENF_mains);
hold on 
plot(ENF_pd);
grid on
ylim([49.9 50.1])

% Calculate the correlation coefficient between the ENF from power mains
% and the ENF from the photodiode.
disp('MCC is:')
corrcoef(ENF_mains,ENF_pd)

% Create a timetable and export it to .csv
Time = timestamp;
for i=1:1:(length(ENF_mains)-1)
    Time = [Time ; timestamp + seconds(i)];
end

TT = timetable(Time,ENF_mains,ENF_pd);

filename = regexprep(datestr(timestamp),'[^a-zA-Z0-9]','_');
filename = strcat('ENF_', filename, '.csv');
writetimetable(TT, filename);

