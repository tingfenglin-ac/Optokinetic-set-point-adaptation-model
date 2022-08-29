function [pOpt, Info] = paramEstTwoEyesModelBias(x)
%PARAMETERESTIMATIONTWOEYESMODELSAMEDIRECTION
% x is the intialization for the parameters 
% x = [B];

% Solve a parameter estimation problem for the TwoEyesModel model.
%
% The function returns estimated parameter values, pOpt,
% and estimation termination information, Info.
%
% The input argument, p, defines the model parameters to estimate,
% if omitted the parameters specified in the function body are estimated.
%
% Modify the function to include or exclude new experiments, or
% to change the estimation options.
%
% Auto-generated by SPETOOL on 07-Apr-2021 21:54:15.
%

%% Open the model.
open_system('TwoEyesModel')

%% Specify Model Parameters to Estimate
%
p = [];

%% Define the Estimation Experiments
%

Exp = sdo.Experiment('TwoEyesModel');

%%
% Specify the experiment input data used to generate the output.
Exp_Sig_Input = Simulink.SimulationData.Signal;
Exp_Sig_Input.Values    = getData('Exp_Sig_Input_Value');
Exp_Sig_Input.BlockPath = 'TwoEyesModel/In1';
Exp_Sig_Input.PortType  = 'outport';
Exp_Sig_Input.PortIndex = 1;
Exp_Sig_Input.Name      = 'In1';
Exp.InputData = Exp_Sig_Input;

%%
% Specify the measured experiment output data.
Exp_Sig_Output_1 = Simulink.SimulationData.Signal;
Exp_Sig_Output_1.Values    = getData('Exp_Sig_Output_1_Value');
Exp_Sig_Output_1.BlockPath = 'TwoEyesModel/Biased Signed Absolute valued TN Model';
Exp_Sig_Output_1.PortType  = 'outport';
Exp_Sig_Output_1.PortIndex = 1;
Exp_Sig_Output_1.Name      = 'Out1';
Exp_Sig_Output_2 = Simulink.SimulationData.Signal;
Exp_Sig_Output_2.Values    = getData('Exp_Sig_Output_2_Value');
Exp_Sig_Output_2.BlockPath = 'TwoEyesModel/Biased Signed Absolute valued TN Model';
Exp_Sig_Output_2.PortType  = 'outport';
Exp_Sig_Output_2.PortIndex = 2;
Exp_Sig_Output_2.Name      = 'Out2';
Exp.OutputData = [Exp_Sig_Output_1; Exp_Sig_Output_2];

%%
% Specify experiment specific parameters.
Param = sdo.getParameterFromModel('TwoEyesModel',{'B'});
Param(1).Value = x(1); 
Exp.Parameters = Param;

% for debugging porpuses
% Param = sdo.getParameterFromModel('TwoEyesModel',{'Ta', 'Ka', 'B', 'Ngain1'});
% Param(1).Value = x(1); Param(1).Minimum = 0; Param(1).Maximum = 4000;
% Param(2).Value = x(2); Param(2).Minimum = 0;
% Param(3).Value = x(3); 
% Param(4).Value = x(4); Param(4).Minimum = 0;
% Exp.Parameters = Param;
 
%%
% Create a model simulator from an experiment
Simulator = createSimulator(Exp);
%%
% Add experiment specific parameters/states to the list of parameters
% to estimate.
s = getValuesToEstimate(Exp);
p = [p; s];

%% Create Estimation Objective Function
%
% Create a function that is called at each optimization iteration
% to compute the estimation cost.
%
% Use an anonymous function with one argument that calls TwoEyesModel_optFcn.
optimfcn = @(P) TwoEyesModel_optFcn(P,Simulator,Exp);

%% Optimization Options
%
% Specify optimization options.
Options = sdo.OptimizeOptions;
Options.Method = 'lsqnonlin';
Options.OptimizedModel = Simulator;

%% Estimate the Parameters
%
% Call sdo.optimize with the estimation objective function handle,
% parameters to estimate, and options.
[pOpt,Info] = sdo.optimize(optimfcn,p,Options);

%%
% Update the experiments with the estimated parameter values.
Exp = setEstimatedValues(Exp,pOpt);

%% Update Model
%
% Update the model with the optimized parameter values.
sdo.setValueInModel('TwoEyesModel',pOpt(1:0));
end

function Vals = TwoEyesModel_optFcn(P,Simulator,Exp)
%TWOEYESMODELSAMEDIRECTION_OPTFCN
%
% Function called at each iteration of the estimation problem.
%
% The function is called with a set of parameter values, P, and returns
% the estimation cost, Vals, to the optimization solver.
%
% See the sdoExampleCostFunction function and sdo.optimize for a more
% detailed description of the function signature.
%

%%
% Define a signal tracking requirement to compute how well the model
% output matches the experiment data.
r = sdo.requirements.SignalTracking(...
    'Method', 'Residuals');
%%
% Update the experiment(s) with the estimated parameter values.
Exp = setEstimatedValues(Exp,P);

%%
% Simulate the model and compare model outputs with measured experiment
% data.

F_r = [];
Simulator = createSimulator(Exp,Simulator);
Simulator = sim(Simulator);

SimLog = find(Simulator.LoggedData,get_param('TwoEyesModel','SignalLoggingName'));
for ctSig=1:numel(Exp.OutputData)
    Sig = find(SimLog,Exp.OutputData(ctSig).Name);
    
    Error = evalRequirement(r,Sig.Values,Exp.OutputData(ctSig).Values);
    F_r = [F_r; Error(:)];
end

%% Return Values.
%
% Return the evaluated estimation cost in a structure to the
% optimization solver.
Vals.F = F_r;
end

function Data = getData(DataID)
%GETDATA
%
% Helper function to store data used by parameterEstimation_TwoEyesModel.
%
% The input, DataID, specifies the name of the data to retrieve. The output,
% Data, contains the requested data.
%

SaveData = load('paramEstTwoEyesModel_Data');
Data = SaveData.Data.(DataID);
end
