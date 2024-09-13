clc;
clear all; %#ok<CLALL>
close all;
addpath(genpath(pwd))
hold on;

%% Initializing
NCellId = 250;
k_SSB.int   = 13;
channelBandwidth = 60;
SFN.int = 455;
timeOffset = 0;
samplesOffset = 0;
config = caseDecipher('C',4.4, 1);

k_SSB.bin=int2bit(k_SSB.int,5,false).';    
SFN.bin = int2bit(SFN.int,10).';
SFN.MSB = bit2int([SFN.bin(1:6), 0, 0, 0, 0].',10);
SFN.LSB = bit2int(SFN.bin(7:10).',4);

MIB     =[...
    0,          ... % just a bit, cos 24 bits required
    SFN.bin(1:6),   ... % SFN_MSB
    0,     ... % scs15or60 = (scs==15||scs==60)
    k_SSB.bin(4:-1:1)           ... % kSsbLsb
    1,                      ... % dmrs pos3
    1,1,1,1,                ... % sib.RB=15
    0,1,0,1,    ... % sib.searchSpaceZero=5
    0,          ... % cellBarred=True
    1,          ... % intraFreqReselection=False
    0,          ... % reserved
    ];

%% PBCH Generation
bits=zeros(864,config.Lmax_*2);
for issb=0:(config.Lmax_*2-1)
    bits(:,issb+1)=PbchGenerator.generatePbch(...
        MIB,...
        SFN.int,...
        issb>=config.Lmax_,... % HRF
        [k_SSB.int>=16 0 0],...
        NCellId, ...
        config.Lmax_...
        );
end

%% Resource grid creation
rg=ResourceTransmitter.GenerateFrame(bits,NCellId,channelBandwidth,timeOffset,k_SSB.int,[1,1,0.9,0.8]);
samplesPerSymbol = size(rg,1);
sampleRate = samplesPerSymbol*config.symbolsPerSecond;

%% Waveform generation
waveform = OfdmTransceiver.ResourceGrid2ComlexTime(rg);

%% Synchronisation
... rcd=received
rcd=struct();
[rcd.NCellId,rcd.k_SSB,rcd.tindex,rcd.samples]=SsFinder.processSignalByPeakNo(waveform,0,23,samplesPerSymbol,1,0.0001);
delay = (rcd.tindex+samplesOffset)/samplesPerSymbol; % delay in symbols

%% Received resource grid creation 
rcd.samples=[rcd.samples, zeros(1,samplesPerSymbol-mod(length(rcd.samples),samplesPerSymbol))];
rcd.rg=OfdmTransceiver.ComplexTime2ResourceGrid(rcd.samples,samplesPerSymbol);

%% Extractiong bits from resource grid
[rcd.pbch,rcd.issb]=ResourceReceiver.getBitstream(rcd.rg,0,rcd.k_SSB,rcd.NCellId,config.Lmax_);
bitStreamError = any(rcd.pbch - bits(:,rcd.issb+1).');

%% Decoding bits
[rcd.data,rcd.valid_crc]=PbchReceiver.receivePbch(cast(rcd.pbch,"double"),rcd.NCellId,config.Lmax_);
disp(rcd.data)
disp(rcd.data.mib)
if (rcd.valid_crc)
    disp("data verification success")
else
    disp("data verification failure")
end

%% Resource grid painting
rGridMaxRB = 1944; %grid window parametres
subplot(2,1,1);
plt=pcolor(abs(rg(1:rGridMaxRB,1:config.symbolsPerSubframe*10)));
plt.EdgeColor='none';
ca=gca();
ca.YDir='normal';
xlim([1,140]);
xlabel('l+1 (номер OFDM символа +1)')
ylabel('k (номер поднесущей)')
text(36,80,sprintf("NcellID=%d\nkSSB=%d\nSFN=%d",NCellId,k_SSB.int,SFN.int),"BackgroundColor","white");
title('Отправлено');

%% Received resource grid painting
subplot(2,1,2)
plt=pcolor([zeros(length(rcd.rg(1:rGridMaxRB,1)),floor(delay)) abs(rcd.rg(1:rGridMaxRB,1:end))]);
plt.EdgeColor='none';
ca=gca();
ca.YDir='normal';
xlim([1,140]);
xlabel('l+1 (номер OFDM символа +1)')
ylabel('k (номер поднесущей)')
title(sprintf('Принято со сдвигом ≈ %.4g, обрезано по %.4g',samplesOffset/samplesPerSymbol,delay));
text(36,80,...
     sprintf("NcellID=%d\nkSSB=%d\nSFN=%d\nИндекс блока: %d",...
            rcd.NCellId,rcd.k_SSB,rcd.data.SFN,rcd.issb),...
    "BackgroundColor","white");
xlim([1,140]);