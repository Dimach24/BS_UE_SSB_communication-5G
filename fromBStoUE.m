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
SFN = 456;
bSFN = int2bit(SFN,10).';
SFN_MSB = bit2int([bSFN(1:6), 0, 0, 0, 0].',10);
SFN_LSB = bit2int(bSFN(7:10).',4);
tran_bandwidth = 60;
toff    =0;
foff    =k_SSB;

samples_offset = 27000;
symbs_received = 60;


kSSB_bin=int2bit(k_SSB,5,false).';
MIB     =[...
    0,          ... % just a bit, cos 24 bits required
    bSFN(1:6),   ... % SFN_MSB
    (scs==15||scs==60),     ... % scs15or60
    kSSB_bin(4:-1:1)           ... % kSsbLsb
    1,                      ... % dmrs pos3
    1,1,1,1,                ... % sib.RB=15
    0,1,0,1,    ... % sib.searchSpaceZero=5
    0,          ... % cellBarred=True
    1,          ... % intraFreqReselection=False
    0,          ... % reserved
    ];
%%

bits=zeros(864,Lmax_*2);

% payload generation

for issb=0:(Lmax_*2-1)
    issb_bin=int2bit(mod(issb,Lmax_),6,true);
    bits(:,issb+1)=PbchGenerator.generatePbch(...
        MIB,...
        SFN,...
        issb>=Lmax_,...
        [k_SSB>=16 0 0],...
        NCellId, ...
        Lmax_...
        );
end

DATACHECK = PbchReceiver.receivePbch(bits(:,3),NCellId,Lmax_);

%% frame generation

rg=ResourceTransmitter.GenerateFrame(bits,NCellId,caseL,pointA,tran_bandwidth,toff,foff,[1,1,0.85,0.9]);

% samples per symbol (~sample rate)
SPS=size(rg,1);

%% drawing
subplot(2,1,1);
plt=pcolor(abs(rg(1:301,1:50)));
plt.EdgeColor='none';
ca=gca();
ca.YDir='normal';
xlim([1,50]);
xlabel('l+1 (номер OFDM символа +1)')
ylabel('k (номер поднесущей)')
text(36,80,sprintf("NcellID=%d\nkSSB=%d\nSFN=%d",NCellId,k_SSB,SFN_MSB+SFN_LSB),"BackgroundColor","white");
title('Отправлено');

%% generating time-domain complex signal and cropping it
samples_part=OfdmTransceiver.ResourceGrid2ComlexTime(rg);
samples_part=samples_part(samples_offset:samples_offset+symbs_received*SPS);

%% looking for PSS and doing other stuff to find the SSB
... rcd=received
    rcd=struct();
[rcd.NCellId,rcd.k_SSB,rcd.tindex,rcd.samples]=SsFinder.processSignalByPeakNo(samples_part,0,23,SPS,1,0.4);

%% recovering the resource grid
rcd.samples=[rcd.samples, zeros(1,SPS-mod(length(rcd.samples),SPS))];
rcd.rg=OfdmTransceiver.ComplexTime2ResourceGrid(rcd.samples,SPS);

%% resource grid mismatch calculation (doesn't work, FIXME)
mismatch.rg=rcd.rg(1:240,1:8)-rg(1:240,5:12);
mismatch.rg(1:end,1:end) = abs(mismatch.rg(1:end,1:end))>1e-10;
mismatch.rg_count = sum(mismatch.rg,"all");

%%  extracting bitstream from the recovered resource grid
[rcd.pbch,rcd.issb]=ResourceReceiver.getBitstream(rcd.rg,0,rcd.k_SSB,rcd.NCellId,Lmax_);
mismatch.bs=(rcd.pbch ~= bits(:,rcd.issb+1).');
mismatch.bs_err_count = sum(mismatch.bs);

%% drawing
subplot(2,1,2)
plt=pcolor(abs(rcd.rg(1:301,1:end)));
plt.EdgeColor='none';
ca=gca();
ca.YDir='normal';
xlim([1,50]);
xlabel('l+1 (номер OFDM символа +1)')
ylabel('k (номер поднесущей)')
title(sprintf('Принято со сдвигом ≈ %.4g, обрезано по %.4g',samples_offset/SPS,(rcd.tindex+samples_offset)/SPS));

text(36,80,...
    sprintf("NcellID=%d\nkSSB=%d\nSFN=%d\nИндекс блока: %d",...
    rcd.NCellId,rcd.k_SSB,SFN,rcd.issb),...
    "BackgroundColor","white");

%% extracting info from bitstream and data validation
[rcd.data,rcd.valid_crc]=PbchReceiver.receivePbch(cast(rcd.pbch,"double"),rcd.NCellId,Lmax_);
disp(rcd.data)
disp(rcd.data.mib)
if (rcd.valid_crc)
    disp("data verification success")
else
    disp("data verification failure")
end
disp(mismatch)