clc;clear;

% information about the input and output audio devices on the system.
info = audiodevinfo
% - Connect the stereo jack and configure it as a Line-in source.
% - Search for an input device named 'Line In'.
% If you cant find it try restarting matlab.
info.input(3)

% Create an audiorecorder object with a sampling rate of 1000Hz, 16 bits.
% The third argument corresponds to the number of channels. In our case
% it is 2 for a stereo recording.
% The fourth argument is the input device ID corresponding to the Line in
% input device.
recObj = audiorecorder(1000,16,2,2); % CH1: Mains, CH2: Photodiode

disp('Start of recording')

% Get a timestamp with a resolution of milliseconds
formatOut = 'yyyy/MM/dd HH:mm:ss.SSS';
timestamp = datetime('now', 'Format', formatOut)

% Record for the specified amount of time
recordblocking(recObj, 120);

disp('End of Recording.');

myRecording = getaudiodata(recObj);

% Plot the first 10 seconds of the recording
plot(myRecording);
axis([0 10000 -1 1])

% Extract the ENF with a resolution of 1s.
ENF_mains = ENF_Hilbert_Adaptive(myRecording(:,1),1000,1000,0.1);
ENF_pd = ENF_Hilbert_Adaptive(myRecording(:,2),1000,1000,0.2);

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

