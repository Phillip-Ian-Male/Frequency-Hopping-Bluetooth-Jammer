# Frequency Hopping Bluetooth Jammer

> A portable, narrow-band Bluetooth jamming system designed to prevent academic dishonesty via concealed Bluetooth audio devices during assessments and interviews.

---

## Overview

This project addresses the growing problem of concealed Bluetooth audio devices being used to transmit answers during academic assessments. Conventional invigilation methods are insufficient against small, concealable Bluetooth earphones. This system implements a portable, legally-compliant, narrow-band Bluetooth jammer running multiple frequency hopping jamming algorithms on an embedded platform to render Bluetooth voice communication unintelligible within a controlled area.

The jammer operates within the ISM band (2.400–2.4825 GHz) at a maximum of **20 dBm (100 mW)** EIRP, in compliance with South African licence-exempt band regulations.

---

## System Architecture

The system is composed of seven functional units:

| Unit | Function                                                        | Implementation                         |
| ---- | --------------------------------------------------------------- | -------------------------------------- |
| FU1  | RF Detection Front-End (RX antenna, amplifier, SDR RX)          | Custom antenna/amp + off-the-shelf SDR |
| FU2  | Frequency Detection Algorithm                                   | From first principles (embedded)       |
| FU3  | Jamming Algorithm Execution                                     | From first principles (embedded)       |
| FU4  | Jamming Signal Generation & Feedback Control                    | From first principles (embedded)       |
| FU5  | RF Jamming Front-End (SDR TX, amplifier, TX antenna)            | Custom antenna/amp + off-the-shelf SDR |
| FU6  | User Interface (spectrum display, algorithm/waveform selection) | From first principles (embedded)       |
| FU7  | Power Module                                                    | Off-the-shelf                          |

---

## Key Specifications

| Requirement              | Specification              | Justification                                                                    |
| ------------------------ | -------------------------- | -------------------------------------------------------------------------------- |
| Effective jamming radius | 1.25 m (2.5 m diameter)    | Covers ~10 students in a standard lecture hall                                   |
| Packet disruption rate   | ≥ 36% of Bluetooth packets | Speech becomes unintelligible at ≤ 64% packet delivery ratio                     |
| Maximum output power     | ≤ 20 dBm EIRP              | South African ISM band legal limit                                               |
| Jamming signal bandwidth | 1 – 20 MHz                 | Covers a single 1 MHz Bluetooth bin; upper bound avoids trivialising the problem |
| Frequency hopping range  | 2.402 GHz – 2.480 GHz      | Covers all 79 Bluetooth Classic hop bins                                         |

---

## Technical Challenges

### Design

- **No access to the Bluetooth hop sequence:** As an uninvited party to the Bluetooth connection, the jammer cannot predict the pseudo-random hopping sequence. Multiple intelligent algorithms must be designed to estimate and track the hop position within a narrow-band budget.
- **Limited legal power budget:** At most 20 dBm across the 80 MHz hopping range, the system must allocate energy intelligently to maximise disruption per watt.
- **Algorithm design:** Algorithms must account for Bluetooth's adaptive frequency hopping (AFH), which causes devices to avoid known congested channels, making naive channel-camping ineffective.

### Implementation

- **Timing constraint:** Bluetooth hops 1600 times per second, giving a window of **625 µs per hop**. The full RX to processing to TX pipeline (SDR communication, FFT, algorithm execution, SDR retune) must complete within this window.
- **Embedded performance:** All processing must run on an embedded platform (not a PC), requiring careful optimisation of algorithm speed and SDR communication latency.

---

## Design Contributions

- Design of two custom high-frequency (> 2.402 GHz) amplifiers — one for TX (jamming) and one for RX (detection)
- Design of two custom directional high-frequency antennas meeting gain and directivity specifications
- PCB layout and implementation of all analogue RF components
- Implementation of multiple selectable frequency hopping jamming algorithms, compared on jamming performance
- User interface for algorithm/waveform selection and live spectrum display
- System-wide timing optimisation to minimise reaction latency

---

## Advanced Theoretical considerations

- **Frequency hopping spread spectrum (FHSS) Communication:** Bluetooth hopping sequence structure, adaptive frequency hopping, processing gain
- **Communication jamming theory:** Hopping jammer design, optimal jamming strategies
- **High-frequency RF electronics:** Signal integrity, PCB layout at 2.4 GHz, EMC considerations
- **Detection and estimation theory:** Spectrum sensing, signal classification, predictive hop-sequence estimation

---

## Real-World Operating Conditions

The system is designed to operate in a typical university lecture hall under real exam conditions:

- No EM shielding present
- Ambient RF noise and interference from other devices in the environment
- No active Wi-Fi devices in the room (consistent with standard exam conditions)

---

## References

[1] D. Cull and S. Makda, "Guide: Commonly-used Licence-exempt bands in South Africa which may be used for outdoor wireless access systems," Ellipsis Regulatory Solutions, May 2017. [Online]. Available: https://www.ellipsis.co.za/wp-content/uploads/2018/04/Guide-to-commonly-used-licence-exempt-frequency-bands-May2017-1.pdf

[2] D. Crowther et al., "The relationship between intelligibility and comprehensibility in second language speech," _Bilingualism: Language and Cognition_, Cambridge University Press, Sep. 2025. [Online]. Available: https://doi.org/10.1017/S1366728925000173

[3] Bluetooth Special Interest Group, _Bluetooth Core Specification_, Version 6.0, Bluetooth SIG, Kirkland, WA, USA, Feb. 2024. [Online]. Available: https://www.bluetooth.com/specifications/specs/core60-html/

---

> **Legal notice:** This device is designed for use within South African ISM band licence-exempt power limits. Operation outside these limits, or use for purposes other than authorised academic invigilation, may be illegal. The device must only be operated by authorised personnel in approved assessment environments.
