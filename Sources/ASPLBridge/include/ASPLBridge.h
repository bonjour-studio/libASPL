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

typedef struct ASPLIOCallbacks {
    void* _Nullable context;
    void (* _Nullable read)(void* _Nullable, Float64, void* _Nullable, UInt32);
    void (* _Nullable write)(void* _Nullable, Float64, const void* _Nullable, UInt32);
    void (* _Nullable reset)(void* _Nullable);
} ASPLIOCallbacks;

// Control-thread custom properties. copyValue transfers a +1 reference to HAL;
// setValue borrows its argument. Keep context alive for the driver's lifetime.
typedef struct ASPLPropertyCallbacks {
    AudioObjectPropertySelector selector;
    void* _Nullable context;
    CFPropertyListRef _Nullable (* _Nonnull copyValue)(void* _Nullable);
    void (* _Nullable setValue)(void* _Nullable, CFPropertyListRef _Nonnull);
} ASPLPropertyCallbacks;

// Strings are copied during creation. Returns null if C++ construction fails.
ASPLDriverHandle* _Nullable ASPLDriverCreate(
    const char* _Nonnull name,
    const char* _Nonnull manufacturer,
    const char* _Nonnull uid,
    UInt32 sampleRate,
    UInt32 channelCount,
    bool inputEnabled,
    bool outputEnabled,
    bool float32,
    ASPLIOCallbacks callbacks,
    const ASPLPropertyCallbacks* _Nullable properties,
    UInt32 propertyCount);

void ASPLDriverDestroy(ASPLDriverHandle* _Nonnull handle);

// The reference is borrowed and remains valid only while the handle is alive.
AudioServerPlugInDriverRef _Nonnull ASPLDriverGetReference(ASPLDriverHandle* _Nonnull handle);

#ifdef __cplusplus
}
#endif
