# BS_UE_SSB_communication-5 G

This repository contains a script illustrating the functionality of modules designed by a group of students for 5G NR. The script doesn't fully illustrate all functionalities. It is applicable to cases `A`, `B` and `C`, described in clause 4.1 of [TS138_213][ts213].

The [script](fromBStoUE.m) creates a resource grid and maps thr synchronization signals (generated by the same script) bursts to it.

Here is a brief overview of the modules and submodules used in the repository, which are listed in the table below.

| Module                                                                                 | description                                                                                                                                                 |
| :------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [5G-CRC](https://github.com/Dimach24/5G-CRC/tree/main)                                 | attaches or removes cyclic redundancy check from data, see clause 5.1 of [TS138_212][ts212].                                                                |
| [PbchGenerator](https://github.com/Dymcos/PbchGenerator/tree/main)                     | collects all transmitted data and generates a polar-encoded, rate-matched bitstream with an attached CRC.                                                   |
| [PbchReceiver](https://github.com/Dimach24/PbchReceiver/tree/main)                     | does the reverse operations (in relation to `PbchGenerator`), i.e. extracts data from the bitstream.                                                        |
| [PBCH_DMRS_Generator-5G](https://github.com/Dimach24/PBCH_DMRS_Generator-5G/tree/main) | generates demodulation reference signals, see clause 7.4.1.4 of [TS138_211][ts211].                                                                         |
| [Resource-Receiver-5G](https://github.com/Dimach24/Resource-Receiver-5G/tree/main)     | extracts and descrambles bitstream from the resource grid, extracts `ibar_SSB` from PBCH DM-RS signal.                                                      |
| [ResourceMapper](https://github.com/Dimach24/ResourceMapper/tree/main)                 | maps signals according to theirs types, resource grid configuration, passed offsets. see clauses 7.4.3 of [TS138_211][ts211] and 4.1 of [TS138_213][ts213]. |
| [SSGenerator](https://github.com/Dimach24/SSGenerator/tree/main)                       | generates primary and secundary sync. signals according to clause 7.4.2 of [TS138_211][ts211].                                                              |
| [ResourceTransmitter-5G](https://github.com/Dimach24/ResourceTransmitter-5G/tree/main) | calls SS burst signal generators and maps it through ResourceMapper.                                                                                        |
| [SsFinder](https://github.com/Dimach24/SsFinder/tree/main)                             | detects SS block in time-domain complex signal, extracts time and frequency offsets and `NCellId`.                                                          |
| [WaveFormer (OfdmTransceiver)](https://github.com/Dymcos/WaveFormer/tree/main)         | converts the resource grid into a time-domain signal or performs a reverse transformation.                                                                  |

[ts213]: https://www.etsi.org/deliver/etsi_ts/138200_138299/138213/17.07.00_60/ts_138213v170700p.pdf
[ts211]: https://www.etsi.org/deliver/etsi_ts/138200_138299/138211/17.06.00_60/ts_138211v170600p.pdf
[ts212]: https://www.etsi.org/deliver/etsi_ts/138200_138299/138212/17.06.00_60/ts_138212v170600p.pdf
