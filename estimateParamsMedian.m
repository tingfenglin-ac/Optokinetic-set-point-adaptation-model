% This code is used for estimating the parameters expleing median 
% population data. To run this code, you need the data for all conditions:
% 20/5, 10/10, 10/5 deg/s. Note that these are the median velocity for the
% population across differential stimuli conditions. Moreover, you will
% need to specify an appropraite innitial condition, 

% Developed and documented Mohammad Mohammadi, 9:47 pm, August 22nd, 2022
% mohammad.mohammadi2@mail.mcgill.ca


% ------------------ initial parameter specification ----------------------
% Specifiy the initial parameters you are going to use. Note that you might
% need to choose an appropriate initial parameters to obtain robust and
% optimial set of parameters. Sensitivity analysis, bifurcation analysis,
% and using global search methods prior to running the simiulations is
% strongly encourage as it will provide insight as to what the range of
% robust and optimial parameters is. 
initParams = 'initParamOptimMedian3';


% The paramerers include B = 0 (used for estimating the parameters of
% individual fish; for estimations of median population B is set to zero);
% H(denoted by h in the manuscript): habituation gain; K(g): occulomotor
% gain; Kh: habituation integrator gain; Ka: adapatation gain; Ta:
% adaptation time constant; Th: habituation time constant; Kvsm: velocity
% storage integrator gain; Tvsm: velocity storage time constant; Tsim:
% simulation time = 3600 s (60 mins); Tgain: temporal asymmetry gain;
% Ngain: nasal asymmetry gain. initMessage: specifies the simulation in
% command window
load(initParams);


% ------------------------------ the model --------------------------------

% Specify the model that you are going to use; Note that this is a simulink model
mdl = 'TwoEyesModel'; 

% Specify the data that you are going to use for training
data = 'Median1010'; 
load(data);


% --------- prepare the data structure for parameter estimation -----------
% scietific reports combined for one and two adaptation integrator models
initialParameters.H = H;            % habituation gain
initialParameters.K = K;            % occulomotor gain
initialParameters.Ka = Ka;          % adapatation gain
initialParameters.Kh = Kh;          % habituation integrator gain
initialParameters.Kvsm = Kvsm;      % velocity storage integrator gain
initialParameters.Ta = Ta;          % adaptation time constant
initialParameters.Th = Th;          % habituation time constant
initialParameters.Tvsm = Tvsm;      % velocity storage time constant
initialParameters.Tgain1 = Tgain1;  % temporal asymmetry gain (right eye)
initialParameters.Ngain1 = Ngain1;  % nasal asymmetry gain (right eye)
initialParameters.Tgain2 = Tgain2;  % temporal asymmetry gain (left eye)
initialParameters.Ngain2 = Ngain2;  % nasal asymmetry gain (left eye)
initialParameters.B = B;            % bias ( set to 0 for median population simulations)
fprintf(intiMessage);
% note that temoral and nasal asymmetry gains were assumed to be indentical
% for final simulations and the result shown in the manuscript


% ---------- Training, testing, and validation data specification ---------
% use the lines 66 and 67, if you want to use the first stimulatory phase
% for training and the second stimulatory phase for testing and validation
idxTrain = t>=300 & t<1800;
idxTest = t>=1800 & t<3600;

% use the lines 71 and 72, if you want to use the first stimulatory phase
% for training and the second stimulatory phase for testing and validation
% % idxTrain = t>=1800 & t<3600;
% % idxTest = t>=300 & t<1800;


% ----------------------- make a training dataset -------------------------
tTrain = t(idxTrain);
NTrain = N(idxTrain);
TTrain = T(idxTrain);
xTrain = x(idxTrain);


% ------------ Set up the data for the optimization code ------------------
Data.Exp_Sig_Input_Value = timeseries(xTrain,tTrain,'Name','In1');
Data.Exp_Sig_Output_1_Value = timeseries(NTrain,tTrain,'Name','Out1');
Data.Exp_Sig_Output_2_Value = timeseries(TTrain,tTrain,'Name','Out2');
save('paramEstTwoEyesModel_Data','Data');
clear('Data')


% -------------------- optimize the parameters ----------------------------
pInit = [H, K, Ka, Kh, Kvsm, Ta, Th, Tvsm];
[pOpt, Info] = paramEstTwoEyesModelMedian(pInit);

H = pOpt(1).Value;
K = pOpt(2).Value;
Ka = pOpt(3).Value;
Kh = pOpt(4).Value;
Kvsm = pOpt(5).Value;
Ta = pOpt(6).Value;
Th = pOpt(7).Value;
Tvsm = pOpt(8).Value;


% ---------------------- test and validate the model ----------------------
[VAF,measureData, simulatedModel] = SimulateNewModel(mdl,B,K,H,...
    Ka,Kh,Ta,Th,Kvsm,Tvsm,Tsim,{'Median205','Median1010','Median105'},idxTest);


%---------------------------- Report and Save -----------------------------
[file, path] = uiputfile('Choose the directory in which you want to save the results:');
save([path file]);


