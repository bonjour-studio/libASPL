//
//  ASPLBridge.cpp
//  ASPLBridge
//
//  Created by Bonjour, LLC on 2026/10/17.
//

#include "ASPLBridge.h"
#include <aspl/Driver.hpp>

#include <memory>
#include <utility>

namespace {
class CallbackHandler final : public aspl::IORequestHandler, public aspl::ControlRequestHandler {
public:
    explicit CallbackHandler(ASPLIOCallbacks callbacks) : callbacks_(callbacks) {}

    OSStatus OnStartIO() override {
        if (callbacks_.reset) callbacks_.reset(callbacks_.context);
        return noErr;
    }

    void OnStopIO() override {
        if (callbacks_.reset) callbacks_.reset(callbacks_.context);
    }

    void OnReadClientInput(const std::shared_ptr<aspl::Client>&,
        const std::shared_ptr<aspl::Stream>&, Float64, Float64 timestamp,
        void* bytes, UInt32 count) override {
        if (count == 0) return;
        if (callbacks_.read) callbacks_.read(callbacks_.context, timestamp, bytes, count);
        else std::memset(bytes, 0, count);
    }

    void OnWriteMixedOutput(const std::shared_ptr<aspl::Stream>&,
        Float64, Float64 timestamp, const void* bytes, UInt32 count) override {
        if (count != 0 && callbacks_.write) callbacks_.write(callbacks_.context, timestamp, bytes, count);
    }

private:
    const ASPLIOCallbacks callbacks_;
};
}

struct ASPLDriverHandle {
    std::shared_ptr<aspl::Driver> driver;
};

ASPLDriverHandle* ASPLDriverCreate(
    const char* name,
    const char* manufacturer,
    const char* uid,
    UInt32 sampleRate,
    UInt32 channelCount,
    bool inputEnabled,
    bool outputEnabled,
    bool float32,
    ASPLIOCallbacks callbacks)
{
    // C++ exceptions must not cross the C boundary into Swift.
    try {
        auto context = std::make_shared<aspl::Context>();
        aspl::DeviceParameters parameters;
        parameters.Name = name;
        parameters.Manufacturer = manufacturer;
        parameters.DeviceUID = uid;
        parameters.SampleRate = sampleRate;
        parameters.ChannelCount = channelCount;

        auto device = std::make_shared<aspl::Device>(context, parameters);
        for (auto direction : {aspl::Direction::Input, aspl::Direction::Output}) {
            if ((direction == aspl::Direction::Input && !inputEnabled) ||
                (direction == aspl::Direction::Output && !outputEnabled)) continue;
            aspl::StreamParameters stream;
            stream.Direction = direction;
            stream.Format.mSampleRate = sampleRate;
            stream.Format.mChannelsPerFrame = channelCount;
            stream.Format.mBitsPerChannel = float32 ? 32 : 16;
            stream.Format.mBytesPerFrame = channelCount * (stream.Format.mBitsPerChannel / 8);
            stream.Format.mBytesPerPacket = stream.Format.mBytesPerFrame;
            stream.Format.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked |
                (float32 ? kAudioFormatFlagIsFloat : kAudioFormatFlagIsSignedInteger);
            device->AddStreamWithControlsAsync(stream);
        }
        auto handler = std::make_shared<CallbackHandler>(callbacks);
        device->SetIOHandler(handler);
        device->SetControlHandler(handler);

        aspl::PluginParameters pluginParameters;
        pluginParameters.Manufacturer = manufacturer;
        auto plugin = std::make_shared<aspl::Plugin>(context, pluginParameters);
        plugin->AddDevice(device);
        auto driver = std::make_shared<aspl::Driver>(context, plugin);
        return new ASPLDriverHandle{std::move(driver)};
    } catch (...) {
        return nullptr;
    }
}

void ASPLDriverDestroy(ASPLDriverHandle* handle)
{
    delete handle;
}

AudioServerPlugInDriverRef ASPLDriverGetReference(ASPLDriverHandle* handle)
{
    return handle->driver->GetReference();
}
