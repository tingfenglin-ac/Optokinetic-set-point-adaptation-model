function [VAF,measureData, simulatedModel] = SimulateNewModel(mdl,B,K,H,...
    Ka,Kh,Ta,Th,Kvsm,Tvsm,Tsim,dataname,idxTest)
% Simulate the new model and plot
% save_system(mdl);
open_system(mdl);
measureData = [];
VAF = [];
simulatedModel = [];
for i = 1:numel(dataname)
    load(dataname{i});
    s = Simulink.SimulationData.Dataset;
    s = s.setElement(1, timeseries(x,t));
    in = Simulink.SimulationInput(mdl);
    in = in.setExternalInput('s.getElement(1)');
    
    
    in = in.setVariable('s',s);
    out = parsim(in);
        
    simN = out.yout{1}.Values;
    simT = out.yout{2}.Values;
    
    simN = resample(simN,t); simN = simN.Data(idx);
    simT = resample(simT,t); simT = simT.Data(idx);
    t = t(1:sum(idx));
    Nn = N(idx);
    Tn = T(idx);
    
    fig = figure;
    FontSize = 14;
    colors = get(gca,'colororder');
    ax1 = subplot(211);
    hold on; plot(t,Nn); plot(t,simN,'color',colors(2,:));
    xlabel('time (s)','FontSize',FontSize);
    ylabel('right EV (deg/s)','FontSize',FontSize);
    title('OKN and OKAN: measured vs simulated data','FontSize',FontSize);
    
    ax2 = subplot(212);
    hold on; plot(t,Tn); plot(t,simT,'color',colors(2,:));
    xlabel('time (s)','FontSize',FontSize);
    ylabel('left EV (deg/s)','FontSize',FontSize);
    
    linkaxes([ax1,ax2],'xy');
    xlim([min(t) max(t)]);
    
    tempMeasuredData = [Nn(idxTest);Tn(idxTest)];
    measureData = [measureData tempMeasuredData];
    model = [simN(idxTest);simT(idxTest)];
    simulatedModel = [simulatedModel model];
    tempVAF = (1-var(tempMeasuredData-model,'omitnan')/var(tempMeasuredData,'omitnan'))*100;
    VAF = [VAF tempVAF];
    fprintf('VAF = %%%d\n',round(tempVAF));
    fig.Name = sprintf('VAF = %d %%',round(tempVAF));
end

close_system(mdl);

end