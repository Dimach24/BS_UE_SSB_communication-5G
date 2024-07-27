clc;
clear all; %#ok<CLALL>
close all;
addpath(genpath(pwd))
%%

NCellId=17;

caseL   = 'B';
scs     = 30;
pointA  = 4.4;  % GHz
Lmax_   = 8;   % amount of SSB in the HALF-FRAME
mu      = 1;
k_SSB   = 20;
SFN_MSB = 37;
SFN_LSB = 1;
tran_bandwidth = 60;
toff    =0;
foff    =k_SSB;

samples_offset = 70000;
symbs_received = 52;


kSSB_bin=int2bit(k_SSB,4).';
MIB     =[...
    int2bit(SFN_MSB,6).',   ... % SFN_MSB
    (scs==15||scs==60),     ... % scs15or60
    kSSB_bin(1:4)           ... % kSsbLsb
    1,                      ... % dmrs pos3
    1,1,1,1,                ... % sib.RB=15
    0,1,0,1,    ... % sib.searchSpaceZero=5
    0,          ... % cellBarred=True
    1,          ... % intraFreqReselection=False
    0,          ... % reserved
    0,          ... % just a bit, cos 24 bits required
    ];
%%

bits=zeros(864,Lmax_*2);

for issb=0:(Lmax_*2-1)
    issb_bin=int2bit(mod(issb,Lmax_),6,true);
    bits(:,issb+1)=PbchGenerator.generatePbch(...
        MIB,...
        SFN_MSB+SFN_LSB,...
        issb>=Lmax_,...
        [k_SSB>=16,0,0],...
        NCellId, ...
        Lmax_...
        );
end

%%

rg=ResourceTransmitter.GenerateFrame(bits,NCellId,caseL,pointA,tran_bandwidth,toff,foff,[1,1,0.85,0.9]);

% samples per symbol (~sample rate)
SPS=size(rg,1);
%%
plt=pcolor(abs(rg(1:301,1:50)));
plt.EdgeColor='none';
ca=gca();
ca.YDir='normal';
xlim([1,50]);
xlabel('l+1 (номер OFDM символа +1)')
ylabel('k (номер поднесущей)')

%%

samples_part=OfdmTransceiver.ResourceGrid2ComlexTime(rg);
samples_part=samples_part(samples_offset:symbs_received*SPS);

%%
... rcd=received
rcd=struct();
[rcd.NCellId,rcd.kSSB,~,rcd.samples]=SsFinder.processSignalByPeakNo(samples_part,0,23,SPS,1,0.9);
%%
