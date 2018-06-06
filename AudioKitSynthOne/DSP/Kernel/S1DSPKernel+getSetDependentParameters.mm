//
//  S1DSPKernel+getSetDependentParameters.mm
//  AudioKitSynthOne
//
//  Created by Aurelius Prochazka on 6/4/18.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#import "S1DSPKernel.hpp"

// algebraic taper and inverse for input range [0,1]
inline float S1DSPKernel::taper01(float inputValue01, float taper) {
    return powf(inputValue01, 1.f / taper);
}
inline float S1DSPKernel::taper01Inverse(float inputValue01, float taper) {
    return powf(inputValue01, taper);
}

float S1DSPKernel::getDependentParameter(S1Parameter parameter) {

    if (parameter == pitchbend) {
        return _pitchbend.value;
    }

    DependentParameter dp;
    switch(parameter) {
        case lfo1Rate: dp = _lfo1Rate; break;
        case lfo2Rate: dp = _lfo2Rate; break;
        case autoPanFrequency: dp = _autoPanRate; break;
        case delayTime: dp = _delayTime; break;
        default:printf("error\n");break;
    }

    if (p[tempoSyncToArpRate] > 0.f) {
        return dp.normalizedValue;
    } else {
        return taper01Inverse(dp.normalizedValue, S1_DEPENDENT_PARAM_TAPER);
    }
}

// map normalized input to parameter range
void S1DSPKernel::setDependentParameter(S1Parameter param, float inputValue01, int payload) {
    const bool notify = true;
    switch(param) {
        case lfo1Rate: case lfo2Rate: case autoPanFrequency:
            if (p[tempoSyncToArpRate] > 0.f) {
                // tempo sync
                AKSynthOneRate rate = _rate.rateFromFrequency01(inputValue01);
                const float val = _rate.frequency(getSynthParameter(arpRate), rate);
                _setSynthParameterHelper(param, val, notify, payload);
            } else {
                // no tempo sync
                const float min = parameterMin(param);
                const float max = parameterMax(param);
                const float taperValue01 = taper01(inputValue01, S1_DEPENDENT_PARAM_TAPER);
                const float val = min + taperValue01 * (max - min);
                _setSynthParameterHelper(param, val, notify, payload);
            }
            break;
        case delayTime:
            if (p[tempoSyncToArpRate] > 0.f) {
                // tempo sync
                const float valInvert = 1.f - inputValue01;
                AKSynthOneRate rate = _rate.rateFromTime01(valInvert);
                const float val = _rate.time(p[arpRate], rate);
                _setSynthParameterHelper(delayTime, val, notify, payload);
            } else {
                // no tempo sync
                const float min = parameterMin(delayTime);
                const float max = parameterMax(delayTime);
                const float taperValue01 = taper01(inputValue01, S1_DEPENDENT_PARAM_TAPER);
                const float val = min + taperValue01 * (max - min);
                _setSynthParameterHelper(delayTime, val, notify, payload);
            }
            break;
        case pitchbend:
        {
            const float min = parameterMin(param);
            const float max = parameterMax(param);
            const float val = min + inputValue01 * (max - min);
            _setSynthParameterHelper(pitchbend, val, notify, payload);
        }
            break;
        default:
            printf("error\n");
            break;
    }
}