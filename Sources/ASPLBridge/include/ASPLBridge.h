//
//  ASPLBridge.h
//  ASPLBridge
//
//  Created by Bonjour, LLC on 2026/10/17.
//

#pragma once

#include <CoreAudio/AudioServerPlugIn.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ASPLDriverHandle ASPLDriverHandle;

// Strings are copied during creation. Returns null if C++ construction fails.
ASPLDriverHandle* _Nullable ASPLDriverCreate(
    const char* _Nonnull name,
    const char* _Nonnull manufacturer,
    const char* _Nonnull uid,
    UInt32 sampleRate,
    UInt32 channelCount,
    bool inputEnabled,
    bool outputEnabled);

void ASPLDriverDestroy(ASPLDriverHandle* _Nonnull handle);

// The reference is borrowed and remains valid only while the handle is alive.
AudioServerPlugInDriverRef _Nonnull ASPLDriverGetReference(ASPLDriverHandle* _Nonnull handle);

#ifdef __cplusplus
}
#endif
