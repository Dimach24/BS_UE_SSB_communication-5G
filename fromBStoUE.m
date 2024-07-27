clc;
clear all; %#ok<CLALL>
close all;
addpath(genpath(pwd))
%%

NCellId=17;

caseL   = 'D';
scs     = 120;
Lmax_   = 64;   % amount of SSB in the FRAME (N.B. not half-frame)
mu      = 3;
k_SSB   = 15;
SFN_MSB = 37;
SFN_LSB = 1;

MIB     =[...
    int2bit(SFN_MSB,6).',   ... % SFN_MSB
    (scs==15||scs==60),     ... % scs15or60
    int2bit(k_SSB,4).'      ... % kSsbLsb=4
    1,                      ... % dmrs pos3
    1,1,1,1,                ... % sib.RB=15
    0,1,0,1,    ... % sib.searchSpaceZero=5
    0,          ... % cellBarred=True
    1,          ... % intraFreqReselection=False
    0,          ... % reserved
    0,          ... % just a bit, cos 24 bits required
    ];
%%

bits=zeros(Lmax_,864);

for issb=0:(Lmax_-1)
    issb_bin=int2bit(mod(issb,Lmax_/2),6,true);
    bits(issb+1,:)=PbchGenerator.generatePbch(...
        MIB,...
        SFN_MSB+SFN_LSB,...
        issb>=Lmax_/2,...
        issb_bin(1:3),...
        NCellId, ...
        Lmax_...
        );
end

